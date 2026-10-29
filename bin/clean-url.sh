#!/data/data/com.termux/files/usr/bin/bash
# Remove X/Twitter tracking query strings and fragments.
#
# X/Twitter status URLs carry tracking parameters such as "?a=<account>&s=20".
# Every other site keeps its query string, so YouTube's ?v= and ?list= survive.
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "Usage: clean-url.sh URL" >&2
  exit 2
fi

url="$1"
base="${url%%\?*}"
base="${base%%#*}"

case "$base" in
  http://*|https://*) ;;
  *) printf '%s\n' "$url"; exit 0 ;;
esac

rest="${base#*://}"
case "$rest" in
  */*) authority="${rest%%/*}" ;;
  *)   authority="$rest" ;;
esac

host="${authority##*@}"
host="${host%%:*}"
host="${host,,}"
host="${host%.}"

case "$host" in
  x.com|www.x.com|mobile.x.com|m.x.com|twitter.com|www.twitter.com|mobile.twitter.com|m.twitter.com)
    printf '%s\n' "$base"
    ;;
  *)
    printf '%s\n' "$url"
    ;;
esac
