#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
build_dir="$script_dir/build-linux"

cmake -S "$script_dir" -B "$build_dir" -DCMAKE_BUILD_TYPE=Release "$@"
cmake --build "$build_dir" --target redis.hdll --parallel
printf 'Built %s\n' "$build_dir/redis.hdll"
