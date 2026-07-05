#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: ./run_pipeline.sh <partition-executable> <testcase.txt> <output-prefix>" >&2
  exit 2
fi

root=$(cd "$(dirname "$0")" && pwd)
partition_exe=$(realpath "$1")
input=$(realpath "$2")
prefix=$(realpath -m "$3")
mkdir -p "$(dirname "$prefix")"
work=$(mktemp -d "${TMPDIR:-/tmp}/iccad-partition-flow.XXXXXX")
trap 'rm -rf "$work"' EXIT

for tool in partition_checker placement placer terminal_stage evaluator shmetis; do
  ln -s "$root/$tool" "$work/$tool"
done
ln -s "$partition_exe" "$work/partition"

cd "$work"
./partition "$input" "${prefix}.part"
./partition_checker "$input" "${prefix}.part"
./placement "$input" "${prefix}.part" "${prefix}.place"
./terminal_stage "$input" "${prefix}.place" "${prefix}.out"
./evaluator "$input" "${prefix}.out"

echo "Partition: ${prefix}.part"
echo "Placement: ${prefix}.place"
echo "Solution:  ${prefix}.out"
