#!/usr/bin/env bash
#
# Stiahne kód dodávateľa na danom tagu.
#
# Klonujeme skriptom a nie cez `resources.repositories`, lebo ref v
# `resources` sa vyhodnocuje pri kompilácii pipeline, takže sa nedá načítať
# zo súboru. Vďaka tomu je zmena verzie zmenou vo `version.json`, nie
# zmenou pipeline.
#
# Token sa neposiela v adrese, ale hlavičkou — `https://<token>@host` dá git
# token ako používateľské meno, heslo si potom vypýta z terminálu a v pipeline
# to padne na "terminal prompts disabled". Berie sa z premennej prostredia, aby
# sa nedostal do logu.
#
# Prijímame dva druhy prihlásenia; v kroku treba namapovať jeden z nich:
#
#     env:
#       VENDOR_TOKEN: $(vendorPat)            # PAT — posiela sa ako `basic`
#       SYSTEM_ACCESSTOKEN: $(System.AccessToken)   # token jobu — ako `bearer`
#
# PAT je potrebný tam, kde je zapnuté "Limit job authorization scope to current
# repository": token jobu je vtedy platný len pre konfiguračný repozitár a
# klonovanie repozitára dodávateľa skončí na TF401019 ("does not exist or you
# don't have permissions"), nech je na repozitári nastavené čokoľvek. PAT tomu
# nepodlieha — stačí mu rozsah Code (Read) na repozitár dodávateľa.
#
# Použitie:
#   ./ci/get-vendor-source.sh --url https://adoserver.koop.sk/DefaultCollection/EDU/_git/EDU --tag v1.2.1

set -euo pipefail

url=""
tag=""
destination="vendor"
access_token="${SYSTEM_ACCESSTOKEN:-}"
vendor_token="${VENDOR_TOKEN:-}"

# Nenamapovaná premenná ostáva v kroku ako doslovné `$(vendorPat)` — to nie je
# token, berieme to ako prázdnu hodnotu.
case "$vendor_token" in '$('*) vendor_token="" ;; esac

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

# PAT má prednosť: ak je v projekte obmedzený rozsah tokenu jobu, je to jediné
# prihlásenie, ktoré na repozitár dodávateľa dosiahne.
if [ -n "$vendor_token" ]; then
  # PAT sa posiela ako `basic`, s prázdnym menom a tokenom namiesto hesla.
  auth_header="AUTHORIZATION: basic $(printf ':%s' "$vendor_token" | base64 | tr -d '\n')"
elif [ -n "$access_token" ]; then
  # Token jobu je OAuth — rovnako sa autentifikuje aj sám agent pri `checkout`.
  auth_header="AUTHORIZATION: bearer $access_token"
else
  echo "##vso[task.logissue type=error]Chýba token — v kroku treba namapovať VENDOR_TOKEN: \$(vendorPat) alebo SYSTEM_ACCESSTOKEN: \$(System.AccessToken)"
  exit 1
fi

if ! git -c http.extraheader="$auth_header" \
       clone --depth 1 --branch "$tag" "$url" "$destination"; then
  echo "##vso[task.logissue type=error]Tag '$tag' sa nepodarilo načítať — existuje?"
  exit 1
fi

echo "OK — tag $tag stiahnutý do \"$destination\"."
