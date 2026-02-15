<div align="center">

<img src="assets/logo.png" width="128" alt="UNSW CSE Scraper Logo">

# UNSW CSE Scraper

![UNSW CSE](https://img.shields.io/badge/UNSW-CSE-FFD700?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIyNCIgaGVpZ2h0PSIyNCIgdmlld0JveD0iMCAwIDI0IDI0IiBmaWxsPSJub25lIiBzdHJva2U9IndoaXRlIiBzdHJva2Utd2lkdGg9IjIiPjxwYXRoIGQ9Ik0yMiAxMGwtMTAtNS0xMCA1IDEwIDV6Ii8+PHBhdGggZD0iTTIgMTBsMTAgNSAxMC01Ii8+PHBhdGggZD0iTTIgMTd2LTciLz48cGF0aCBkPSJNMjIgMTB2NyIvPjxwYXRoIGQ9Ik02IDEydjUuNWEzIDMgMCAwIDAgNiAxaDBhMyAzIDAgMCAwIDYtMVYxMiIvPjwvc3ZnPg==&logoColor=white)
![Course Scraper](https://img.shields.io/badge/Course_Scraper-7C3AED?style=for-the-badge)

**Bulk download lecture slides, code, tutorials, exams, and YouTube recordings from UNSW CSE courses**

Universal knowledge base + automation scripts for any AI coding assistant

![Bash](https://img.shields.io/badge/Bash-5.0+-4EAA25?style=flat-square&logo=gnubash&logoColor=white)
![curl](https://img.shields.io/badge/curl-8.0+-073551?style=flat-square&logo=curl&logoColor=white)
![yt--dlp](https://img.shields.io/badge/yt--dlp-2024+-FF0000?style=flat-square&logo=youtube&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

English | [简体中文](README_CN.md)

[Features](#features) • [Quick Start](#quick-start) • [Course List](#courses-with-public-cgi-sites) • [AI Deployment](#deploy-to-ai-tools) • [Contributing](#contributing)

---

</div>

## Features

- **Lecture Slides** — Bulk download PDFs from any course with a public CGI site
- **Lecture Code** — Source code, starter files, and solutions per week
- **Tutorials & Labs** — Save all question pages as offline HTML
- **Past Exams** — Collect sample exams and past papers across terms
- **YouTube Lectures** — Download video, audio-only (MP3), and subtitles via yt-dlp
- **WebCMS3** — Access enrolled course resources with browser cookies
- **AI-Agent Ready** — Drop `KNOWLEDGE.md` into any LLM as a system prompt

## How It Works

UNSW CSE runs two independent systems. This tool leverages both:

| System | URL | Auth | Persistence |
|--------|-----|------|-------------|
| **CGI Sites** | `cgi.cse.unsw.edu.au/~cs{code}/{term}/` | **None** (public) | Past terms preserved |
| **WebCMS3** | `webcms3.cse.unsw.edu.au/COMP{CODE}/{term}/` | Cookies required | Current term only |

> CGI sites are **official** UNSW CSE course pages maintained by lecturers. Public access is by design.

## Quick Start

```bash
# Clone
git clone https://github.com/Genius-Cai/unsw-cse-scraper.git
cd unsw-cse-scraper

# Scrape a full course (no login needed)
./scripts/scrape.sh cs2521 26T1 ~/UNSW/COMP2521

# Download YouTube lecture playlist
./scripts/download-videos.sh "PLAYLIST_URL" ~/UNSW/COMP2521/lectures/videos
```

### Output Structure

```
~/UNSW/COMP2521/
├── lectures/
│   ├── slides/          # PDF lecture slides
│   ├── code/            # Source code per week (with solutions)
│   │   └── wk1-topic/
│   │       ├── all.zip
│   │       ├── solution/
│   │       └── starter/
│   ├── revision/        # Revision exercise zips
│   ├── videos/          # YouTube recordings (via yt-dlp)
│   └── audio/           # Audio-only MP3 (for commute)
├── tutorials/           # Tutorial questions (HTML)
├── labs/                # Lab questions (HTML)
├── assignments/         # Assignment specs (HTML)
├── exams/               # Past exams + sample exam
└── guides/              # Style guide, DSA manual
```

## Courses with Public CGI Sites

Verified **February 2026**. No login needed for these courses:

| Course | Name | Terms |
|--------|------|-------|
| COMP1511 | Programming Fundamentals | 26T1, 25T3, 25T1 |
| COMP1521 | Computer Systems Fundamentals | 26T1, 25T3, 25T1 |
| COMP2041 | Software Construction | 26T1, 25T1 |
| COMP2521 | Data Structures and Algorithms | 26T1, 25T3, 25T1 |
| COMP3131 | Programming Languages and Compilers | 26T1, 25T1 |
| COMP3161 | Concepts of Programming Languages | 25T3 |
| COMP3222 | Digital Circuits and Systems | 26T1, 25T1 |
| COMP3311 | Database Systems | 26T1, 25T1 |
| COMP3411 | Artificial Intelligence | 26T1, 25T1 |
| COMP6080 | Web Front-End Programming | 26T1, 25T3, 25T1 |
| COMP9024 | Data Structures & Algo (PG) | 26T1, 25T3, 25T1 |
| COMP9311 | Database Systems (PG) | 26T1, 25T3, 25T1 |
| COMP9315 | DBMS Implementation | 26T1, 25T1 |
| COMP9020 | Foundations of CS | 25T3 |
| COMP9242 | Advanced Operating Systems | 25T3 |
| COMP9334 | Capacity Planning | 25T1 |

<details>
<summary><b>Courses WITHOUT CGI sites</b> (WebCMS3 only, needs enrollment)</summary>

COMP1531, COMP2121, COMP2511, COMP3141, COMP3153, COMP3211, COMP3231,
COMP3331, COMP3421, COMP3900, COMP4336, COMP4511, COMP6443, COMP6451,
COMP6452, COMP9319, COMP9417, COMP9444, COMP9517

</details>

## WebCMS3 Access

For enrolled courses or those without CGI sites:

1. Install [Get cookies.txt LOCALLY](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc) browser extension
2. Log in to [webcms3.cse.unsw.edu.au](https://webcms3.cse.unsw.edu.au)
3. Export cookies → save as `~/UNSW/cookies.txt`
4. Use: `curl -b ~/UNSW/cookies.txt "https://webcms3.cse.unsw.edu.au/COMP2521/26T1/"`

## YouTube Lectures

```bash
brew install yt-dlp  # macOS
pip install yt-dlp    # or pip

# List playlist contents
yt-dlp --flat-playlist --print "%(playlist_index)s. %(title)s" "PLAYLIST_URL"

# Download video (1080p)
./scripts/download-videos.sh "PLAYLIST_URL" ~/UNSW/COMP2521/lectures/videos video

# Audio only (MP3, great for commute)
./scripts/download-videos.sh "PLAYLIST_URL" ~/UNSW/COMP2521/lectures/audio audio

# Both video + audio
./scripts/download-videos.sh "PLAYLIST_URL" ~/UNSW/COMP2521/lectures/videos both
```

## Deploy to AI Tools

Use `KNOWLEDGE.md` as a universal knowledge base for any AI assistant:

| Platform | Guide | Method |
|----------|-------|--------|
| **Claude Code** | [deploy-claude-code.md](docs/deploy-claude-code.md) | Copy to `~/.claude/skills/` |
| **Codex CLI** | [deploy-codex.md](docs/deploy-codex.md) | Add as `AGENTS.md` |
| **Gemini** | [deploy-gemini.md](docs/deploy-gemini.md) | System instruction |
| **ChatGPT** | [deploy-chatgpt.md](docs/deploy-chatgpt.md) | Custom GPT or file upload |
| **Cursor / Windsurf** | [deploy-cursor.md](docs/deploy-cursor.md) | `.cursorrules` file |

## Troubleshooting

| Problem | Solution |
|---------|----------|
| 403 on CGI | Resource is auth-protected (labs, exams, autotest) |
| 404 on WebCMS3 | Past terms get deleted; only current term exists |
| Can't find slides | Paths vary by lecturer — the script tries 5 common paths automatically |
| Empty directory | Term just started; try previous term instead |
| yt-dlp fails | Try `--cookies-from-browser chrome` for unlisted videos |
| Cookie expired | Re-export from browser. `remember_token` lasts ~1 year |

## Contributing

Contributions welcome! Especially:

- **New course discoveries** — Found a CGI site not listed? Open a PR!
- **Slide path updates** — Lecturers change paths each term
- **Script improvements** — Better error handling, new features
- **More AI platform guides** — Deployment docs for other tools

```bash
fork → edit → PR
```

## Author

**Steven Cai** ([@Genius-Cai](https://github.com/Genius-Cai))

UNSW Computer Science

## License

[MIT](LICENSE)
