#!/usr/bin/env bash
set -euo pipefail

echo "=== TRACE CONTRACT CHECK ==="

cargo test --test discovery_trace_artifact_shape -- --test-threads=1
cargo test --test discovery_trace_archive_shape -- --test-threads=1
cargo test --test discovery_trace_manifest -- --test-threads=1
cargo test --test discovery_trace_verify -- --test-threads=1
cargo test --test discovery_trace_isolated_artifacts -- --test-threads=1

echo "TRACE CONTRACT: OK"
