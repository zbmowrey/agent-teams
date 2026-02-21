#!/usr/bin/env bash
# Aggregate cost summary data from all session cost files.
#
# Parses docs/progress/*cost-summary.md files to produce:
#   - Total session count
#   - Sessions by skill (plan-product, build-product, review-quality)
#   - Agent model mix (Opus vs Sonnet counts across all sessions)
#   - Session timeline
#
# Usage: cost-report.sh [repo_root]
#   repo_root defaults to the parent of the directory containing this script.
#
# Compatible with bash 3.x (macOS default).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${1:-$(cd "$SCRIPT_DIR/.." && pwd)}"
PROGRESS_DIR="$REPO_ROOT/docs/progress"

if [ ! -d "$PROGRESS_DIR" ]; then
    echo "No progress directory found at $PROGRESS_DIR"
    exit 0
fi

# Find all cost summary files
cost_files=()
while IFS= read -r -d '' f; do
    cost_files+=("$f")
done < <(find "$PROGRESS_DIR" -name "*cost-summary*" -print0 2>/dev/null | sort -z)

if [ "${#cost_files[@]}" -eq 0 ]; then
    echo "No cost summary files found."
    exit 0
fi

total_sessions=${#cost_files[@]}
total_opus=0
total_sonnet=0

# Per-skill counters (bash 3.x compatible — no associative arrays)
pp_count=0; pp_opus=0; pp_sonnet=0
bp_count=0; bp_opus=0; bp_sonnet=0
rq_count=0; rq_opus=0; rq_sonnet=0
unk_count=0; unk_opus=0; unk_sonnet=0

# Collect dates and session details into temp files for sorting
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
: > "$tmpdir/dates.txt"
: > "$tmpdir/sessions.txt"

n=0
for filepath in "${cost_files[@]}"; do
    n=$((n + 1))
    filename="$(basename "$filepath")"

    # Extract skill from filename
    skill=""
    if [[ "$filename" == plan-product-* ]]; then
        skill="plan-product"
    elif [[ "$filename" == build-product-* ]]; then
        skill="build-product"
    elif [[ "$filename" == review-quality-* ]]; then
        skill="review-quality"
    else
        skill="unknown"
    fi

    # Extract date from filename
    file_date=""
    if [[ "$filename" =~ ([0-9]{4}-[0-9]{2}-[0-9]{2}) ]]; then
        file_date="${BASH_REMATCH[1]}"
        echo "$file_date" >> "$tmpdir/dates.txt"
    fi

    # Count Opus and Sonnet agents from table rows
    file_opus=0
    file_sonnet=0
    while IFS= read -r line; do
        if printf '%s' "$line" | grep -iq '|[[:space:]]*opus[[:space:]]*|'; then
            file_opus=$((file_opus + 1))
        fi
        if printf '%s' "$line" | grep -iq '|[[:space:]]*sonnet[[:space:]]*|'; then
            file_sonnet=$((file_sonnet + 1))
        fi
    done < "$filepath"

    total_opus=$((total_opus + file_opus))
    total_sonnet=$((total_sonnet + file_sonnet))

    case "$skill" in
        plan-product)  pp_count=$((pp_count+1)); pp_opus=$((pp_opus+file_opus)); pp_sonnet=$((pp_sonnet+file_sonnet)) ;;
        build-product) bp_count=$((bp_count+1)); bp_opus=$((bp_opus+file_opus)); bp_sonnet=$((bp_sonnet+file_sonnet)) ;;
        review-quality) rq_count=$((rq_count+1)); rq_opus=$((rq_opus+file_opus)); rq_sonnet=$((rq_sonnet+file_sonnet)) ;;
        *) unk_count=$((unk_count+1)); unk_opus=$((unk_opus+file_opus)); unk_sonnet=$((unk_sonnet+file_sonnet)) ;;
    esac

    echo "$n|$filename|$skill|$file_date" >> "$tmpdir/sessions.txt"
done

# Output report
echo "# Cost Report"
echo ""
echo "## Summary"
echo ""
echo "| Metric | Value |"
echo "|--------|-------|"
echo "| Total sessions | $total_sessions |"
echo "| Total agent spawns (Opus) | $total_opus |"
echo "| Total agent spawns (Sonnet) | $total_sonnet |"
echo "| Total agent spawns (all) | $((total_opus + total_sonnet)) |"
if [ $((total_opus + total_sonnet)) -gt 0 ]; then
    pct=$(( (total_opus * 100) / (total_opus + total_sonnet) ))
    echo "| Opus % of total | ${pct}% |"
fi
echo ""

echo "## Sessions by Skill"
echo ""
echo "| Skill | Sessions | Opus Agents | Sonnet Agents | Total Agents |"
echo "|-------|----------|-------------|---------------|--------------|"
if [ "$pp_count" -gt 0 ]; then
    echo "| plan-product | $pp_count | $pp_opus | $pp_sonnet | $((pp_opus + pp_sonnet)) |"
fi
if [ "$bp_count" -gt 0 ]; then
    echo "| build-product | $bp_count | $bp_opus | $bp_sonnet | $((bp_opus + bp_sonnet)) |"
fi
if [ "$rq_count" -gt 0 ]; then
    echo "| review-quality | $rq_count | $rq_opus | $rq_sonnet | $((rq_opus + rq_sonnet)) |"
fi
if [ "$unk_count" -gt 0 ]; then
    echo "| unknown | $unk_count | $unk_opus | $unk_sonnet | $((unk_opus + unk_sonnet)) |"
fi
echo ""

echo "## Sessions by Date"
echo ""
echo "| Date | Sessions |"
echo "|------|----------|"
sort "$tmpdir/dates.txt" | uniq -c | sort -k2 | while read -r count date; do
    echo "| $date | $count |"
done
echo ""

echo "## Session List"
echo ""
echo "| # | File | Skill | Date |"
echo "|---|------|-------|------|"
while IFS='|' read -r num file skill date; do
    echo "| $num | $file | $skill | $date |"
done < "$tmpdir/sessions.txt"
