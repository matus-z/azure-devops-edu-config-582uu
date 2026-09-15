#!/usr/bin/env bash
#
# Overí, že dokumentácia zodpovedá nasadzovanej verzii.
#
# Nasadenie bez popisu zmeny je presne to, čo schvaľovateľovi chýba, keď sa
# rozhoduje. Preto sa kontroluje spolu s testami, ešte pred publikovaním.
#
# Použitie:
#   ./ci/test-documentation.sh --version v1.2.1 [--path docs]

set -euo pipefail

version=""
path="docs"
required="CHANGELOG.md popis-zmeny.md"
changelog="CHANGELOG.md"

while [ $# -gt 0 ]; do
  case "$1" in
    --version)   version="$2";   shift 2 ;;
    --path)      path="$2";      shift 2 ;;
    --required)  required="$2";  shift 2 ;;
    --changelog) changelog="$2"; shift 2 ;;
    *)
      echo "##vso[task.logissue type=error]Neznámy parameter: $1"
      exit 1
      ;;
  esac
done

if [ -z "$version" ]; then
  echo "##vso[task.logissue type=error]Chýba povinný parameter --version"
  exit 1
fi

missing=""
for file in $required; do
  if [ ! -f "$path/$file" ]; then
    missing="${missing:+$missing, }$path/$file"
  fi
done

if [ -n "$missing" ]; then
  echo "##vso[task.logissue type=error]Chýba: $missing"
  exit 1
fi

if ! grep -qF -- "$version" "$path/$changelog"; then
  echo "##vso[task.logissue type=error]$changelog nespomína verziu $version"
  exit 1
fi

echo "Dokumentácia k verzii $version je na mieste."
