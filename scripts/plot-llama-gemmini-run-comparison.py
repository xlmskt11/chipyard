#!/usr/bin/env python3

import argparse
import csv
import re
from collections import defaultdict
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


PHASES = ("prefill", "decode")


def parse_args():
    parser = argparse.ArgumentParser(
        description="Compare the gemmini_run subphase across llama-firesim runs."
    )
    parser.add_argument("run_dirs", nargs="+", type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    return parser.parse_args()


def read_csv(path):
    with path.open(newline="") as handle:
        return list(csv.DictReader(handle))


def hardware_label(run_dir):
    summary = (run_dir / "HW_CFG_SUMMARY").read_text()
    runtime_match = re.search(r"^RuntimeHWConfig:\s*(.+)$", summary, re.MULTILINE)
    runtime_config = runtime_match.group(1) if runtime_match else "unknown"

    dim_match = re.search(r"(?:^|_)(\d+)dim(?:_|$)", runtime_config.lower())
    if dim_match:
        dim = int(dim_match.group(1))
    else:
        square_match = re.search(r"gemmini(\d+)x\1", runtime_config.lower())
        dim = int(square_match.group(1)) if square_match else 0

    return runtime_config, dim


def run_mode(run_label):
    if run_label.startswith("multi_"):
        return "multi"
    if run_label.startswith("single_"):
        return "single"
    return "other"


def packing_mask(row):
    return "".join(row[f"page_packed_{matrix}"] for matrix in "abcd")


def packing_name(mask):
    enabled = "".join(matrix.upper() for matrix, bit in zip("abcd", mask) if bit == "1")
    return f"Packed {enabled}" if enabled else "Row-major"


def load_run(run_dir):
    runtime_config, dim = hardware_label(run_dir)
    metadata = {row["run_label"]: row for row in read_csv(run_dir / "run_summary.csv")}
    phase_totals = defaultdict(lambda: defaultdict(lambda: {"us": 0, "cycles": 0}))

    for row in read_csv(run_dir / "op_profile.csv"):
        label = row["run_label"]
        phase = row["phase"]
        if label not in metadata or phase not in PHASES:
            continue
        phase_totals[label][phase]["us"] += int(row["gemmini_run_us"])
        phase_totals[label][phase]["cycles"] += int(row["gemmini_run_cycles"])

    records = []
    for label, row in metadata.items():
        mode = run_mode(label)
        if mode == "other":
            continue
        mask = packing_mask(row)
        record = {
            "run_dir": str(run_dir),
            "run_label": label,
            "runtime_hw_config": runtime_config,
            "dim": dim,
            "mode": mode,
            "packing_mask": mask,
            "packing": packing_name(mask),
            "gemmini_count": int(row["gemmini_count"]),
            "prompt_tokens": int(row["prompt_tokens"]),
            "generated_tokens": int(row["generated_tokens"]),
        }
        for phase in PHASES:
            record[f"{phase}_us"] = phase_totals[label][phase]["us"]
            record[f"{phase}_cycles"] = phase_totals[label][phase]["cycles"]
        record["total_us"] = sum(record[f"{phase}_us"] for phase in PHASES)
        record["total_cycles"] = sum(record[f"{phase}_cycles"] for phase in PHASES)
        records.append(record)
    return records


def config_key(record):
    return (
        record["packing_mask"],
        record["gemmini_count"],
        record["dim"],
        record["mode"],
    )


def config_label(key):
    mask, count, dim, mode = key
    dim_text = f"DIM{dim}" if dim else "DIM?"
    return f"{packing_name(mask)} | {count}G {dim_text} | {mode}"


def common_prompt_tokens(records_by_config):
    prompt_sets = [
        {(record["prompt_tokens"], record["generated_tokens"]) for record in records}
        for records in records_by_config.values()
    ]
    common = set.intersection(*prompt_sets)
    generated_counts = {generated for _, generated in common}
    if len(generated_counts) != 1:
        raise RuntimeError(f"expected one common decode-token count, got {sorted(generated_counts)}")
    return sorted(prompt for prompt, _ in common), generated_counts.pop()


def choose_baseline(configs):
    row_major = [key for key in configs if key[0] == "0000"]
    if len(row_major) != 1:
        raise RuntimeError(f"expected one row-major baseline, got {row_major}")
    return row_major[0]


def ordered_configs(configs, baseline):
    packed = sorted(
        (key for key in configs if key != baseline),
        key=lambda key: (key[1], key[2], key[3], key[0]),
    )
    return [baseline] + packed


def write_comparison_csv(path, records_by_config, configs, prompts, generated_tokens, baseline):
    lookup = {
        key: {(record["prompt_tokens"], record["generated_tokens"]): record for record in records}
        for key, records in records_by_config.items()
    }
    fields = [
        "configuration",
        "packing_mask",
        "gemmini_count",
        "dim",
        "mode",
        "prompt_tokens",
        "generated_tokens",
        "prefill_gemmini_run_us",
        "prefill_gemmini_run_cycles",
        "decode_gemmini_run_us",
        "decode_gemmini_run_cycles",
        "total_gemmini_run_us",
        "total_gemmini_run_cycles",
        "speedup_vs_row_major_baseline",
    ]
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for prompt in prompts:
            baseline_record = lookup[baseline][(prompt, generated_tokens)]
            for key in configs:
                record = lookup[key][(prompt, generated_tokens)]
                writer.writerow({
                    "configuration": config_label(key),
                    "packing_mask": key[0],
                    "gemmini_count": key[1],
                    "dim": key[2],
                    "mode": key[3],
                    "prompt_tokens": prompt,
                    "generated_tokens": generated_tokens,
                    "prefill_gemmini_run_us": record["prefill_us"],
                    "prefill_gemmini_run_cycles": record["prefill_cycles"],
                    "decode_gemmini_run_us": record["decode_us"],
                    "decode_gemmini_run_cycles": record["decode_cycles"],
                    "total_gemmini_run_us": record["total_us"],
                    "total_gemmini_run_cycles": record["total_cycles"],
                    "speedup_vs_row_major_baseline": (
                        f"{baseline_record['total_cycles'] / record['total_cycles']:.6f}"
                    ),
                })


def plot(path, records_by_config, configs, prompts, generated_tokens, baseline):
    lookup = {
        key: {(record["prompt_tokens"], record["generated_tokens"]): record for record in records}
        for key, records in records_by_config.items()
    }
    colors = ["#3f4650", "#247ba0", "#2a9d8f", "#e9a23b", "#d1495b"]
    if len(configs) > len(colors):
        colors = list(plt.cm.tab10(np.linspace(0, 1, len(configs))))

    fig, axes = plt.subplots(2, 2, figsize=(16, 10.5))
    total_ax, speedup_ax, prefill_ax, decode_ax = axes.flat
    x = np.arange(len(prompts), dtype=float)
    width = 0.82 / len(configs)

    for index, (key, color) in enumerate(zip(configs, colors)):
        offset = (index - (len(configs) - 1) / 2) * width
        label = config_label(key)
        values = [lookup[key][(prompt, generated_tokens)] for prompt in prompts]
        total_cycles = [record["total_cycles"] / 1_000_000_000 for record in values]
        prefill_cycles = [record["prefill_cycles"] / 1_000_000_000 for record in values]
        decode_cycles = [record["decode_cycles"] / 1_000_000_000 for record in values]

        total_ax.bar(x + offset, total_cycles, width=width * 0.94, color=color, label=label)
        prefill_ax.bar(x + offset, prefill_cycles, width=width * 0.94, color=color)
        decode_ax.bar(x + offset, decode_cycles, width=width * 0.94, color=color)

        if key != baseline:
            baseline_values = [
                lookup[baseline][(prompt, generated_tokens)]["total_cycles"] for prompt in prompts
            ]
            speedups = [base / record["total_cycles"] for base, record in zip(baseline_values, values)]
            speedup_ax.plot(x, speedups, color=color, marker="o", linewidth=2, label=label)

    for axis in (total_ax, prefill_ax, decode_ax):
        axis.set_xticks(x, [str(prompt) for prompt in prompts])
        axis.set_xlabel("Prompt tokens")
        axis.set_ylabel("Accumulated gemmini_run cycles (billions)")
        axis.grid(axis="y", alpha=0.25)

    total_ax.set_title("Total: prefill + decode")
    prefill_ax.set_title("Prefill only")
    decode_ax.set_title(f"Decode only ({generated_tokens} generated tokens)")

    speedup_ax.axhline(1.0, color="#3f4650", linestyle="--", linewidth=1.2)
    speedup_ax.set_xticks(x, [str(prompt) for prompt in prompts])
    speedup_ax.set_xlabel("Prompt tokens")
    baseline_dim = baseline[2]
    baseline_name = f"row-major DIM{baseline_dim}" if baseline_dim else "row-major baseline"
    speedup_ax.set_ylabel(f"Speedup vs {baseline_name}")
    speedup_ax.set_title("Total gemmini_run speedup")
    speedup_ax.grid(alpha=0.25)

    handles, labels = total_ax.get_legend_handles_labels()
    fig.legend(
        handles,
        labels,
        loc="upper center",
        bbox_to_anchor=(0.5, 0.915),
        ncol=3,
        frameon=False,
    )
    fig.suptitle(
        "llama.cpp Gemmini execution-cycle comparison\n"
        "gemmini_run subphase only; quantization, dequantization, configuration, and host time excluded",
        fontsize=15,
        y=0.985,
    )
    fig.subplots_adjust(top=0.82, bottom=0.07, hspace=0.30, wspace=0.17)
    fig.savefig(path, dpi=200)
    plt.close(fig)


def main():
    args = parse_args()
    all_records = []
    for run_dir in args.run_dirs:
        all_records.extend(load_run(run_dir))

    records_by_config = defaultdict(list)
    for record in all_records:
        records_by_config[config_key(record)].append(record)

    baseline = choose_baseline(records_by_config)
    configs = ordered_configs(records_by_config, baseline)
    prompts, generated_tokens = common_prompt_tokens(records_by_config)

    args.output_dir.mkdir(parents=True, exist_ok=True)
    csv_path = args.output_dir / "gemmini_run_cycles_comparison.csv"
    figure_path = args.output_dir / "gemmini_run_cycles_comparison.png"
    write_comparison_csv(
        csv_path, records_by_config, configs, prompts, generated_tokens, baseline
    )
    plot(
        figure_path, records_by_config, configs, prompts, generated_tokens, baseline
    )
    print(figure_path)
    print(csv_path)


if __name__ == "__main__":
    main()
