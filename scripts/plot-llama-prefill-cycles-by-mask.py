#!/usr/bin/env python3
"""Plot end-to-end prefill cycles for each Gemmini mask in a FireSim summary."""

from __future__ import annotations

import argparse
import csv
import math
import re
from dataclasses import dataclass
from pathlib import Path

import matplotlib

matplotlib.use("Agg")

import matplotlib.pyplot as plt


SECTION_RE = re.compile(
    r"^## (?P<label>multi_mask(?P<mask>0x[0-9a-fA-F]+)_ptok(?P<ptok>\d+)_.*)$"
)
GEMMINI_COUNT_RE = re.compile(r"^\|\s*gemmini count\s*\|\s*(?P<count>\d+)\s*\|")
PREFILL_RE = re.compile(
    r"^\|\s*prefill\s*\|\s*(?P<us>\d+)\s*\|\s*(?P<cycles>\d+)\s*\|"
)

MASK_COLORS = {
    "0x1": "#0072B2",
    "0x3": "#D55E00",
    "0x7": "#009E73",
    "0xf": "#CC79A7",
}


@dataclass(frozen=True)
class PrefillRecord:
    run_label: str
    prompt_tokens: int
    gemmini_mask: str
    gemmini_count: int
    prefill_total_us: int
    prefill_total_cycles: int


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Create one bar chart per prompt-token count using the Phase Split "
            "prefill total cycles in a FireSim summary.md file."
        )
    )
    parser.add_argument("summary", type=Path)
    parser.add_argument("--output-dir", required=True, type=Path)
    parser.add_argument(
        "--ptoks",
        nargs="+",
        type=int,
        required=True,
        help="Prompt-token counts to plot.",
    )
    return parser.parse_args()


def parse_summary(path: Path) -> list[PrefillRecord]:
    records: list[PrefillRecord] = []
    current_label: str | None = None
    current_mask: str | None = None
    current_ptok: int | None = None
    current_count: int | None = None
    in_phase_split = False

    for line in path.read_text(encoding="utf-8").splitlines():
        section_match = SECTION_RE.match(line)
        if section_match:
            current_label = section_match.group("label")
            current_mask = section_match.group("mask").lower()
            current_ptok = int(section_match.group("ptok"))
            current_count = None
            in_phase_split = False
            continue

        if current_label is None:
            continue

        count_match = GEMMINI_COUNT_RE.match(line)
        if count_match:
            current_count = int(count_match.group("count"))
            continue

        if line == "### Phase Split":
            in_phase_split = True
            continue
        if line.startswith("### ") and in_phase_split:
            in_phase_split = False

        prefill_match = PREFILL_RE.match(line) if in_phase_split else None
        if prefill_match:
            if current_mask is None or current_ptok is None or current_count is None:
                raise ValueError(f"incomplete metadata for section {current_label}")
            records.append(
                PrefillRecord(
                    run_label=current_label,
                    prompt_tokens=current_ptok,
                    gemmini_mask=current_mask,
                    gemmini_count=current_count,
                    prefill_total_us=int(prefill_match.group("us")),
                    prefill_total_cycles=int(prefill_match.group("cycles")),
                )
            )
            in_phase_split = False

    keys = [(record.prompt_tokens, record.gemmini_mask) for record in records]
    if len(keys) != len(set(keys)):
        raise ValueError("duplicate prompt-token/mask records found")
    return records


def write_csv(records: list[PrefillRecord], path: Path) -> None:
    fields = [
        "run_label",
        "prompt_tokens",
        "gemmini_mask",
        "gemmini_count",
        "prefill_total_us",
        "prefill_total_cycles",
    ]
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields)
        writer.writeheader()
        for record in records:
            writer.writerow({field: getattr(record, field) for field in fields})


def plot_ptok(records: list[PrefillRecord], output_path: Path, y_max_billions: float) -> None:
    prompt_tokens = records[0].prompt_tokens
    masks = [record.gemmini_mask for record in records]
    labels = [
        f"{record.gemmini_mask}\n({record.gemmini_count} Gemmini)" for record in records
    ]
    values = [record.prefill_total_cycles / 1_000_000_000 for record in records]
    colors = [MASK_COLORS.get(mask, "#777777") for mask in masks]

    fig, ax = plt.subplots(figsize=(8.4, 5.8))
    bars = ax.bar(labels, values, width=0.62, color=colors, edgecolor="white", linewidth=0.8)

    ax.set_title(
        f"Prefill cycles by Gemmini mask — ptok {prompt_tokens}",
        fontsize=15,
        fontweight="bold",
        pad=17,
    )
    ax.set_xlabel("Gemmini mask (active Gemmini count)", labelpad=10)
    ax.set_ylabel("Prefill cycles (billions)", labelpad=9)
    ax.set_ylim(0, y_max_billions)
    ax.grid(axis="y", color="#D9D9D9", linewidth=0.8, alpha=0.8)
    ax.set_axisbelow(True)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)

    value_offset = y_max_billions * 0.018
    for bar, value in zip(bars, values):
        ax.text(
            bar.get_x() + bar.get_width() / 2,
            value + value_offset,
            f"{value:.3f}B",
            ha="center",
            va="bottom",
            fontsize=10,
            fontweight="semibold",
        )

    fig.text(
        0.5,
        0.025,
        "Source metric: summary.md → Phase Split → prefill → total cycles (end-to-end prefill)",
        ha="center",
        fontsize=8.5,
        color="#555555",
    )
    fig.subplots_adjust(left=0.13, right=0.98, top=0.87, bottom=0.18)
    fig.savefig(output_path, dpi=220, bbox_inches="tight", facecolor="white")
    plt.close(fig)


def main() -> None:
    args = parse_args()
    requested_ptoks = list(dict.fromkeys(args.ptoks))
    requested_set = set(requested_ptoks)
    selected = [
        record
        for record in parse_summary(args.summary)
        if record.prompt_tokens in requested_set
    ]

    found_ptoks = {record.prompt_tokens for record in selected}
    missing_ptoks = [ptok for ptok in requested_ptoks if ptok not in found_ptoks]
    if missing_ptoks:
        raise ValueError(f"requested ptok values not found: {missing_ptoks}")

    records_by_ptok: dict[int, list[PrefillRecord]] = {}
    for ptok in requested_ptoks:
        records_by_ptok[ptok] = sorted(
            (record for record in selected if record.prompt_tokens == ptok),
            key=lambda record: int(record.gemmini_mask, 16),
        )

    expected_masks = {record.gemmini_mask for record in records_by_ptok[requested_ptoks[0]]}
    for ptok, records in records_by_ptok.items():
        masks = {record.gemmini_mask for record in records}
        if masks != expected_masks:
            raise ValueError(
                f"mask mismatch for ptok {ptok}: expected {sorted(expected_masks)}, "
                f"found {sorted(masks)}"
            )

    args.output_dir.mkdir(parents=True, exist_ok=True)
    ordered_records = [
        record for ptok in requested_ptoks for record in records_by_ptok[ptok]
    ]
    write_csv(ordered_records, args.output_dir / "prefill_cycles_by_mask.csv")

    max_billions = max(record.prefill_total_cycles for record in selected) / 1_000_000_000
    y_max_billions = math.ceil(max_billions * 1.10 * 2) / 2
    for ptok, records in records_by_ptok.items():
        output_path = args.output_dir / f"ptok{ptok}_prefill_cycles_by_gemmini_mask.png"
        plot_ptok(records, output_path, y_max_billions)
        print(output_path)

    print(args.output_dir / "prefill_cycles_by_mask.csv")


if __name__ == "__main__":
    main()
