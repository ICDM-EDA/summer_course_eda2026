#!/usr/bin/env bash
set -euo pipefail
root=$(cd "$(dirname "$0")" && pwd)
if [[ $# -ne 2 ]]; then
  echo "Usage: ./run_reference.sh <testcase.txt> <output-prefix>" >&2
  exit 2
fi
exec "$root/run_pipeline.sh" "$root/partition" "$1" "$2"
