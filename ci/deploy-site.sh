#!/usr/bin/env bash
#
# Nasadí zostavený balík na cieľové prostredie.
#
# Staging aj produkcia nasadzujú ten istý artefakt tým istým spôsobom — líšia sa
# len prostredím a cieľom. Schválenia a kontroly nie sú tu, sú nastavené na
# prostredí (`environment:`), preto je tento skript zámerne hlúpy: skopíruje
# a vypíše, čo skopíroval.
#
# Bez `--target-path` sa iba vypíše obsah balíka — to je režim na workshop.
# V ostrej prevádzke sa zadá priečinok stránky na agentovi alebo pripojený
# share, napr. `/var/www/kalkulacka/staging`.
#
# Použitie:
#   ./ci/deploy-site.sh --version v1.2.1 --environment-name STAGING --package-path "$(Pipeline.Workspace)/app"

set -euo pipefail

version=""
environment_name=""
package_path=""
target_path=""

while [ $# -gt 0 ]; do
  case "$1" in
    --version)          version="$2";          shift 2 ;;
    --environment-name) environment_name="$2"; shift 2 ;;
    --package-path)     package_path="$2";     shift 2 ;;
    --target-path)      target_path="$2";      shift 2 ;;
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

if [ -z "$environment_name" ]; then
  echo "##vso[task.logissue type=error]Chýba povinný parameter --environment-name"
  exit 1
fi

if [ -z "$package_path" ]; then
  echo "##vso[task.logissue type=error]Chýba povinný parameter --package-path"
  exit 1
fi

if [ ! -d "$package_path" ]; then
  echo "##vso[task.logissue type=error]\"$package_path\" nie je priečinok — stiahol sa artefakt \`app\`?"
  exit 1
fi

echo "Nasadzujem verziu $version na $environment_name"
find "$package_path" -type f | sort

if [ -z "$target_path" ]; then
  echo "--target-path nezadaný — kopírovanie preskočené (workshopový režim)."
  exit 0
fi

mkdir -p "$target_path"
cp -R "$package_path"/. "$target_path"/
echo "OK — verzia $version skopírovaná do $target_path."
