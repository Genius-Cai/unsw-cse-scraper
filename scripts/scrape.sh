#!/bin/bash
# UNSW CSE Course Scraper
# Usage: ./scrape.sh <course> <term> [save_dir]
# Example: ./scrape.sh cs2521 26T1 ~/UNSW/COMP2521

set -euo pipefail

COURSE="${1:?Usage: $0 <course> <term> [save_dir]}"
TERM="${2:?Usage: $0 <course> <term> [save_dir]}"
CODE=$(echo "$COURSE" | sed 's/cs/COMP/')
SAVE_DIR="${3:-$HOME/UNSW/${CODE}}"
BASE="https://cgi.cse.unsw.edu.au/~${COURSE}/${TERM}"

echo "=== UNSW CSE Scraper ==="
echo "Course: ${CODE} (${TERM})"
echo "CGI Base: ${BASE}"
echo "Save to: ${SAVE_DIR}"
echo ""

# Check if site exists
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "${BASE}/")
if [ "$HTTP_CODE" != "200" ]; then
    echo "ERROR: ${BASE}/ returned HTTP ${HTTP_CODE}"
    echo "This course may not have a CGI site, or the term doesn't exist."
    exit 1
fi
echo "[OK] Site exists"

# --- Discover and download slides ---
echo ""
echo "=== Lecture Slides ==="
SLIDE_PATH=""
for path in lectures/slides/ lectures/ slides/ Lectures/ lecs/; do
    code=$(curl -s -o /dev/null -w "%{http_code}" "${BASE}/${path}")
    if [ "$code" = "200" ]; then
        count=$(curl -s "${BASE}/${path}" | grep -oi 'href="[^"]*\.pdf"' | wc -l | tr -d ' ')
        if [ "$count" -gt 0 ]; then
            SLIDE_PATH="$path"
            echo "Found ${count} PDFs at /${path}"
            break
        fi
    fi
done

if [ -n "$SLIDE_PATH" ]; then
    mkdir -p "${SAVE_DIR}/lectures/slides"
    curl -s "${BASE}/${SLIDE_PATH}" \
      | grep -o 'href="[^"]*\.pdf"' | sed 's/href="//;s/"$//' \
      | while read -r f; do
          if [ ! -f "${SAVE_DIR}/lectures/slides/$f" ]; then
              echo "  Downloading: $f"
              curl -s -o "${SAVE_DIR}/lectures/slides/$f" "${BASE}/${SLIDE_PATH}$f"
          else
              echo "  Skip (exists): $f"
          fi
        done
else
    echo "No slide directory found"
fi

# --- Download lecture code ---
echo ""
echo "=== Lecture Code ==="
CODE_URL="${BASE}/lectures/code/"
code=$(curl -s -o /dev/null -w "%{http_code}" "$CODE_URL")
if [ "$code" = "200" ]; then
    mkdir -p "${SAVE_DIR}/lectures/code"
    curl -s "$CODE_URL" \
      | grep -o 'href="[^"]*/"' | sed 's/href="//;s/\/"$//' \
      | grep -v '^\.\|^\?' \
      | while read -r dir; do
          mkdir -p "${SAVE_DIR}/lectures/code/${dir}"
          if curl -s -f -o "${SAVE_DIR}/lectures/code/${dir}/all.zip" \
              "${CODE_URL}${dir}/all.zip" 2>/dev/null; then
              echo "  Downloaded: ${dir}/all.zip"
          fi
        done
else
    echo "No lecture code directory"
fi

# --- Download tutorials ---
echo ""
echo "=== Tutorials ==="
mkdir -p "${SAVE_DIR}/tutorials"
for i in 1 2 3 4 5 6 7 8 9 10; do
    if curl -s -f "${BASE}/tut/${i}/questions" -o "${SAVE_DIR}/tutorials/tut${i}.html" 2>/dev/null; then
        size=$(wc -c < "${SAVE_DIR}/tutorials/tut${i}.html" | tr -d ' ')
        [ "$size" -gt 500 ] && echo "  tut${i}: ${size} bytes" || rm -f "${SAVE_DIR}/tutorials/tut${i}.html"
    fi
done

# --- Download labs ---
echo ""
echo "=== Labs ==="
mkdir -p "${SAVE_DIR}/labs"
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17; do
    if curl -s -f "${BASE}/lab/${i}/questions" -o "${SAVE_DIR}/labs/lab${i}.html" 2>/dev/null; then
        size=$(wc -c < "${SAVE_DIR}/labs/lab${i}.html" | tr -d ' ')
        [ "$size" -gt 500 ] && echo "  lab${i}: ${size} bytes" || rm -f "${SAVE_DIR}/labs/lab${i}.html"
    fi
done

# --- Download exams ---
echo ""
echo "=== Exams ==="
mkdir -p "${SAVE_DIR}/exams"
curl -s -f "${BASE}/sample-exam" -o "${SAVE_DIR}/exams/sample-exam.html" 2>/dev/null && echo "  sample-exam: OK"
for t in 21T2 21T3 22T1 22T2 22T3 23T1 23T2 23T3 24T1 24T3 25T1 25T3; do
    if curl -s -f "${BASE}/past-exam/${t}" -o "${SAVE_DIR}/exams/past-${t}.html" 2>/dev/null; then
        size=$(wc -c < "${SAVE_DIR}/exams/past-${t}.html" | tr -d ' ')
        [ "$size" -gt 500 ] && echo "  past-${t}: ${size} bytes" || rm -f "${SAVE_DIR}/exams/past-${t}.html"
    fi
done

# --- Download guides ---
echo ""
echo "=== Guides ==="
mkdir -p "${SAVE_DIR}/guides"
for page in style-guide dsa-manual; do
    if curl -s -f "${BASE}/${page}" -o "${SAVE_DIR}/guides/${page}.html" 2>/dev/null; then
        size=$(wc -c < "${SAVE_DIR}/guides/${page}.html" | tr -d ' ')
        [ "$size" -gt 500 ] && echo "  ${page}: ${size} bytes" || rm -f "${SAVE_DIR}/guides/${page}.html"
    fi
done

# --- Practice exercises ---
PRACTICE_URL="https://cgi.cse.unsw.edu.au/~${COURSE}/practice-exercises/"
code=$(curl -s -o /dev/null -w "%{http_code}" "$PRACTICE_URL")
if [ "$code" = "200" ]; then
    curl -s -f "$PRACTICE_URL" -o "${SAVE_DIR}/guides/practice-exercises.html" 2>/dev/null && echo "  practice-exercises: OK"
fi

# --- Summary ---
echo ""
echo "=== Done ==="
echo "Saved to: ${SAVE_DIR}"
du -sh "${SAVE_DIR}" 2>/dev/null
echo ""
echo "Directory structure:"
find "${SAVE_DIR}" -type f | head -30
TOTAL=$(find "${SAVE_DIR}" -type f | wc -l | tr -d ' ')
echo "... Total: ${TOTAL} files"
