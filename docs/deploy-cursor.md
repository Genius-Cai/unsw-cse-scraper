# Deploy to Cursor / Windsurf / Other AI IDEs

## Cursor

Add as project rules:

```bash
# Copy to project root
cp KNOWLEDGE.md .cursorrules
```

Or create `.cursor/rules/unsw-cse.md`:

```bash
mkdir -p .cursor/rules/
cp KNOWLEDGE.md .cursor/rules/unsw-cse.md
```

## Windsurf

Add to `.windsurfrules`:

```bash
cp KNOWLEDGE.md .windsurfrules
```

## Generic: Any AI IDE with Custom Instructions

Most AI-powered IDEs support project-level instruction files. Common patterns:

| IDE | Instruction File |
|-----|-----------------|
| Cursor | `.cursorrules` or `.cursor/rules/*.md` |
| Windsurf | `.windsurfrules` |
| Cline | `.clinerules` |
| Aider | `.aider.conf.yml` (model context) |
| Continue | `.continue/config.json` (context providers) |

Simply copy `KNOWLEDGE.md` to the appropriate location for your IDE.
