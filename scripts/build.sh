#!/usr/bin/env bash
set -euo pipefail

# Build with Zig and move zig-out to build/ so repository root remains clean.
# Usage: ./scripts/build.sh

echo "Running zig build..."
zig build

mkdir -p build
if [ -d zig-out ]; then
  echo "Moving zig-out -> build/zig-out"
  rm -rf build/zig-out || true
  mv zig-out build/
fi

echo "Build outputs are in build/"
