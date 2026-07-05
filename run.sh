#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "Usage: ./run.sh <testcase.txt> <output-prefix>" >&2
  echo "Replace a stage with PARTITION=..., PLACEMENT=..., TERMINAL=..., or EVALUATOR=..." >&2
  exit 2
fi

ROOT=$(cd "$(dirname "$0")" && pwd)
INPUT=$(realpath "$1")
PREFIX=$(realpath -m "$2")

PARTITION=$(realpath "${PARTITION:-$ROOT/partition}")
PLACEMENT=$(realpath "${PLACEMENT:-$ROOT/placement}")
TERMINAL=$(realpath "${TERMINAL:-$ROOT/terminal_stage}")
EVALUATOR=$(realpath "${EVALUATOR:-$ROOT/evaluator}")

PART_FILE="${PREFIX}.part"
PLACE_FILE="${PREFIX}.place"
FINAL_FILE="${PREFIX}.out"
mkdir -p "$(dirname "$PREFIX")"

# The reference placement wrapper expects ./placer in this directory.
cd "$ROOT"

echo "[1/4] Partition"
echo "  $INPUT -> $PART_FILE"
"$PARTITION" "$INPUT" "$PART_FILE"

echo "[2/4] Placement"
echo "  $INPUT + $PART_FILE -> $PLACE_FILE"
"$PLACEMENT" "$INPUT" "$PART_FILE" "$PLACE_FILE"

echo "[3/4] Terminal insertion"
echo "  $INPUT + $PLACE_FILE -> $FINAL_FILE"
"$TERMINAL" "$INPUT" "$PLACE_FILE" "$FINAL_FILE"

echo "[4/4] Evaluator"
echo "  $INPUT + $FINAL_FILE -> evaluation report"
"$EVALUATOR" "$INPUT" "$FINAL_FILE"

echo "Done: $PART_FILE $PLACE_FILE $FINAL_FILE"
