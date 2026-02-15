# UNSW CSE Course Scraper Skill

## Description

Expert skill for scraping UNSW CSE course materials from public CGI sites and authenticated WebCMS3 system. Handles lecture slides, code, tutorials, labs, exams, and YouTube playlists with intelligent directory discovery and error handling.

## When to Use This Skill

Trigger this skill when user requests:
- "Scrape COMP{CODE} materials"
- "Download {course} lecture slides/code/tutorials"
- "Get UNSW CSE course resources for {term}"
- "Fetch {course} past exams/assignments"

## Prerequisites

**Required tools:**
- `curl` (HTTP client)
- `grep`, `sed` (text processing)
- `yt-dlp` (YouTube downloads) — install: `brew install yt-dlp` or `pip install yt-dlp`

**Optional:**
- Browser cookie exporter extension (for WebCMS3-only courses)
- Netscape-format `.txt` cookie file at `~/UNSW/cookies.txt`

## Quick Start Flow

When activated:

1. **Clarify requirements**:
   - Which course? (e.g., COMP2521)
   - Which term? (e.g., 26T1)

2. **Check availability**:
   - Public CGI site? → Scrape directly (no auth)
   - WebCMS3-only? → Request cookies from user

3. **Execute scraping**:
   - Discover slide directory path (varies by lecturer)
   - Download all available resources
   - Organize to standard structure: `~/UNSW/COMP{CODE}/`

4. **Report results**:
   - Files downloaded count
   - Any missing resources (404/403)

---

## Architecture Overview

### Two Independent Systems

#### CGI Sites — `cgi.cse.unsw.edu.au` (Public Access)

**URL Pattern**: `https://cgi.cse.unsw.edu.au/~cs{code}/{term}/`

**Characteristics**:
- Static Apache-served files
- No authentication for public resources
- Past terms preserved indefinitely
- Slide paths vary: `/lectures/slides/`, `/lectures/`, `/slides/`, `/Lectures/`, `/lecs/`

**Public Resources**:
- Lecture slides (PDF)
- Lecture code (.c, .h, .zip, Makefile)
- Code solutions
- Revision exercises (.zip)
- Tutorial/lab questions (HTML)
- Assignment specs (HTML)
- Past exams, sample exams (HTML)
- Practice exercises with solutions (HTML)
- Style guide, DSA manual (HTML)

**Protected Resources** (403):
- `/labs/` — lab submission system
- `/exams/` — current exam papers
- `/autotest/` — auto-testing system
- `/view/main.cgi` — CGI portal (zID/zPass, NOT WebCMS3 cookies)

#### WebCMS3 — `webcms3.cse.unsw.edu.au` (Authenticated)

**URL Pattern**: `https://webcms3.cse.unsw.edu.au/COMP{CODE}/{term}/`

**Characteristics**:
- Flask/gunicorn-based
- Requires browser cookies
- Only current term exists (past terms deleted)

**Required Cookies** (Netscape format):
- `remember_token` — persistent login, ~1 year lifespan
- `session` — Flask session, expires on browser close

**Export via**: "Cookie Editor" or "Get cookies.txt LOCALLY" browser extension

**Access Levels**:
- Any authenticated user: homepage, announcements, staff
- Enrolled students only: resources, grades, forum (403 otherwise)

---

## Course Availability (Verified Feb 2026)

### Public CGI Courses (No Auth Required)

| Course | Name | Terms | Slide Path |
|--------|------|-------|------------|
| COMP1511 | Programming Fundamentals | 26T1, 25T3, 25T1 | varies |
| COMP1521 | Computer Systems Fundamentals | 26T1, 25T3, 25T1 | varies |
| COMP2041 | Software Construction | 26T1, 25T1 | varies |
| COMP2521 | Data Structures and Algorithms | 26T1, 25T3, 25T1 | `/lectures/slides/` |
| COMP3131 | Programming Languages and Compilers | 26T1, 25T1 | `/Lectures/` |
| COMP3161 | Concepts of Programming Languages | 25T3 | varies |
| COMP3222 | Digital Circuits and Systems | 26T1, 25T1 | `/slides/` |
| COMP3311 | Database Systems | 26T1, 25T1 | `/lectures/` |
| COMP3411 | Artificial Intelligence | 26T1, 25T1 | varies |
| COMP3891 | Ext Operating Systems | 26T1, 25T3, 25T1 | (redirect) |
| COMP4337 | Securing Fixed and Wireless Networks | 25T1 | varies |
| COMP6080 | Web Front-End Programming | 26T1, 25T3, 25T1 | `/lectures/slides/` |
| COMP9020 | Foundations of Computer Science | 25T3 | varies |
| COMP9024 | Data Structures and Algorithms (PG) | 26T1, 25T3, 25T1 | varies |
| COMP9242 | Advanced Operating Systems | 25T3 | varies |
| COMP9311 | Database Systems (PG) | 26T1, 25T3, 25T1 | varies |
| COMP9315 | DBMS Implementation | 26T1, 25T1 | `/lectures/` |
| COMP9334 | Capacity Planning | 25T1 | varies |

### WebCMS3-Only Courses (Enrollment Required)

COMP1531, COMP2121, COMP2511, COMP3141, COMP3153, COMP3211, COMP3231,
COMP3331, COMP3421, COMP3900, COMP4336, COMP4511, COMP6443, COMP6451,
COMP6452, COMP9319, COMP9417, COMP9444, COMP9517

---

## Step-by-Step Procedures

### Step 1: Discover Slide Directory

Slide paths vary by lecturer. Test common patterns:

```bash
COURSE=cs2521
TERM=26T1
BASE="https://cgi.cse.unsw.edu.au/~${COURSE}/${TERM}"

for path in lectures/slides/ lectures/ slides/ Lectures/ lecs/; do
  code=$(curl -s -o /dev/null -w "%{http_code}" "${BASE}/${path}")
  if [ "$code" = "200" ]; then
    count=$(curl -s "${BASE}/${path}" | grep -oi 'href="[^"]*\.pdf"' | wc -l)
    if [ "$count" -gt 0 ]; then
      echo "FOUND: ${path} (${count} PDFs)"
      break
    fi
  fi
done
```

### Step 2: Download All Lecture Slides

```bash
SLIDE_PATH="lectures/slides/"  # from Step 1
SAVE_DIR=~/UNSW/COMP2521/lectures/slides
mkdir -p "$SAVE_DIR"

curl -s "${BASE}/${SLIDE_PATH}" \
  | grep -o 'href="[^"]*\.pdf"' | sed 's/href="//;s/"$//' \
  | while read f; do
      echo "Downloading: $f"
      curl -s -o "${SAVE_DIR}/$f" "${BASE}/${SLIDE_PATH}$f"
    done
```

### Step 3: Download Lecture Code

```bash
SAVE_DIR=~/UNSW/COMP2521/lectures/code
mkdir -p "$SAVE_DIR"

curl -s "${BASE}/lectures/code/" \
  | grep -o 'href="[^"]*/"' | sed 's/href="//;s/\/"$//' \
  | grep -v '^\.\|^\?' \
  | while read dir; do
      mkdir -p "${SAVE_DIR}/${dir}"
      curl -s -f -o "${SAVE_DIR}/${dir}/all.zip" \
        "${BASE}/lectures/code/${dir}/all.zip" 2>/dev/null && \
        echo "Downloaded: ${dir}/all.zip"
    done
```

### Step 4: Download Tutorials and Labs

```bash
SAVE_DIR=~/UNSW/COMP2521
mkdir -p "${SAVE_DIR}/tutorials" "${SAVE_DIR}/labs"

# Tutorials (week numbers vary by course)
for i in 1 2 3 4 5 7 8 9 10; do
  curl -s -f "${BASE}/tut/${i}/questions" -o "${SAVE_DIR}/tutorials/tut${i}.html" 2>/dev/null
done

# Labs
for i in 1 2 3 4 5 7 8 9 11 12 13 14 15 16 17; do
  curl -s -f "${BASE}/lab/${i}/questions" -o "${SAVE_DIR}/labs/lab${i}.html" 2>/dev/null
done
```

### Step 5: Download Exams and Guides

```bash
SAVE_DIR=~/UNSW/COMP2521
mkdir -p "${SAVE_DIR}/exams" "${SAVE_DIR}/guides"

curl -s -f "${BASE}/sample-exam" -o "${SAVE_DIR}/exams/sample-exam.html"
curl -s -f "${BASE}/style-guide" -o "${SAVE_DIR}/guides/style-guide.html"
curl -s -f "${BASE}/dsa-manual" -o "${SAVE_DIR}/guides/dsa-manual.html"

# Past exams (terms back to 2021T2)
for t in 21T2 21T3 22T1 22T2 22T3 23T1 23T2 23T3 24T1 24T3 25T1 25T3; do
  curl -s -f "${BASE}/past-exam/${t}" -o "${SAVE_DIR}/exams/past-${t}.html" 2>/dev/null
done
```

### Step 6: Download YouTube Lecture Playlists

**Requires**: `yt-dlp` (`brew install yt-dlp` or `pip install yt-dlp`)

```bash
# List videos without downloading (preview)
yt-dlp --flat-playlist \
  --print "%(playlist_index)s. %(title)s (%(duration_string)s)" \
  "PLAYLIST_URL"

# Download full playlist (1080p video + subtitles)
yt-dlp \
  -o '~/UNSW/COMP2521/lectures/videos/%(playlist_index)s-%(title)s.%(ext)s' \
  --format 'bestvideo[height<=1080]+bestaudio/best' \
  --write-subs --sub-langs en \
  --no-overwrites \
  "PLAYLIST_URL"

# Audio-only (for commute listening)
yt-dlp \
  -o '~/UNSW/COMP2521/lectures/audio/%(playlist_index)s-%(title)s.%(ext)s' \
  --extract-audio --audio-format mp3 --audio-quality 128K \
  "PLAYLIST_URL"
```

### Step 7: WebCMS3 Scraping (Authenticated)

**Requires**: Cookie file at `~/UNSW/cookies.txt` (Netscape format)

```bash
COOKIES=~/UNSW/cookies.txt

# Fetch course homepage
curl -s -b "$COOKIES" -L "https://webcms3.cse.unsw.edu.au/COMP2521/26T1/"

# Extract all resource IDs
curl -s -b "$COOKIES" -L "https://webcms3.cse.unsw.edu.au/COMP2521/26T1/" \
  | grep -o '/resources/[0-9]*' | sort -u

# Fetch specific resource by ID
curl -s -b "$COOKIES" -L "https://webcms3.cse.unsw.edu.au/COMP2521/26T1/resources/{ID}"

# Extract all YouTube links from course page
curl -s -b "$COOKIES" -L "https://webcms3.cse.unsw.edu.au/COMP2521/26T1/" \
  | grep -o 'https://[^"]*youtube[^"]*' | sed 's/&amp;/\&/g' | sort -u
```

---

## Output Directory Structure

Standard organization for all downloads:

```
~/UNSW/COMP{CODE}/
├── lectures/
│   ├── slides/              # PDF lecture slides
│   ├── code/                # Source code per week
│   │   ├── wk1-topic/
│   │   │   ├── all.zip
│   │   │   ├── solution/
│   │   │   └── starter/
│   │   └── ...
│   ├── revision/            # Revision exercise zips
│   ├── videos/              # YouTube recordings (via yt-dlp)
│   ├── audio/               # Audio-only lecture recordings
│   └── youtube-links.txt    # All YouTube URLs extracted
├── tutorials/               # Tutorial question pages (HTML)
├── labs/                    # Lab question pages (HTML)
├── assignments/             # Assignment specifications (HTML)
├── exams/                   # Past exams + sample exam (HTML)
├── guides/                  # Style guide, DSA manual, etc.
└── webcms-pages/            # Raw WebCMS3 pages (HTML)
```

---

## Troubleshooting Guide

| Problem | Cause | Solution |
|---------|-------|----------|
| 403 Forbidden on CGI | Behind CGI portal auth | Not accessible via cookies; requires zID/zPass login |
| 404 Not Found on WebCMS3 | Past term deleted | Only current term exists; use CGI site for archives |
| Can't find slides | Wrong directory path | Try all paths: `lectures/slides/`, `lectures/`, `slides/`, `Lectures/` |
| Empty directory | Term just started | Try previous term (e.g., 25T3 instead of 26T1) |
| yt-dlp download fails | Video unlisted/private | Add `--cookies-from-browser chrome` flag |
| Cookie expired | Token lifetime exceeded | Re-export cookies (`remember_token` ~1yr, `session` = browser session) |
| CGI site doesn't exist | WebCMS3-only course | Check "WebCMS3-Only" list; requires enrollment cookies |
| PDF file <1KB | Error page saved as PDF | Check HTTP status; likely 404/403 response |
| Code zip missing | Week directory doesn't exist | Not all weeks have code; skip gracefully |
| Tutorial/lab 404 | Numbering varies by course | Adjust loop range based on actual week numbers |

---

## Best Practices

1. **Verify course availability** before scraping (check public vs. WebCMS3-only lists)
2. **Test slide paths systematically** (lecturers use different structures)
3. **Maintain standard directory structure** across all courses for consistency
4. **Handle errors gracefully** (suppress stderr, continue on 404/403)
5. **Preserve original filenames** (don't rename downloaded files)
6. **Validate downloads** (PDFs <1KB are likely error pages)
7. **Use `--no-overwrites`** for yt-dlp to avoid re-downloading
8. **Log download progress** (echo status for user visibility)
9. **Batch similar operations** (loops for tutorials/labs/exams)
10. **Secure cookie storage** (`chmod 600 ~/UNSW/cookies.txt`)

---

## Example Interactions

### Example 1: Public CGI Course

**User**: "Scrape COMP2521 26T1 slides"

**Gemini Workflow**:
1. ✓ Check: COMP2521 in public CGI list
2. ✓ Discover slide path: `/lectures/slides/` (37 PDFs)
3. ✓ Download all slides to `~/UNSW/COMP2521/lectures/slides/`
4. ✓ Report: "Downloaded 37 lecture slides for COMP2521 26T1"

### Example 2: WebCMS3-Only Course

**User**: "Get COMP1531 26T1 resources"

**Gemini Workflow**:
1. ✓ Check: COMP1531 is WebCMS3-only
2. ⚠ Request cookies: "COMP1531 requires authentication. Export cookies to `~/UNSW/cookies.txt` (Netscape format) using 'Cookie Editor' extension."
3. ⏸ Wait for user to provide cookies
4. ✓ Proceed with WebCMS3 scraping

### Example 3: Complete Course Download

**User**: "Download everything for COMP2521 26T1"

**Gemini Workflow**:
1. ✓ Discover slide path and download slides
2. ✓ Download lecture code (all weeks)
3. ✓ Download tutorials (tut1-10)
4. ✓ Download labs (lab1-17)
5. ✓ Download exams (sample + past terms)
6. ✓ Download guides (style guide, DSA manual)
7. ✓ Extract YouTube links from course page
8. ✓ Report: "Complete download: 37 slides, 12 code zips, 10 tutorials, 17 labs, 14 exams, 2 guides"

---

## Implementation Notes

- All `curl` commands use `-s` (silent) and `-f` (fail fast) flags
- Grep patterns use case-insensitive matching (`-oi`) for robustness
- Loops suppress stderr (`2>/dev/null`) to avoid cluttering output
- Directory creation uses `-p` flag (no error if exists)
- YouTube downloads default to 1080p max (balance quality/size)
- Cookie files must be Netscape format (NOT JSON)
- Preserve HTTP headers for debugging: add `-i` flag to curl

---

## Advanced Features

### Bulk Course Download

Download multiple courses in sequence:

```bash
for course in cs2521 cs3311 cs6080; do
  TERM=26T1
  BASE="https://cgi.cse.unsw.edu.au/~${course}/${TERM}"
  echo "=== Processing ${course^^} ==="
  # Run scraping procedures here
done
```

### Incremental Updates

Download only new files since last scrape:

```bash
# Use conditional GET with timestamp
curl -s -z ~/UNSW/COMP2521/lectures/slides/week1.pdf \
  -o ~/UNSW/COMP2521/lectures/slides/week1.pdf \
  "${BASE}/lectures/slides/week1.pdf"
```

### Parallel Downloads

Speed up large downloads using GNU parallel:

```bash
# Download all PDFs in parallel (max 4 concurrent)
grep -o 'href="[^"]*\.pdf"' index.html \
  | sed 's/href="//;s/"$//' \
  | parallel -j 4 curl -s -o '{/.}' "${BASE}/{}"
```

---

## Security Considerations

1. **Cookie protection**: Store cookies with restricted permissions (`chmod 600`)
2. **HTTPS only**: All URLs use HTTPS (HTTP auto-upgraded)
3. **No credential logging**: Never log cookie values or passwords
4. **Validate inputs**: Sanitize course codes and terms to prevent injection
5. **Respect robots.txt**: Check `/robots.txt` before aggressive scraping
6. **Rate limiting**: Add delays between requests if downloading hundreds of files

---

## Maintenance

**Update course availability**: Verify public CGI course list each term (February, June, September)

**Test procedures**: Validate scraping scripts at term start (weeks 1-2)

**Monitor changes**:
- CGI site directory structures may change with new lecturers
- WebCMS3 may update cookie/session handling
- YouTube playlists may become private/unlisted

**Version info**: Last updated February 2026
