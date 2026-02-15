---
name: unsw-cse
description: Scrape UNSW CSE course materials — lecture slides, code, tutorials, exams, YouTube recordings. Supports 16+ courses with public CGI sites and WebCMS3 authenticated access.
---

# UNSW CSE Course Scraper

Universal knowledge file for AI agents to scrape UNSW CSE course materials.
Compatible with: Claude Code, Codex CLI, Gemini, ChatGPT, Cursor, and any LLM-based tool.

## Quick Start

When a user asks to scrape CSE course materials, follow this flow:

1. **Ask**: Which course? (e.g. COMP2521) Which term? (e.g. 26T1)
2. **Check**: Does this course have a public CGI site? (see table below)
3. **If yes**: Scrape directly — no authentication needed
4. **If no**: User needs to provide WebCMS3 cookies (exported from browser)

---

## Architecture: Two Independent Systems

### System 1: CGI Sites — `cgi.cse.unsw.edu.au` (Public)

Static course websites hosted by lecturers. Apache serves files directly.
**No authentication required.** Past terms are preserved indefinitely.

- URL pattern: `https://cgi.cse.unsw.edu.au/~cs{code}/{term}/`
- Example: `https://cgi.cse.unsw.edu.au/~cs2521/26T1/`

#### Publicly Accessible Resources

| Resource | URL Pattern | Format |
|----------|-------------|--------|
| Lecture slides | `/lectures/slides/` or `/lectures/` or `/slides/` or `/Lectures/` | PDF |
| Lecture code | `/lectures/code/` | .c, .h, .zip, Makefile |
| Code solutions | `/lectures/code/{week}/solution/` | .c source files |
| Revision exercises | `/lectures/revision/` | .zip |
| Tutorial questions | `/tut/{1-10}/questions` | HTML |
| Lab questions | `/lab/{1-17}/questions` | HTML |
| Assignment specs | `/assignments/ass{1-2}/` | HTML |
| Past exams | `/past-exam/{term}` (e.g. `/past-exam/22T3`) | HTML |
| Sample exam | `/sample-exam` | HTML |
| Practice exercises | `/practice-exercises/` (with solutions!) | HTML |
| Style guide | `/style-guide` | HTML |
| DSA manual | `/dsa-manual` | HTML |

#### Protected Resources (403 — separate auth required)

- `/labs/` — lab submission system
- `/exams/` — exam papers (current term)
- `/autotest/` — automated testing system
- `/view/main.cgi` — CGI portal, uses zID/zPass (NOT WebCMS3 cookies)

### System 2: WebCMS3 — `webcms3.cse.unsw.edu.au` (Authenticated)

Course management system built with Flask/gunicorn.
**Requires browser cookies for access.** Only current term data exists.

- URL pattern: `https://webcms3.cse.unsw.edu.au/COMP{CODE}/{term}/`
- Example: `https://webcms3.cse.unsw.edu.au/COMP2521/26T1/`

#### Access Levels

| Content | Any authenticated user | Enrolled students only |
|---------|----------------------|----------------------|
| Course homepage & description | Yes | — |
| Announcements/notices | Yes | — |
| Staff names & sidebar | Yes | — |
| Resource pages & files | — | Yes (403 otherwise) |
| Grades & analytics | — | Yes |
| Forum | — | Yes |

#### Required Cookies

Export from browser as Netscape format `.txt` file:
- `remember_token` — persistent login, format: `{zID_number}|{hash}`, lasts ~1 year
- `session` — Flask signed session, expires when browser closes

Tools to export: "Cookie Editor" or "Get cookies.txt LOCALLY" browser extension.

#### Key Endpoints

| Endpoint | Description |
|----------|-------------|
| `/COMP{code}/{term}/` | Course homepage |
| `/COMP{code}/{term}/resources/{id}` | Individual resource (sequential integer IDs) |
| `/COMP{code}/{term}/notices` | Announcements page |
| `/users/{zID}` | User profile |
| `/search` | Course search (all terms back to 2014) |
| `/messages/` | JSON API endpoint |

---

## Courses with Public CGI Sites

Verified February 2026. Slide directory paths vary by lecturer.

### Available (public, no auth):

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

### NOT Available (WebCMS3 only, needs enrollment):

COMP1531, COMP2121, COMP2511, COMP3141, COMP3153, COMP3211, COMP3231,
COMP3331, COMP3421, COMP3900, COMP4336, COMP4511, COMP6443, COMP6451,
COMP6452, COMP9319, COMP9417, COMP9444, COMP9517

---

## Scraping Procedures

### 1. Discover slide directory

Slide paths vary by lecturer. Try these in order:

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

### 2. Download all lecture slides

```bash
SLIDE_PATH="lectures/slides/"  # from step 1
SAVE_DIR=~/UNSW/COMP2521/lectures/slides
mkdir -p "$SAVE_DIR"

curl -s "${BASE}/${SLIDE_PATH}" \
  | grep -o 'href="[^"]*\.pdf"' | sed 's/href="//;s/"$//' \
  | while read f; do
      echo "Downloading: $f"
      curl -s -o "${SAVE_DIR}/$f" "${BASE}/${SLIDE_PATH}$f"
    done
```

### 3. Download lecture code

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

### 4. Download tutorials and labs

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

### 5. Download exams and guides

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

### 6. Download YouTube lectures

Requires `yt-dlp` (`brew install yt-dlp` / `pip install yt-dlp`).

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

### 7. WebCMS3 scraping (needs cookies)

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

| Problem | Solution |
|---------|----------|
| 403 on CGI resource | Behind CGI portal auth — not accessible via cookies |
| 404 on WebCMS3 | Past terms get deleted; only current term exists |
| Can't find slides | Try all paths: `lectures/slides/`, `lectures/`, `slides/`, `Lectures/` |
| Empty directory | Term just started; try previous term |
| yt-dlp fails | Video may be unlisted. Try `--cookies-from-browser chrome` |
| Cookie expired | `remember_token` ~1 year, `session` = browser session. Re-export. |
| CGI site doesn't exist for course | Course only uses WebCMS3 — needs enrollment cookies |
