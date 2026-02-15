# Deploy to Gemini CLI / Google AI Studio

## Gemini CLI (gemini-cli)

Add as a system instruction file:

```bash
# Copy to Gemini config
mkdir -p ~/.gemini/
cp KNOWLEDGE.md ~/.gemini/unsw-cse-context.md
```

Then reference in your Gemini CLI config or paste as context:

```bash
gemini --system-instruction "$(cat KNOWLEDGE.md)" \
  "Download COMP2521 lecture slides"
```

## Google AI Studio

1. Open [AI Studio](https://aistudio.google.com/)
2. Create a new prompt
3. In "System Instructions", paste the contents of `KNOWLEDGE.md`
4. Ask: "Download all COMP2521 26T1 lecture slides"

## Gemini API (Python)

```python
import google.generativeai as genai

with open("KNOWLEDGE.md") as f:
    knowledge = f.read()

model = genai.GenerativeModel(
    "gemini-2.0-flash",
    system_instruction=knowledge
)

response = model.generate_content(
    "Generate a bash script to download all COMP2521 26T1 slides"
)
print(response.text)
```
