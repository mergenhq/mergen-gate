#!/usr/bin/env bash
set -euo pipefail

cargo test --test discovery_pipeline_exact_closure -- --test-threads=1
cargo test --test discovery_pipeline_closure -- --test-threads=1
cargo test --test discovery_pipeline_bounds -- --test-threads=1
cargo test --test discovery_pipeline_provenance -- --test-threads=1
cargo test --test discovery_pipeline_trace_shape -- --test-threads=1
cargo test --test discovery_trace_export -- --test-threads=1
cargo test --test discovery_trace_snapshot -- --test-threads=1
cargo test --test discovery_trace_artifact_shape -- --test-threads=1
cargo test --test discovery_trace_archive_shape -- --test-threads=1
cargo test --test discovery_trace_manifest -- --test-threads=1
cargo test --test discovery_trace_verify -- --test-threads=1
cargo test --test discovery_trace_isolated_artifacts -- --test-threads=1

cargo test --lib ruleset_alignment_is_exact -- --test-threads=1
cargo test --lib rule_ids_are_unique -- --test-threads=1
cargo test --lib enabled_registry_matches_legacy_tuple_contract -- --test-threads=1
