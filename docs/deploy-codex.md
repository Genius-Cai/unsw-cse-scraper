# Deploy to OpenAI Codex CLI

## Installation

Add `KNOWLEDGE.md` as an `AGENTS.md` instruction file in your project:

```bash
# Option 1: Copy to project root
cp KNOWLEDGE.md ./AGENTS.md

# Option 2: Create a dedicated directory
mkdir -p ~/.codex/
cp KNOWLEDGE.md ~/.codex/unsw-cse.md
```

## Configuration

In your project's `AGENTS.md`, reference the knowledge:

```markdown
# Project Instructions

When working on UNSW CSE course tasks, refer to the UNSW CSE scraping
knowledge base at ~/.codex/unsw-cse.md for URL patterns and procedures.
```

## Usage

```bash
codex "Download all COMP2521 lecture slides from CGI site"
codex "List available courses on cgi.cse.unsw.edu.au"
```

## Approval Mode

Since scraping involves running curl commands, use `suggest` or `auto-edit` mode:

```bash
codex --approval-mode suggest "Scrape COMP2521 tutorials"
```
