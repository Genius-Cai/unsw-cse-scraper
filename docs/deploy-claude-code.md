# Deploy to Claude Code

## Installation

Copy `KNOWLEDGE.md` to your Claude Code skills directory:

```bash
cp KNOWLEDGE.md ~/.claude/skills/unsw-cse.md
```

Or if you cloned this repo:

```bash
ln -s "$(pwd)/KNOWLEDGE.md" ~/.claude/skills/unsw-cse.md
```

## Usage

Claude Code will automatically load the skill when you mention CSE courses. Example prompts:

```
"Download all COMP2521 26T1 lecture slides"
"Scrape COMP3311 tutorials and labs"
"Get me the past exams for COMP1521"
"Download the YouTube lecture playlist for COMP2521"
```

## With WebCMS3 Access

Export your cookies from Chrome using "Get cookies.txt LOCALLY" extension, save to `~/UNSW/cookies.txt`, then:

```
"Fetch my COMP2521 resources from WebCMS3 using my cookies"
```

## Skill Trigger

Add a description line to the top of your skill file if you want custom trigger behavior:

```markdown
# UNSW CSE Course Scraper
Use when the user asks about UNSW CSE courses, lecture slides, downloading course materials,
or accessing webcms3/cgi.cse.unsw.edu.au resources.
```
