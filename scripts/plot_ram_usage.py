#!/usr/bin/env python3
"""Plot RAM usage relative to the first sample in a RAM usage log."""

from __future__ import annotations

import argparse
import re
from datetime import datetime
from pathlib import Path

import matplotlib.pyplot as plt


SAMPLE_PATTERN = re.compile(
    r"^(?P<timestamp>\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})"
    r".*?\| used:\s*(?P<used>[+-]?(?:\d+(?:\.\d*)?|\.\d+))\s+GB\b"
)


def read_samples(path: Path) -> tuple[list[datetime], list[float]]:
    """Read timestamps and used RAM values from a recording log."""
    timestamps: list[datetime] = []
    used_gb: list[float] = []

    with path.open(encoding="utf-8") as log_file:
        for line_number, line in enumerate(log_file, start=1):
            line = line.strip()
            if not line:
                continue

            match = SAMPLE_PATTERN.match(line)
            if match is None:
                raise ValueError(f"{path}:{line_number}: unrecognized log entry")

            timestamps.append(
                datetime.strptime(match.group("timestamp"), "%Y-%m-%d %H:%M:%S")
            )
            used_gb.append(float(match.group("used")))

    if not timestamps:
        raise ValueError(f"{path}: no RAM usage samples found")

    return timestamps, used_gb


def plot_ram_usage(input_path: Path, output_path: Path, show: bool = False) -> None:
    """Create a plot of RAM usage change from the first recorded sample."""
    timestamps, used_gb = read_samples(input_path)
    initial_used_gb = used_gb[0]
    elapsed_hours = [
        (timestamp - timestamps[0]).total_seconds() / 3600
        for timestamp in timestamps
    ]
    delta_gb = [value - initial_used_gb for value in used_gb]

    figure, axis = plt.subplots(figsize=(10, 5.5))
    axis.plot(elapsed_hours, delta_gb, marker=".", linewidth=1.2)
    axis.axhline(0, color="black", linewidth=0.8, alpha=0.6)
    axis.set_xlabel("Time since first sample (hours)")
    axis.set_ylabel("RAM used - initial RAM (GB)")
    axis.set_title("Change in RAM Usage")
    axis.grid(True, alpha=0.3)
    figure.tight_layout()
    figure.savefig(output_path, dpi=150)

    if show:
        plt.show()
    else:
        plt.close(figure)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Plot RAM usage relative to the first sample."
    )
    parser.add_argument(
        "input",
        nargs="?",
        type=Path,
        default=Path("ram_usage.txt"),
        help="RAM usage log (default: ram_usage.txt)",
    )
    parser.add_argument(
        "-o",
        "--output",
        type=Path,
        default=Path("ram_usage_delta.png"),
        help="output image path (default: ram_usage_delta.png)",
    )
    parser.add_argument(
        "--show",
        action="store_true",
        help="also display the plot interactively",
    )
    args = parser.parse_args()

    plot_ram_usage(args.input, args.output, args.show)
    print(f"Saved plot to {args.output}")


if __name__ == "__main__":
    main()
