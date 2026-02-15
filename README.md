# UNSW CSE Course Scraper

> Scrape lecture slides, code, tutorials, labs, exams, and YouTube recordings from UNSW CSE course websites.

A universal knowledge base + automation scripts for downloading UNSW Computer Science & Engineering course materials. Works standalone or as a plugin for AI coding assistants (Claude Code, Codex CLI, Gemini, ChatGPT, Cursor, etc.).

## Features

- **Lecture slides** — Bulk download PDFs from any course with a CGI site
- **Lecture code** — Download source code, starter files, and solutions
- **Tutorials & Labs** — Save all question pages as HTML
- **Past exams** — Collect sample exams and past papers
- **YouTube lectures** — Download video/audio/subtitles via yt-dlp
- **WebCMS3 integration** — Access enrolled course resources with cookies
- **AI-agent ready** — Drop-in knowledge file for any LLM tool

## Quick Start

```bash
# Clone
git clone https://github.com/Genius-Cai/unsw-cse-scraper.git
cd unsw-cse-scraper

# Scrape a course (no login needed for CGI courses)
./scripts/scrape.sh cs2521 26T1 ~/UNSW/COMP2521

# Download YouTube lectures
./scripts/download-videos.sh "https://www.youtube.com/playlist?list=PLxxx" ~/UNSW/COMP2521/lectures/videos
```

## How It Works

UNSW CSE uses two independent systems:

| System | URL | Auth | Content |
|--------|-----|------|---------|
| **CGI Sites** | `cgi.cse.unsw.edu.au/~cs{code}/{term}/` | None (public) | Slides, code, tutorials, labs, exams |
| **WebCMS3** | `webcms3.cse.unsw.edu.au/COMP{CODE}/{term}/` | Cookies required | Announcements, grades, resources |

CGI sites are official course websites maintained by lecturers with Apache directory listings. Not all courses have them — see the [course list](#courses-with-public-cgi-sites) below.

## Courses with Public CGI Sites

✅ = public slides/code available, no login needed

| Course | Name | Available Terms |
|--------|------|-----------------|
| ✅ COMP1511 | Programming Fundamentals | 26T1, 25T3, 25T1 |
| ✅ COMP1521 | Computer Systems Fundamentals | 26T1, 25T3, 25T1 |
| ✅ COMP2041 | Software Construction | 26T1, 25T1 |
| ✅ COMP2521 | Data Structures and Algorithms | 26T1, 25T3, 25T1 |
| ✅ COMP3131 | Programming Languages and Compilers | 26T1, 25T1 |
| ✅ COMP3161 | Concepts of Programming Languages | 25T3 |
| ✅ COMP3222 | Digital Circuits and Systems | 26T1, 25T1 |
| ✅ COMP3311 | Database Systems | 26T1, 25T1 |
| ✅ COMP3411 | Artificial Intelligence | 26T1, 25T1 |
| ✅ COMP6080 | Web Front-End Programming | 26T1, 25T3, 25T1 |
| ✅ COMP9024 | Data Structures and Algorithms (PG) | 26T1, 25T3, 25T1 |
| ✅ COMP9311 | Database Systems (PG) | 26T1, 25T3, 25T1 |
| ✅ COMP9315 | DBMS Implementation | 26T1, 25T1 |
| ✅ COMP9020 | Foundations of Computer Science | 25T3 |
| ✅ COMP9242 | Advanced Operating Systems | 25T3 |
| ✅ COMP9334 | Capacity Planning | 25T1 |

❌ **WebCMS3 only** (needs enrollment): COMP1531, COMP2511, COMP3141, COMP3231, COMP3331, COMP3900, COMP6443, COMP9417, COMP9444, COMP9517, and others.

## Output Structure

```
~/UNSW/COMP2521/
├── lectures/
│   ├── slides/          # PDF lecture slides
│   ├── code/            # Source code per week (with solutions)
│   ├── revision/        # Revision exercise zips
│   ├── videos/          # YouTube recordings
│   └── audio/           # Audio-only (for commute)
├── tutorials/           # Tutorial questions (HTML)
├── labs/                # Lab questions (HTML)
├── assignments/         # Assignment specs (HTML)
├── exams/               # Past exams + sample exam
└── guides/              # Style guide, DSA manual
```

## WebCMS3 Access (Optional)

For courses without CGI sites, or to access announcements/grades/forum:

1. Install a browser extension: [Get cookies.txt LOCALLY](https://chromewebstore.google.com/detail/get-cookiestxt-locally/cclelndahbckbenkjhflpdbgdldlbecc)
2. Log in to [webcms3.cse.unsw.edu.au](https://webcms3.cse.unsw.edu.au)
3. Export cookies as Netscape format to `~/UNSW/cookies.txt`
4. Use with curl: `curl -b ~/UNSW/cookies.txt "https://webcms3.cse.unsw.edu.au/COMP2521/26T1/"`

## YouTube Lecture Downloads

Requires [yt-dlp](https://github.com/yt-dlp/yt-dlp):

```bash
brew install yt-dlp  # macOS
pip install yt-dlp    # or via pip

# List videos in a playlist
yt-dlp --flat-playlist --print "%(playlist_index)s. %(title)s" "PLAYLIST_URL"

# Download all videos (1080p)
./scripts/download-videos.sh "PLAYLIST_URL" ~/UNSW/COMP2521/lectures/videos video

# Audio only (MP3, for commute listening)
./scripts/download-videos.sh "PLAYLIST_URL" ~/UNSW/COMP2521/lectures/audio audio
```

## Deploy to AI Tools

Use `KNOWLEDGE.md` as a knowledge base / system prompt for any AI assistant:

| Tool | Guide |
|------|-------|
| Claude Code | [docs/deploy-claude-code.md](docs/deploy-claude-code.md) |
| OpenAI Codex CLI | [docs/deploy-codex.md](docs/deploy-codex.md) |
| Gemini CLI / AI Studio | [docs/deploy-gemini.md](docs/deploy-gemini.md) |
| ChatGPT / Custom GPT | [docs/deploy-chatgpt.md](docs/deploy-chatgpt.md) |
| Cursor / Windsurf / IDEs | [docs/deploy-cursor.md](docs/deploy-cursor.md) |

## Troubleshooting

| Problem | Solution |
|---------|----------|
| 403 on CGI | Resource is auth-protected (labs, exams, autotest) |
| 404 on WebCMS3 | Past terms get deleted; only current term exists |
| Can't find slides | Paths vary: try `lectures/slides/`, `lectures/`, `slides/`, `Lectures/` |
| Empty directory | Term just started; content uploads incrementally. Try previous term. |
| yt-dlp fails | Try `--cookies-from-browser chrome` for unlisted videos |
| Cookie expired | Re-export from browser. `remember_token` lasts ~1 year. |

## Contributing

Contributions welcome! If you find new course CGI sites, updated slide paths, or better scraping methods:

1. Fork this repo
2. Add your changes
3. Submit a PR

Please help keep the course list up to date each term.

## Author

**Steven Cai** ([@Genius-Cai](https://github.com/Genius-Cai))
UNSW Computer Science

## License

MIT

---

# UNSW CSE 课程资料抓取器

> 批量下载 UNSW CSE 课程的 lecture slides、代码、tutorials、labs、考试和 YouTube 录播。

通用知识库 + 自动化脚本，支持直接使用或作为 AI 编程助手插件 (Claude Code, Codex CLI, Gemini, ChatGPT, Cursor 等)。

## 功能

- **Lecture slides** — 批量下载 PDF 课件
- **Lecture code** — 下载源代码、starter files 和 solutions
- **Tutorials & Labs** — 保存所有题目页面
- **Past exams** — 收集历年试卷
- **YouTube lectures** — 通过 yt-dlp 下载视频/音频/字幕
- **WebCMS3** — 使用 cookies 访问已注册课程资源
- **AI 工具兼容** — 可直接作为任何 LLM 的知识库

## 快速开始

```bash
git clone https://github.com/Genius-Cai/unsw-cse-scraper.git
cd unsw-cse-scraper

# 抓取课程 (CGI 课程不需要登录)
./scripts/scrape.sh cs2521 26T1 ~/UNSW/COMP2521

# 下载 YouTube 录播
./scripts/download-videos.sh "PLAYLIST_URL" ~/UNSW/COMP2521/lectures/videos
```

## 原理

UNSW CSE 有两套独立系统：
- **CGI 站** (`cgi.cse.unsw.edu.au`) — 公开，无需登录，Apache 目录浏览
- **WebCMS3** (`webcms3.cse.unsw.edu.au`) — 需要 cookies，只保留当前学期

不是所有课程都有 CGI 站，详见上方[课程列表](#courses-with-public-cgi-sites)。

## 部署到 AI 工具

将 `KNOWLEDGE.md` 作为知识库 / system prompt 加载到你的 AI 助手中。详见 `docs/` 目录下的部署指南。

## 作者

**Steven Cai** ([@Genius-Cai](https://github.com/Genius-Cai))
UNSW 计算机科学

## 协议

MIT
