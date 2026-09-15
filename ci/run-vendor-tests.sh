#!/usr/bin/env bash
#
# Spustí testy dodávateľa proti zostavenému balíku.
#
# Testy bežia proti tomu, čo sa naozaj zostavilo: `src/` z klonu nahradíme
# balíkom z Build (aj s dosadenou verziou). Priečinok najprv mažeme — kopírovanie
# do už existujúceho priečinka vie podpriečinky zanoriť do seba (`src/hooks/hooks`).
#
# `tests/` je v koreni repozitára dodávateľa, aplikácia v `src/`.
#
# Použitie:
#   ./ci/run-vendor-tests.sh --package-path "$(Pipeline.Workspace)/build-output"

set -euo pipefail

package_path=""
vendor_root="vendor"
source_dir="src"
test_dir="tests"

while [ $# -gt 0 ]; do
  case "$1" in
    --package-path) package_path="$2"; shift 2 ;;
    --vendor-root)  vendor_root="$2";  shift 2 ;;
    --source-dir)   source_dir="$2";   shift 2 ;;
    --test-dir)     test_dir="$2";     shift 2 ;;
    *)
      echo "##vso[task.logissue type=error]Neznámy parameter: $1"
      exit 1
      ;;
  esac
done

if [ -z "$package_path" ]; then
  echo "##vso[task.logissue type=error]Chýba povinný parameter --package-path"
  exit 1
fi

if [ ! -d "$package_path" ]; then
  echo "##vso[task.logissue type=error]\"$package_path\" nie je priečinok — stiahol sa artefakt z Build?"
  exit 1
fi

if [ ! -d "$vendor_root" ]; then
  echo "##vso[task.logissue type=error]\"$vendor_root\" nie je priečinok — stiahol sa kód dodávateľa?"
  exit 1
fi

target="$vendor_root/$source_dir"
rm -rf "$target"
cp -R "$package_path" "$target"

# Testy sa spúšťajú z koreňa klonu, preto podshell — `cd` tak neovplyvní
# zvyšok skriptu a návratový kód sa nestratí.
exit_code=0
(cd "$vendor_root" && node --test --test-reporter=spec "$test_dir") || exit_code=$?

if [ "$exit_code" -ne 0 ]; then
  echo "##vso[task.logissue type=error]Testy zlyhali (exit $exit_code)"
  exit "$exit_code"
fi

echo "OK — testy dodávateľa prešli proti zostavenému balíku."
