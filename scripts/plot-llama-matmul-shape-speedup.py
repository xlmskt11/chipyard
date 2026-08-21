#!/usr/bin/env python3

import argparse
import csv
import re
import statistics
from collections import defaultdict
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np


CONFIG_ORDER = (
    (16, 1),
    (16, 2),
    (16, 3),
    (16, 4),
    (32, 1),
)

COMPARISON_STYLE = {
    (16, 2): ("16DIM 2 Gemmini", "#d95f02"),
    (16, 3): ("16DIM 3 Gemmini", "#1b9e77"),
    (16, 4): ("16DIM 4 Gemmini", "#c76da2"),
    (32, 1): ("32DIM 1 Gemmini", "#292929"),
}


def parse_args():
    parser = argparse.ArgumentParser(
        description=(
            "Plot per-shape gemmini_run cycle improvement relative to a "
            "16DIM one-Gemmini llama-firesim run."
        )
    )
    parser.add_argument("run_dirs", nargs="+", type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    return parser.parse_args()


def read_csv(path):
    with path.open(newline="") as handle:
        return list(csv.DictReader(handle))


def hardware_dim(run_dir):
    summary = (run_dir / "HW_CFG_SUMMARY").read_text()
    runtime_match = re.search(r"^RuntimeHWConfig:\s*(.+)$", summary, re.MULTILINE)
    if not runtime_match:
        raise RuntimeError(f"missing RuntimeHWConfig in {run_dir / 'HW_CFG_SUMMARY'}")
    runtime_config = runtime_match.group(1)

    dim_match = re.search(r"(?:^|_)(\d+)dim(?:_|$)", runtime_config.lower())
    if dim_match:
        return int(dim_match.group(1)), runtime_config
    comparison_match = re.search(
        r"gemminicomparison\d+x(\d+)", runtime_config.lower()
    )
    if comparison_match:
        return int(comparison_match.group(1)), runtime_config
    square_match = re.search(r"gemmini(\d+)x\1", runtime_config.lower())
    if square_match:
        return int(square_match.group(1)), runtime_config
    raise RuntimeError(f"unable to infer Gemmini DIM from {runtime_config}")


def packing_mask(row):
    return "".join(row[f"page_packed_{matrix}"] for matrix in "abcd")


def load_samples(run_dir):
    dim, runtime_config = hardware_dim(run_dir)
    run_rows = read_csv(run_dir / "run_summary.csv")
    metadata = {row["run_label"]: row for row in run_rows}
    samples = defaultdict(list)
    tile_shapes = defaultdict(set)

    for row in read_csv(run_dir / "op_profile.csv"):
        label = row["run_label"]
        meta = metadata.get(label)
        if meta is None or label.startswith("hybrid_"):
            continue
        if row["phase"] != "prefill" or int(row["dim_i"]) == 1:
            continue
        cycles = int(row["gemmini_run_cycles"])
        if cycles <= 0:
            continue

        prompt = int(meta["prompt_tokens"])
        gemmini_count = int(meta["gemmini_count"])
        shape = (int(row["dim_i"]), int(row["dim_j"]), int(row["dim_k"]))
        key = (prompt, shape, dim, gemmini_count)
        samples[key].append(cycles)
        tile_shapes[key].add((int(row["tile_i"]), int(row["tile_j"]), int(row["tile_k"])))

    return samples, tile_shapes, runtime_config, {
        (int(row["prompt_tokens"]), dim, int(row["gemmini_count"])): packing_mask(row)
        for row in run_rows
        if not row["run_label"].startswith("hybrid_")
    }


def merge_runs(run_dirs):
    samples = defaultdict(list)
    tile_shapes = defaultdict(set)
    hardware = {}
    packing = {}
    for run_dir in run_dirs:
        run_samples, run_tiles, runtime_config, run_packing = load_samples(run_dir)
        dim, _ = hardware_dim(run_dir)
        hardware[dim] = runtime_config
        packing.update(run_packing)
        for key, values in run_samples.items():
            samples[key].extend(values)
        for key, values in run_tiles.items():
            tile_shapes[key].update(values)
    return samples, tile_shapes, hardware, packing


def shape_sort_key(shape):
    _, n_dim, k_dim = shape
    order = {
        (512, 2048): 0,
        (2048, 2048): 1,
        (2048, 8192): 2,
        (8192, 2048): 3,
    }
    return order.get((n_dim, k_dim), 100), n_dim, k_dim


def validate_and_summarize(samples, tile_shapes, hardware, packing):
    prompts = sorted({key[0] for key in samples})
    rows = []

    for prompt in prompts:
        shapes = sorted(
            {key[1] for key in samples if key[0] == prompt},
            key=shape_sort_key,
        )
        for shape in shapes:
            baseline_key = (prompt, shape, 16, 1)
            if baseline_key not in samples:
                raise RuntimeError(f"missing 16DIM one-Gemmini baseline for prompt={prompt}, shape={shape}")
            baseline_values = samples[baseline_key]
            baseline_avg = statistics.mean(baseline_values)
            baseline_total = sum(baseline_values)

            for dim, count in CONFIG_ORDER:
                key = (prompt, shape, dim, count)
                if key not in samples:
                    raise RuntimeError(f"missing comparison sample for prompt={prompt}, shape={shape}, config={(dim, count)}")
                values = samples[key]
                if len(values) != len(baseline_values):
                    raise RuntimeError(
                        f"op-count mismatch for prompt={prompt}, shape={shape}: "
                        f"baseline={len(baseline_values)}, config={(dim, count)}={len(values)}"
                    )
                avg_cycles = statistics.mean(values)
                total_cycles = sum(values)
                speedup = baseline_avg / avg_cycles
                mask = packing.get((prompt, dim, count), "unknown")
                rows.append({
                    "phase": "prefill",
                    "prompt_tokens": prompt,
                    "shape_exact": "x".join(str(value) for value in shape),
                    "config": f"{dim}DIM x{count}",
                    "hardware": hardware[dim],
                    "packing_mask": mask,
                    "gemmini_count": count,
                    "op_count": len(values),
                    "avg_gemmini_run_cycles": avg_cycles,
                    "median_gemmini_run_cycles": statistics.median(values),
                    "total_gemmini_run_cycles": total_cycles,
                    "tile_shapes": ";".join(
                        "x".join(str(value) for value in tile)
                        for tile in sorted(tile_shapes[key])
                    ),
                    "baseline_avg_cycles_16dim_1gem": baseline_avg,
                    "baseline_total_cycles_16dim_1gem": baseline_total,
                    "speedup_vs_16dim_1gem": speedup,
                    "perf_improvement_pct_vs_16dim_1gem": (speedup - 1.0) * 100.0,
                    "cycle_reduction_pct_vs_16dim_1gem":
                        (1.0 - avg_cycles / baseline_avg) * 100.0,
                })
    return rows


def write_csv(path, rows):
    with path.open("w", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=list(rows[0].keys()))
        writer.writeheader()
        writer.writerows(rows)


def comparison_label(config, lookup, shapes):
    label, color = COMPARISON_STYLE[config]
    if config == (32, 1):
        config_hardware = lookup[(shapes[0], config[0], config[1])]["hardware"]
        if "fourdma" in config_hardware.lower():
            label = "32DIM 1 Gemmini (4 DMA)"
    return label, color


def plot_prompt(path, prompt, rows):
    prompt_rows = [row for row in rows if row["prompt_tokens"] == prompt]
    shapes = sorted(
        {row["shape_exact"] for row in prompt_rows},
        key=lambda text: shape_sort_key(tuple(int(value) for value in text.split("x"))),
    )
    configs = list(COMPARISON_STYLE)
    lookup = {
        (row["shape_exact"], int(row["config"].split("DIM")[0]), row["gemmini_count"]): row
        for row in prompt_rows
    }

    fig, axis = plt.subplots(figsize=(16, 7.5))
    x = np.arange(len(shapes), dtype=float)
    width = 0.78 / len(configs)

    all_improvements = []
    for index, config in enumerate(configs):
        label, color = comparison_label(config, lookup, shapes)
        offset = (index - (len(configs) - 1) / 2) * width
        improvements = [
            float(lookup[(shape, config[0], config[1])]["perf_improvement_pct_vs_16dim_1gem"])
            for shape in shapes
        ]
        all_improvements.extend(improvements)
        bars = axis.bar(x + offset, improvements, width=width * 0.92, label=label, color=color)
        axis.bar_label(bars, fmt="%.1f%%", padding=3, fontsize=9)

    minimum = min(0.0, min(all_improvements))
    maximum = max(0.0, max(all_improvements))
    margin = max(8.0, (maximum - minimum) * 0.18)
    axis.set_ylim(minimum - margin, maximum + margin)
    axis.axhline(0.0, color="#666666", linewidth=1)
    axis.set_xticks(x, shapes, rotation=32, ha="right")
    axis.set_xlabel("Matmul shape MxNxK")
    axis.set_ylabel("Performance improvement (%)")
    axis.set_title("Prefill, gemmini_run_cycles only", fontsize=14)
    axis.grid(axis="y", alpha=0.3)
    axis.legend(
        loc="upper center",
        bbox_to_anchor=(0.5, -0.22),
        ncol=4,
        frameon=False,
        title="Compared configuration",
    )
    fig.suptitle(
        f"Prompt length {prompt}: performance improvement vs packed 16DIM 1 Gemmini",
        fontsize=18,
        fontweight="bold",
        y=0.98,
    )
    fig.subplots_adjust(top=0.84, bottom=0.30, left=0.08, right=0.98)
    fig.savefig(path, dpi=200)
    plt.close(fig)


def plot_prompt_speedup(path, prompt, rows):
    prompt_rows = [row for row in rows if row["prompt_tokens"] == prompt]
    shapes = sorted(
        {row["shape_exact"] for row in prompt_rows},
        key=lambda text: shape_sort_key(tuple(int(value) for value in text.split("x"))),
    )
    configs = list(COMPARISON_STYLE)
    lookup = {
        (row["shape_exact"], int(row["config"].split("DIM")[0]), row["gemmini_count"]): row
        for row in prompt_rows
    }

    fig, axis = plt.subplots(figsize=(16, 7.5))
    x = np.arange(len(shapes), dtype=float)
    width = 0.78 / len(configs)

    all_speedups = []
    for index, config in enumerate(configs):
        label, color = comparison_label(config, lookup, shapes)
        offset = (index - (len(configs) - 1) / 2) * width
        speedups = [
            float(lookup[(shape, config[0], config[1])]["speedup_vs_16dim_1gem"])
            for shape in shapes
        ]
        all_speedups.extend(speedups)
        bars = axis.bar(x + offset, speedups, width=width * 0.92, label=label, color=color)
        axis.bar_label(bars, labels=[f"{value:.2f}x" for value in speedups], padding=3, fontsize=9)

    maximum = max(all_speedups)
    margin = max(0.25, maximum * 0.12)
    axis.set_ylim(0.0, maximum + margin)
    axis.axhline(1.0, color="#666666", linewidth=1.2, linestyle="--")
    axis.text(
        0.99,
        1.0 + maximum * 0.025,
        "1.00x baseline",
        ha="right",
        va="bottom",
        color="#555555",
        fontsize=9,
        transform=axis.get_yaxis_transform(),
        bbox={"facecolor": "white", "edgecolor": "none", "alpha": 0.8, "pad": 1.5},
    )
    axis.set_xticks(x, shapes, rotation=32, ha="right")
    axis.set_xlabel("Matmul shape MxNxK")
    axis.set_ylabel("Performance multiplier (x)")
    axis.set_title("Prefill, gemmini_run_cycles only", fontsize=14)
    axis.grid(axis="y", alpha=0.3)
    axis.legend(
        loc="upper center",
        bbox_to_anchor=(0.5, -0.22),
        ncol=4,
        frameon=False,
        title="Compared configuration",
    )
    fig.suptitle(
        f"Prompt length {prompt}: speedup vs packed 16DIM 1 Gemmini",
        fontsize=18,
        fontweight="bold",
        y=0.98,
    )
    fig.subplots_adjust(top=0.84, bottom=0.30, left=0.08, right=0.98)
    fig.savefig(path, dpi=200)
    plt.close(fig)


def main():
    args = parse_args()
    samples, tile_shapes, hardware, packing = merge_runs(args.run_dirs)
    rows = validate_and_summarize(samples, tile_shapes, hardware, packing)
    args.output_dir.mkdir(parents=True, exist_ok=True)

    csv_path = args.output_dir / "gemmini_run_perf_improvement_vs_16dim_1gem.csv"
    write_csv(csv_path, rows)
    print(csv_path)

    for prompt in sorted({row["prompt_tokens"] for row in rows}):
        figure_path = args.output_dir / f"prompt{prompt}_perf_improvement_vs_16dim_1gem_bar.png"
        plot_prompt(figure_path, prompt, rows)
        print(figure_path)

        speedup_figure_path = args.output_dir / f"prompt{prompt}_speedup_vs_16dim_1gem_bar.png"
        plot_prompt_speedup(speedup_figure_path, prompt, rows)
        print(speedup_figure_path)


if __name__ == "__main__":
    main()
