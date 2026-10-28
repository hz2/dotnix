# web search and fetch for agents that only have a shell.
# config: ~/.config/dotnix-web/env (sourced) or environment variables:
#   DOTNIX_WEB_BACKEND   duckduckgo | searxng | brave   (default duckduckgo)
#   DOTNIX_WEB_SEARXNG   base url of a searxng instance
#   DOTNIX_WEB_BRAVE_KEY_CMD  command printing a brave search api key
#   DOTNIX_WEB_MAX_CHARS fetch output cap (default 20000)

ua="Mozilla/5.0 (X11; Linux x86_64) dotnix-web"
conf="${XDG_CONFIG_HOME:-$HOME/.config}/dotnix-web/env"
# shellcheck disable=SC1090
[ -f "$conf" ] && . "$conf"

backend="${DOTNIX_WEB_BACKEND:-duckduckgo}"
max_chars="${DOTNIX_WEB_MAX_CHARS:-20000}"

usage() {
  cat <<EOF
usage:
  dotnix-web search [-n count] <query...>   print title, url and snippet per result
  dotnix-web fetch [-r] <url>               print the page as plain text (-r: raw body)
EOF
  exit 2
}

search_duckduckgo() {
  local html
  html=$(curl -fsSL -m 20 -A "$ua" --data-urlencode "q=$1" https://html.duckduckgo.com/html/)
  paste -d '\t' \
    <(htmlq -t '.result__body .result__a' <<<"$html") \
    <(htmlq -a href '.result__body .result__a' <<<"$html") \
    <(htmlq -t '.result__body .result__snippet' <<<"$html") |
    head -n "$2" |
    awk -F '\t' '{ printf "%d. %s\n   %s\n   %s\n\n", NR, $1, $2, $3 }'
}

search_searxng() {
  [ -n "${DOTNIX_WEB_SEARXNG:-}" ] || {
    echo "DOTNIX_WEB_SEARXNG is not set" >&2
    exit 1
  }
  curl -fsSL -m 20 -A "$ua" -G --data-urlencode "q=$1" -d format=json \
    "${DOTNIX_WEB_SEARXNG%/}/search" |
    jq -r --argjson n "$2" '.results[:$n] | to_entries[] |
      "\(.key + 1). \(.value.title)\n   \(.value.url)\n   \(.value.content // "")\n"'
}

search_brave() {
  local key
  key=$(sh -c "${DOTNIX_WEB_BRAVE_KEY_CMD:?DOTNIX_WEB_BRAVE_KEY_CMD is not set}")
  curl -fsSL -m 20 -G --data-urlencode "q=$1" -d "count=$2" \
    -H "Accept: application/json" -H "X-Subscription-Token: $key" \
    https://api.search.brave.com/res/v1/web/search |
    jq -r '.web.results // [] | to_entries[] |
      "\(.key + 1). \(.value.title)\n   \(.value.url)\n   \(.value.description // "")\n"'
}

cmd_search() {
  local count=8
  while getopts "n:" opt; do
    case "$opt" in
    n) count="$OPTARG" ;;
    *) usage ;;
    esac
  done
  shift $((OPTIND - 1))
  [ $# -gt 0 ] || usage
  case "$backend" in
  duckduckgo) search_duckduckgo "$*" "$count" ;;
  searxng) search_searxng "$*" "$count" ;;
  brave) search_brave "$*" "$count" ;;
  *)
    echo "unknown backend: $backend" >&2
    exit 1
    ;;
  esac
}

cmd_fetch() {
  local raw=0
  while getopts "r" opt; do
    case "$opt" in
    r) raw=1 ;;
    *) usage ;;
    esac
  done
  shift $((OPTIND - 1))
  [ $# -eq 1 ] || usage

  local type
  # global, the exit trap runs after this function returns
  tmp=$(mktemp)
  trap 'rm -f "$tmp"' EXIT
  type=$(curl -fsSL -m 30 -A "$ua" -o "$tmp" -w '%{content_type}' "$1")

  if [ "$raw" = 1 ] || [[ $type != *html* ]]; then
    head -c "$max_chars" "$tmp"
  else
    w3m -dump -T text/html -cols 120 -o display_link_number=1 <"$tmp" | head -c "$max_chars"
  fi
  if [ "$(wc -c <"$tmp")" -gt "$max_chars" ]; then
    printf '\n[truncated at %s chars]\n' "$max_chars"
  fi
}

[ $# -gt 0 ] || usage
sub="$1"
shift
case "$sub" in
search) cmd_search "$@" ;;
fetch) cmd_fetch "$@" ;;
*) usage ;;
esac
