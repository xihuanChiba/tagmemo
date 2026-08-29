#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$project_dir"

platform_template_dir="$(mktemp -d)"
trap 'rm -rf "$platform_template_dir"' EXIT

flutter create \
  --platforms=android,windows \
  --org com.xihuanchiba \
  --project-name tagmemo \
  "$platform_template_dir"
cp -R "$platform_template_dir/android" "$project_dir/"
cp -R "$platform_template_dir/windows" "$project_dir/"
cp -R "$project_dir/platform_overrides/android/." "$project_dir/android/"
flutter pub get

echo "TagMemo platform files are ready."
