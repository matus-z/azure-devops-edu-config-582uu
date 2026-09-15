#!/usr/bin/env bash
#
# Stiahne kód dodávateľa na danom tagu.
#
# Klonujeme skriptom a nie cez `resources.repositories`, lebo ref v
# `resources` sa vyhodnocuje pri kompilácii pipeline, takže sa nedá načítať
# zo súboru. Vďaka tomu je zmena verzie zmenou vo `version.json`, nie
# zmenou pipeline.
#
# Token sa do adresy vkladá až tu a berie sa z premennej prostredia, aby sa
# nedostal do príkazového riadku ani do logu. V kroku ho treba namapovať:
#
#     env:
#       SYSTEM_ACCESSTOKEN: $(System.AccessToken)
#
# Použitie:
#   ./ci/get-vendor-source.sh --url https://adoserver.koop.sk/DefaultCollection/EDU/_git/Dev --tag v1.2.1

set -euo pipefail

url=""
tag=""
destination="vendor"
access_token="${SYSTEM_ACCESSTOKEN:-}"

while [ $# -gt 0 ]; do
  case "$1" in
    --url)          url="$2";          shift 2 ;;
    --tag)          tag="$2";          shift 2 ;;
    --destination)  destination="$2";  shift 2 ;;
    *)
      echo "##vso[task.logissue type=error]Neznámy parameter: $1"
      exit 1
      ;;
  esac
done

if [ -z "$url" ]; then
  echo "##vso[task.logissue type=error]Chýba povinný parameter --url"
  exit 1
fi

if [ -z "$tag" ]; then
  echo "##vso[task.logissue type=error]Chýba povinný parameter --tag"
  exit 1
fi

if [ -z "$access_token" ]; then
  echo "##vso[task.logissue type=error]Chýba token — v kroku treba namapovať SYSTEM_ACCESSTOKEN: \$(System.AccessToken)"
  exit 1
fi

auth_url="${url/https:\/\//https://$access_token@}"

if ! git clone --depth 1 --branch "$tag" "$auth_url" "$destination"; then
  echo "##vso[task.logissue type=error]Tag '$tag' sa nepodarilo načítať — existuje?"
  exit 1
fi

echo "OK — tag $tag stiahnutý do \"$destination\"."
