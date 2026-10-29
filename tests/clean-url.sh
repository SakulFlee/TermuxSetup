#!/data/data/com.termux/files/usr/bin/bash
# Unit tests for bin/clean-url.sh.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLEAN="$ROOT/bin/clean-url.sh"
failures=0

check() {
  local input="$1" expected="$2" actual
  actual="$(bash "$CLEAN" "$input")"
  if [ "$actual" = "$expected" ]; then
    printf 'ok: %s\n' "$input"
  else
    printf 'FAIL: %s\n  expected: %s\n  actual:   %s\n' "$input" "$expected" "$actual" >&2
    failures=$((failures + 1))
  fi
}

check \
  'https://x.com/Ara_Arasaka/status/2115859697672814664?a=SpJXRHJzd21qFZOEVQI&s=20' \
  'https://x.com/Ara_Arasaka/status/2115859697672814664'

check \
  'https://twitter.com/foo/status/123?s=20&t=abc' \
  'https://twitter.com/foo/status/123'

check \
  'https://mobile.x.com/foo/status/123/photo/1?a=1#fragment' \
  'https://mobile.x.com/foo/status/123/photo/1'

check \
  'https://x.com/i/web/status/123?a=1' \
  'https://x.com/i/web/status/123'

check \
  'https://x.com/search?q=test' \
  'https://x.com/search'

check \
  'https://www.youtube.com/watch?v=jSYY-zTUOmU&list=PL123&t=30' \
  'https://www.youtube.com/watch?v=jSYY-zTUOmU&list=PL123&t=30'

check \
  'https://example.com/?a=1&b=2' \
  'https://example.com/?a=1&b=2'

check \
  'https://x.com/Ara_Arasaka/status/2115859697672814664' \
  'https://x.com/Ara_Arasaka/status/2115859697672814664'

if [ "$failures" -ne 0 ]; then
  printf '\n%d test(s) failed\n' "$failures" >&2
  exit 1
fi

printf '\nAll URL cleanup tests passed.\n'
