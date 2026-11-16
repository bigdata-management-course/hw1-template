#!/usr/bin/env bash
# Prints a team's HW1 parameters and downloads its hourly Wikimedia pageview dumps (CC0).
set -euo pipefail

usage() {
    cat >&2 <<'EOF'
usage: ./get-data.sh [-n] [-o DIR] [TEAM]
  TEAM  your team repo name (hw1-<team>, a URL works too); default: the origin remote,
        or the reference set (2026-09-15, K=10) if there is none
  -n    print the parameters only
  -o    download directory (default: data/ next to this script); complete files are skipped
EOF
    exit 2
}

print_only=
dir="$(cd "$(dirname "$0")" && pwd)/data"
while getopts no: opt; do
    case $opt in
        n) print_only=1 ;;
        o) dir=$OPTARG ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))
[ $# -le 1 ] || usage

team=${1:-}
if [ -z "$team" ]; then
    team=$(git -C "$(dirname "$0")" remote get-url origin 2>/dev/null || true)
fi
team=$(basename "${team%.git}" | tr '[:upper:]' '[:lower:]')
case $team in hw1-*) ;; *) team= ;; esac

sha256() { if command -v sha256sum >/dev/null; then sha256sum; else shasum -a 256; fi | cut -c1-64; }
# n-th group of 4 hex digits of the seed, as a number
part() { echo $((16#${seed:$(($1 * 4)):4})); }

if [ -z "$team" ]; then
    date=20260915 hours="00 04 08 12 16 20" k=10 langs=
elif [ -z "${HW1_SALT:-}" ]; then
    # Students: a September day and one hour from each 4-hour block, so every team gets
    # a similar volume (~330 MB gz) and the same day/night mix.
    seed=$(printf '%s' "$team" | sha256)
    date=$(printf '202609%02d' $(($(part 0) % 28 + 1)))
    hours=
    for i in 0 1 2 3 4 5; do hours="$hours $(printf '%02d' $((i * 4 + $(part $((i + 1))) % 4)))"; done
    hours=${hours# }
    k=$(($(part 7) % 11 + 5))
    langs=
else
    # Grader only: a secret salt picks an October day, two hours and a language filter.
    seed=$(printf '%s:%s' "$team" "$HW1_SALT" | sha256)
    date=$(printf '202610%02d' $(($(part 0) % 20 + 1)))
    hours=$(printf '%02d %02d' $(($(part 1) % 12)) $(($(part 2) % 12 + 12)))
    k=$(($(part 3) % 9 + 3))
    pool=(de fr es it ja ru pt pl nl zh ar fa uk sv tr ko)
    langs="en,he,${pool[$(($(part 4) % 16))]}"
fi

echo "TEAM=${team:-reference}"
echo "DATE=$date"
echo "HOURS=\"$hours\""
echo "K=$k"
[ -z "$langs" ] || echo "LANGS=$langs"
[ -z "$print_only" ] || exit 0

base=https://dumps.wikimedia.org/other/pageviews/${date:0:4}/${date:0:4}-${date:4:2}
size() { wc -c <"$1" | tr -d ' '; }
remote_size() {
    curl -fsSI --retry 3 -A "Mozilla/5.0" "$base/$1" | tr -d '\r' |
        awk 'tolower($1) == "content-length:" { print $2 }'
}

mkdir -p "$dir"
for h in $hours; do
    f=pageviews-$date-${h}0000.gz
    want=$(remote_size "$f")
    if [ -f "$dir/$f" ] && [ "$(size "$dir/$f")" = "$want" ]; then
        echo "ok       $f"
        continue
    fi
    echo "fetching $f ($want bytes) ..."
    curl -fsSL --retry 3 -A "Mozilla/5.0" -o "$dir/$f.part" "$base/$f"
    got=$(size "$dir/$f.part")
    if [ "$got" != "$want" ]; then
        echo "size mismatch for $f: got $got, want $want" >&2
        exit 1
    fi
    gzip -t "$dir/$f.part"
    mv "$dir/$f.part" "$dir/$f"
    echo "ok       $f"
done

others=$(cd "$dir" && for f in pageviews-*.gz; do
    [ -e "$f" ] || continue
    case " $hours " in *" ${f:19:2} "*) [ "${f:10:8}" = "$date" ] && continue ;; esac
    echo "$f"
done)
if [ -n "$others" ]; then
    echo "warning: $dir also holds files that are not part of this set; move them away before loading HDFS:" >&2
    echo "$others" >&2
fi
echo "your files in $dir:"
for h in $hours; do ls -l "$dir/pageviews-$date-${h}0000.gz"; done
