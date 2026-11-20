#!/usr/bin/env bash
# Smoke test: builds the jar and runs every task on smoke/sample with Hadoop 3.4.1 in local mode.
# It checks output formats and internal consistency only; it does not know the correct answers.
# shellcheck disable=SC2016 # awk programs are passed in single quotes on purpose
set -uo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
HADOOP_VERSION=3.4.1
HADOOP_SHA512=822cb1531333847e740d942cacf24295a588255786afe11f11c8ff9695be1caae425ddbafd4fda8b0f1fce88336efa05f16d5425659ab225075864ab6b8702bf
CACHE=${HW1_CACHE:-$HOME/.cache/hw1-hadoop}
IN=$ROOT/smoke/sample
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

fails=0
report=()
pass() { report+=("PASS  $*"); }
fail() {
    report+=("FAIL  $*")
    fails=$((fails + 1))
}

sha512() { if command -v sha512sum >/dev/null; then sha512sum "$1"; else shasum -a 512 "$1"; fi | cut -c1-128; }

hadoop_install() {
    local dir=$CACHE/hadoop-$HADOOP_VERSION f=hadoop-$HADOOP_VERSION-lean.tar.gz
    if [ ! -x "$dir/bin/hadoop" ]; then
        mkdir -p "$CACHE"
        echo "downloading Hadoop $HADOOP_VERSION (once, ~500 MB) ..."
        curl -fsSL -A "Mozilla/5.0" -o "$CACHE/$f" "https://dlcdn.apache.org/hadoop/common/hadoop-$HADOOP_VERSION/$f" ||
            curl -fsSL -A "Mozilla/5.0" -o "$CACHE/$f" "https://archive.apache.org/dist/hadoop/common/hadoop-$HADOOP_VERSION/$f" ||
            return 1
        [ "$(sha512 "$CACHE/$f")" = "$HADOOP_SHA512" ] || return 1
        tar -xzf "$CACHE/$f" -C "$CACHE" --exclude "*/share/doc" && rm -f "$CACHE/$f"
    fi
    export HADOOP_HOME=$dir PATH=$dir/bin:$PATH
    # Default config of the tarball = local mode on the local file system.
    export HADOOP_CONF_DIR=$dir/etc/hadoop
}

# run <name> <command...>: log to $WORK/<name>.log
run() {
    local name=$1
    shift
    echo "running $name ..."
    if "$@" >"$WORK/$name.log" 2>&1; then
        pass "$name: job finished"
        return 0
    fi
    fail "$name: job failed (log tail printed above)"
    tail -15 "$WORK/$name.log" | sed 's/^/      /'
    return 1
}

out() { cat "$WORK/$1"/part-* 2>/dev/null; }
counter() { sed -n -E "s/^[[:space:]]*$2=([0-9]+)$/\1/p" "$WORK/$1.log" | tail -1; }

# check_lines <name> <dir> <awk program that prints offending lines>
check_lines() {
    local bad
    if [ -z "$(out "$2")" ]; then
        fail "$1: empty output"
        return
    fi
    bad=$(out "$2" | LC_ALL=C awk -F'\t' "$3" | head -3)
    if [ -n "$bad" ]; then
        fail "$1: unexpected lines, e.g.:"
        report+=("      $bad")
    else
        pass "$1"
    fi
}

cd "$ROOT" || exit 1
command -v python3 >/dev/null || {
    echo "python3 is required" >&2
    exit 1
}

if mvn -q -B -f java/pom.xml package >"$WORK/build.log" 2>&1; then
    pass "build: mvn package"
else
    fail "build: mvn package"
    tail -30 "$WORK/build.log"
fi
JAR=$ROOT/java/target/hw1.jar
[ -f "$JAR" ] || {
    printf '%s\n' "${report[@]}"
    exit 1
}
hadoop_install || {
    echo "could not install Hadoop" >&2
    exit 1
}

R=(-D mapreduce.job.reduces=2)
HW1=(hadoop jar "$JAR")

if run task1 "${HW1[@]}" project-views "${R[@]}" "$IN" "$WORK/t1"; then
    check_lines "task1: format project<TAB>total" t1 'NF != 2 || $2 !~ /^[0-9]+$/'
    if [ "$(counter task1 'Combine input records')" -gt 0 ] 2>/dev/null; then
        pass "task1: combiner runs by default"
    else
        fail "task1: no combiner ran (Combine input records)"
    fi
    if [ "$(counter task1 MALFORMED)" -gt 0 ] 2>/dev/null; then
        pass "task1: MALFORMED counter"
    else
        fail "task1: no MALFORMED counter (the sample has malformed lines)"
    fi
fi

if run task1-nocombiner "${HW1[@]}" project-views "${R[@]}" -D hw1.combiner=false "$IN" "$WORK/t1-nocombiner"; then
    if [ "$(counter task1-nocombiner 'Combine input records')" -gt 0 ] 2>/dev/null; then
        fail "task1: -D hw1.combiner=false still runs a combiner"
    else
        pass "task1: -D hw1.combiner=false disables the combiner"
    fi
    if [ -n "$(out t1)" ] && diff <(out t1 | LC_ALL=C sort) <(out t1-nocombiner | LC_ALL=C sort) >/dev/null; then
        pass "task1: same output with and without combiner"
    else
        fail "task1: output changes when the combiner is off"
    fi
fi

if run task1-python mapred streaming "${R[@]}" -files "$ROOT/python/mapper.py,$ROOT/python/reducer.py" \
    -mapper "python3 mapper.py" -combiner "python3 reducer.py" -reducer "python3 reducer.py" \
    -input "$IN" -output "$WORK/t1-python"; then
    if [ -z "$(out t1-python)" ]; then
        fail "task1: Python output is empty"
    elif diff <(out t1 | LC_ALL=C sort) <(out t1-python | LC_ALL=C sort) >"$WORK/t1.diff"; then
        pass "task1: Java and Python outputs are identical"
    else
        fail "task1: Java and Python outputs differ (diff head below)"
        report+=("$(head -6 "$WORK/t1.diff" | sed 's/^/      /')")
    fi
fi

if run task2 "${HW1[@]}" hourly-profile "${R[@]}" "$IN" "$WORK/t2"; then
    # mobile% must be 100*mobile/(desktop+mobile) with one decimal; hours come from the two file names.
    check_lines "task2: format lang<TAB>hour<TAB>desktop<TAB>mobile<TAB>mobile%" t2 \
        'NF != 5 || $2 !~ /^(00|12)$/ || $3 !~ /^[0-9]+$/ || $4 !~ /^[0-9]+$/ || $5 !~ /^[0-9]+\.[0-9]$/ ||
         ($3 + $4 > 0 && (100 * $4 / ($3 + $4) - $5 > 0.051 || $5 - 100 * $4 / ($3 + $4) > 0.051))'
fi
if run task2-langs "${HW1[@]}" hourly-profile "${R[@]}" -D hw1.langs=en,he "$IN" "$WORK/t2-langs"; then
    check_lines "task2: -D hw1.langs=en,he keeps only en and he" t2-langs '$1 != "en" && $1 != "he"'
fi

if [ -d "$WORK/t1" ] && run task3 "${HW1[@]}" language-join "${R[@]}" "$WORK/t1" "$ROOT/languages.tsv" "$WORK/t3"; then
    check_lines "task3: format lang<TAB>name<TAB>views" t3 'NF != 3 || $3 !~ /^[0-9]+$/ || $1 ~ /\./'
    if grep -q "	UNKNOWN	" < <(out t3); then
        pass "task3: codes missing from languages.tsv are kept as UNKNOWN"
    else
        fail "task3: no UNKNOWN rows (left outer join?)"
    fi
fi

before=$(ls "$WORK")
if run task4 "${HW1[@]}" top-pages "${R[@]}" -D hw1.k=3 -D hw1.langs=en,ja "$IN" "$WORK/t4"; then
    check_lines "task4: format lang<TAB>rank<TAB>title<TAB>views, k=3, langs en,ja" t4 \
        'NF != 4 || ($1 != "en" && $1 != "ja") || $2 !~ /^[1-3]$/ || $4 !~ /^[0-9]+$/ ||
         $3 == "-" || $3 == "Main_Page" || $3 ~ /^Special:/'
    # within a language: ranks 1..n in order, views not increasing, ties broken by title
    check_lines "task4: ranks contiguous, sorted, ties by title" t4 \
        '{ r[$1, $2] = $0; v[$1, $2] = $4; t[$1, $2] = $3; n[$1] = ($2 > n[$1] ? $2 : n[$1]) }
         END { for (l in n) for (i = 1; i <= n[l]; i++) {
                 if (!((l, i) in r)) { print l " rank " i " missing"; continue }
                 if (i > 1 && ((l, i - 1) in r) && (v[l, i] > v[l, i - 1] ||
                     (v[l, i] == v[l, i - 1] && t[l, i] < t[l, i - 1]))) print r[l, i] } }'
    extra=$(comm -13 <(echo "$before") <(ls "$WORK") | grep -v -x -e t4 -e task4.log)
    if [ -z "$extra" ]; then
        pass "task4: intermediate output deleted"
    else
        fail "task4: intermediate output left behind: $extra"
    fi
fi

if python3 - "$ROOT/report/counters.json" >"$WORK/counters.txt" 2>&1 <<'EOF'
import json, sys
need = {
    "task1-combiner": ["Launched map tasks", "Map input records", "Map output records", "Map output bytes",
                       "Combine input records", "Combine output records", "Reduce input records",
                       "Reduce shuffle bytes", "MALFORMED"],
    "task1-nocombiner": ["Launched map tasks", "Map output records", "Map output bytes",
                         "Combine input records", "Combine output records", "Reduce input records",
                         "Reduce shuffle bytes"],
    "task2": ["Launched map tasks", "Map output records", "Combine output records"],
    "task3": ["Map input records", "UNMATCHED_LANGUAGES", "LANGUAGES_WITHOUT_VIEWS"],
    "task4-job1": ["Map output records", "Combine output records"],
    "task4-job2": ["Launched map tasks", "Reduce output records"],
}
try:
    data = json.load(open(sys.argv[1], encoding="utf-8"))
except (OSError, ValueError) as e:
    sys.exit(f"cannot read: {e}")
errors = [f"{job}/{c} missing" for job, cs in need.items() for c in cs if c not in data.get(job, {})]
errors += [f"{job}/{c} is not a number or null" for job, cs in data.items() if isinstance(cs, dict)
           for c, v in cs.items() if v is not None and (not isinstance(v, int) or isinstance(v, bool) or v < 0)]
empty = sum(v is None for cs in data.values() if isinstance(cs, dict) for v in cs.values())
if errors:
    sys.exit("; ".join(errors[:5]))
if empty:
    print(f"note: {empty} counters still null; fill them in from your cluster runs before the deadline")
EOF
then
    pass "report/counters.json: valid"
    [ ! -s "$WORK/counters.txt" ] || report+=("      $(cat "$WORK/counters.txt")")
else
    fail "report/counters.json: $(cat "$WORK/counters.txt")"
fi

# Team table in README.md: 2-3 members, every cell filled and well-formed.
if python3 - "$ROOT/README.md" >"$WORK/team.txt" 2>&1 <<'EOF'
import re
import sys

team = started = False
rows = []
for line in open(sys.argv[1], encoding="utf-8"):
    s = line.strip()
    if s.startswith("## "):
        team = s == "## Team"
    elif team and s.startswith("|"):
        started = True
        rows.append([c.strip() for c in s.strip("|").split("|")])
    elif team and started:
        break
data = [r for r in rows[1:] if not re.fullmatch(r"[-:\s|]*", "".join(r))]  # rows[0] is the header


def id_ok(n):  # Israeli ID check digit
    t = sum(sum(divmod(int(d) * (1 + i % 2), 10)) for i, d in enumerate(n))
    return t % 10 == 0


problems, members = [], 0
for i, r in enumerate(data, 1):
    if not any(r):
        continue
    members += 1
    who = f"row {i}" + (f" ({r[0]})" if r[0] else "")
    if len(r) != 4 or not all(r):
        problems.append(f"{who}: need 4 filled cells: full name, ID number, email, GitHub username")
        continue
    _, uid, email, gh = r
    if not re.fullmatch(r"\d{9}", uid):
        problems.append(f"{who}: ID number must be exactly 9 digits (pad with leading zeros)")
    elif not id_ok(uid):
        problems.append(f"{who}: ID number fails the check digit; if your ID is correct, tell us on the course forum")
    if not re.fullmatch(r"[^@\s|]+@[^@\s|]+\.[^@\s|]+", email):
        problems.append(f"{who}: email is not of the form name@host.tld")
    if len(gh) > 39 or not re.fullmatch(r"[A-Za-z0-9](-?[A-Za-z0-9])*", gh):
        problems.append(f"{who}: GitHub username must be the bare name, no @ or URL")
if not 2 <= members <= 3:
    problems.append(f"need 2-3 members, found {members}")
if problems:
    sys.exit("\n".join(problems))
print(members)
EOF
then
    pass "README.md: Team table has $(cat "$WORK/team.txt") members"
else
    fail "README.md: Team table"
    while IFS= read -r l; do report+=("      $l"); done <"$WORK/team.txt"
fi

echo
printf '%s\n' "${report[@]}" | tee "$WORK/summary.txt"
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
    {
        echo '```'
        cat "$WORK/summary.txt"
        echo '```'
    } >>"$GITHUB_STEP_SUMMARY"
fi
echo
if [ "$fails" -gt 0 ]; then
    echo "$fails smoke check(s) failed. These checks only cover format and consistency on a tiny sample."
    exit 1
fi
echo "all smoke checks passed. These checks only cover format and consistency on a tiny sample, not correctness."
