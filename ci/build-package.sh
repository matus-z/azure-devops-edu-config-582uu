#!/usr/bin/env bash
#
# Zostaví balík z kódu dodávateľa a zapíše doň nasadzovanú verziu.
#
# Verziu zapisujeme do stránky, aby bola viditeľná aj bez otvorenia pipeline.
# Keby placeholder chýbal, nahradenie by ticho neurobilo nič a verzia by sa na
# stránku nedostala — preto zlyháme hlasne.
#
# Použitie:
#   ./ci/build-package.sh --version v1.2.1 [--source vendor/src] [--destination dist]

set -euo pipefail

version=""
source_dir="vendor/src"
destination="dist"
page="index.html"
placeholder="__VERSION__"

while [ $# -gt 0 ]; do
  case "$1" in
    --version)      version="$2";     shift 2 ;;
    --source)       source_dir="$2";  shift 2 ;;
    --destination)  destination="$2"; shift 2 ;;
    --page)         page="$2";        shift 2 ;;
    --placeholder)  placeholder="$2"; shift 2 ;;
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

if [ ! -d "$source_dir" ]; then
  echo "##vso[task.logissue type=error]\"$source_dir\" nie je priečinok — stiahol sa kód dodávateľa?"
  exit 1
fi

mkdir -p "$destination"
cp -R "$source_dir"/. "$destination"/

page_path="$destination/$page"
if [ ! -f "$page_path" ]; then
  echo "##vso[task.logissue type=error]$page_path neexistuje"
  exit 1
fi

content="$(cat "$page_path")"
case "$content" in
  *"$placeholder"*) ;;
  *)
    echo "##vso[task.logissue type=error]$page_path neobsahuje $placeholder — verzia by sa na stránku nedostala"
    exit 1
    ;;
esac

printf '%s' "${content//"$placeholder"/$version}" > "$page_path"

echo "Balík zostavený, verzia $version zapísaná do $page:"
find "$destination" -type f | sort
