# UNSW CSE Course Scraper — Codex Agent

## Purpose

Scrape UNSW CSE course materials from two independent systems:
1. **CGI sites** (`cgi.cse.unsw.edu.au`) — public, no auth required
2. **WebCMS3** (`webcms3.cse.unsw.edu.au`) — requires browser cookies for enrolled students

## Capabilities

- Discover and download lecture slides (PDF) from CGI sites
- Download lecture code, tutorials, labs, assignments, exams, and guides
- Scrape WebCMS3 resources with user-provided cookies
- Download YouTube lecture playlists using `yt-dlp`
- Handle varying directory structures across different courses and lecturers
- Organize downloads into standardized directory structure

## Tools Required

- `curl` — HTTP requests and file downloads
- `grep`, `sed` — HTML parsing and text extraction
- `yt-dlp` — YouTube playlist downloads (install: `brew install yt-dlp` or `pip install yt-dlp`)
- Browser cookie exporter (e.g., "Cookie Editor" extension) for WebCMS3 access

## Workflow

When user requests CSE course scraping:

1. **Clarify requirements**:
   - Which course? (e.g., COMP2521)
   - Which term? (e.g., 26T1)

2. **Determine scraping method**:
   - Check "Public CGI Courses" list below
   - If public: scrape directly from CGI site
   - If not: request WebCMS3 cookies (Netscape `.txt` format)

3. **Execute scraping procedures**:
   - Discover slide directory path (varies by lecturer)
   - Download all resources following standard structure
   - Handle errors gracefully (missing directories, 403/404 responses)

4. **Organize output** to standard directory structure

---

## Two Independent Systems

### System 1: CGI Sites (Public)

**URL Pattern**: `https://cgi.cse.unsw.edu.au/~cs{code}/{term}/`

**Example**: `https://cgi.cse.unsw.edu.au/~cs2521/26T1/`

**Characteristics**:
- Static Apache-served files
- No authentication required for public resources
- Past terms preserved indefinitely
- Slide paths vary by lecturer: `/lectures/slides/`, `/lectures/`, `/slides/`, `/Lectures/`, `/lecs/`

**Public Resources**:
- Lecture slides: PDF files
- Lecture code: `.c`, `.h`, `.zip`, `Makefile` files per week
- Code solutions: `/lectures/code/{week}/solution/`
- Revision exercises: `.zip` archives
- Tutorial questions: `/tut/{1-10}/questions` (HTML)
- Lab questions: `/lab/{1-17}/questions` (HTML)
- Assignment specs: `/assignments/ass{1-2}/` (HTML)
- Past exams: `/past-exam/{term}` (HTML)
- Sample exam: `/sample-exam` (HTML)
- Practice exercises: `/practice-exercises/` (HTML, with solutions)
- Style guide: `/style-guide` (HTML)
- DSA manual: `/dsa-manual` (HTML)

**Protected Resources** (403 — separate auth):
- `/labs/` — lab submission system
- `/exams/` — current term exam papers
- `/autotest/` — automated testing
- `/view/main.cgi` — CGI portal (uses zID/zPass, NOT WebCMS3 cookies)

### System 2: WebCMS3 (Authenticated)

**URL Pattern**: `https://webcms3.cse.unsw.edu.au/COMP{CODE}/{term}/`

**Example**: `https://webcms3.cse.unsw.edu.au/COMP2521/26T1/`

**Characteristics**:
- Flask/gunicorn-based system
- Requires browser cookies for access
- Only current term data exists (past terms deleted)

**Required Cookies** (Netscape format):
- `remember_token` — persistent login (`{zID_number}|{hash}`), ~1 year lifespan
- `session` — Flask signed session, expires on browser close

**Export Method**: Use browser extension like "Cookie Editor" or "Get cookies.txt LOCALLY"

**Access Levels**:
- Any authenticated user: homepage, announcements, staff names, sidebar
- Enrolled students only: resources, grades, analytics, forum (403 otherwise)

**Key Endpoints**:
- `/COMP{code}/{term}/` — course homepage
- `/COMP{code}/{term}/resources/{id}` — individual resource (sequential integer IDs)
- `/COMP{code}/{term}/notices` — announcements
- `/users/{zID}` — user profile
- `/search` — course search (all terms back to 2014)
- `/messages/` — JSON API endpoint

---

## Public CGI Courses (Verified February 2026)

### Available (No Authentication)

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

### NOT Available (WebCMS3 Only)

Requires enrollment cookies:
COMP1531, COMP2121, COMP2511, COMP3141, COMP3153, COMP3211, COMP3231,
COMP3331, COMP3421, COMP3900, COMP4336, COMP4511, COMP6443, COMP6451,
COMP6452, COMP9319, COMP9417, COMP9444, COMP9517

---

## Scraping Procedures

### Procedure 1: Discover Slide Directory

Slide paths vary by lecturer. Test common paths in order:

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

### Procedure 2: Download All Lecture Slides

```bash
SLIDE_PATH="lectures/slides/"  # from Procedure 1
SAVE_DIR=~/UNSW/COMP2521/lectures/slides
mkdir -p "$SAVE_DIR"

curl -s "${BASE}/${SLIDE_PATH}" \
  | grep -o 'href="[^"]*\.pdf"' | sed 's/href="//;s/"$//' \
  | while read f; do
      echo "Downloading: $f"
      curl -s -o "${SAVE_DIR}/$f" "${BASE}/${SLIDE_PATH}$f"
    done
```

### Procedure 3: Download Lecture Code

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

### Procedure 4: Download Tutorials and Labs

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

### Procedure 5: Download Exams and Guides

```bash
SAVE_DIR=~/UNSW/COMP2521
mkdir -p "${SAVE_DIR}/exams" "${SAVE_DIR}/guides"

curl -s -f "${BASE}/sample-exam" -o "${SAVE_DIR}/exams/sample-exam.html"
curl -s -f "${BASE}/style-guide" -o "${SAVE_DIR}/guides/style-guide.html"
curl -s -f "${BASE}/dsa-manual" -o "${SAVE_DIR}/guides/dsa-manual.html"

# Past exams
for t in 21T2 21T3 22T1 22T2 22T3 23T1 23T2 23T3 24T1 24T3 25T1 25T3; do
  curl -s -f "${BASE}/past-exam/${t}" -o "${SAVE_DIR}/exams/past-${t}.html" 2>/dev/null
done
```

### Procedure 6: Download YouTube Lectures

Requires `yt-dlp` (`brew install yt-dlp` or `pip install yt-dlp`):

```bash
# List videos in a playlist (no download)
yt-dlp --flat-playlist \
  --print "%(playlist_index)s. %(title)s (%(duration_string)s)" \
  "PLAYLIST_URL"

# Download full playlist (1080p video)
yt-dlp \
  -o '~/UNSW/COMP2521/lectures/videos/%(playlist_index)s-%(title)s.%(ext)s' \
  --format 'bestvideo[height<=1080]+bestaudio/best' \
  --write-subs --sub-langs en \
  --no-overwrites \
  "PLAYLIST_URL"

# Audio only (for commute listening)
yt-dlp \
  -o '~/UNSW/COMP2521/lectures/audio/%(playlist_index)s-%(title)s.%(ext)s' \
  --extract-audio --audio-format mp3 --audio-quality 128K \
  "PLAYLIST_URL"
```

### Procedure 7: WebCMS3 Scraping (Requires Cookies)

```bash
COOKIES=~/UNSW/cookies.txt  # Netscape format

# Fetch course page
curl -s -b "$COOKIES" -L "https://webcms3.cse.unsw.edu.au/COMP2521/26T1/"

# Extract resource IDs
curl -s -b "$COOKIES" -L "https://webcms3.cse.unsw.edu.au/COMP2521/26T1/" \
  | grep -o '/resources/[0-9]*' | sort -u

# Fetch specific resource
curl -s -b "$COOKIES" -L "https://webcms3.cse.unsw.edu.au/COMP2521/26T1/resources/{ID}"

# Extract YouTube links from lectures page
curl -s -b "$COOKIES" -L "https://webcms3.cse.unsw.edu.au/COMP2521/26T1/" \
  | grep -o 'https://[^"]*youtube[^"]*' | sed 's/&amp;/\&/g' | sort -u
```

---

## Output Directory Structure

Standard organization for all downloaded materials:

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
│   ├── audio/               # Audio-only versions
│   └── youtube-links.txt    # All YouTube URLs
├── tutorials/               # Tutorial question pages (HTML)
├── labs/                    # Lab question pages (HTML)
├── assignments/             # Assignment specs (HTML)
├── exams/                   # Past exams + sample exam (HTML)
├── guides/                  # Style guide, manuals
└── webcms-pages/            # Raw WebCMS3 pages (HTML)
```

---

## Troubleshooting

| Problem | Diagnosis | Solution |
|---------|-----------|----------|
| 403 on CGI resource | Behind CGI portal auth | Not accessible via WebCMS3 cookies; requires zID/zPass |
| 404 on WebCMS3 | Past term deleted | WebCMS3 only retains current term; use CGI site instead |
| Can't find slides | Wrong directory path | Try all paths: `lectures/slides/`, `lectures/`, `slides/`, `Lectures/` |
| Empty directory | Term just started | Try previous term (e.g., 25T3 instead of 26T1) |
| yt-dlp fails | Video unlisted/private | Try `--cookies-from-browser chrome` flag |
| Cookie expired | Token lifetime exceeded | `remember_token` ~1 year, `session` = browser session. Re-export. |
| CGI site doesn't exist | Course WebCMS3-only | Check "NOT Available" list; needs enrollment cookies |
| PDF file <1KB | Error page downloaded | Check HTTP response; likely 404/403 saved as PDF |

---

## Best Practices

1. **Check course availability first** — verify against public course list before attempting scrape
2. **Respect slide path variations** — lecturers use different directory structures; test systematically
3. **Use standard directory structure** — maintain consistent organization across all courses
4. **Handle errors gracefully** — some resources may not exist for all courses/terms; suppress errors, continue
5. **Preserve original filenames** — don't rename downloaded files; keep original structure
6. **Validate downloads** — check file sizes; PDFs <1KB are likely error pages
7. **Batch processing** — use loops for tutorials/labs/exams with consistent numbering
8. **Cookie management** — store cookies securely; remind user to refresh when expired
9. **Avoid redundant downloads** — use `--no-overwrites` for yt-dlp; check file existence before curl
10. **Log progress** — echo download status for user visibility

---

## Example Usage

**User request**: "Scrape COMP2521 26T1 slides"

**Agent response**:
1. Check: COMP2521 is in public CGI list ✓
2. Discover slide path: `/lectures/slides/` (37 PDFs found)
3. Download all slides to `~/UNSW/COMP2521/lectures/slides/`
4. Report: "Downloaded 37 lecture slides for COMP2521 26T1"

**User request**: "Scrape COMP1531 26T1"

**Agent response**:
1. Check: COMP1531 is WebCMS3-only (NOT in public list)
2. Request cookies: "COMP1531 requires WebCMS3 authentication. Please export cookies to `~/UNSW/cookies.txt` (Netscape format) using a browser extension like 'Cookie Editor'."
3. Wait for user to provide cookies
4. Proceed with WebCMS3 scraping procedure

---

## Implementation Notes

- All curl commands use `-s` (silent) and `-f` (fail fast) flags
- Grep patterns use case-insensitive matching (`-oi`) for robustness
- Loops suppress stderr (`2>/dev/null`) to avoid cluttering output
- Directory creation uses `-p` flag (create parent dirs, no error if exists)
- YouTube downloads default to 1080p max to balance quality and file size
- Cookie files must be Netscape format (NOT JSON)
