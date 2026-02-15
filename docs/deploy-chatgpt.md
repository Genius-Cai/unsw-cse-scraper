# Deploy to ChatGPT / OpenAI API

## ChatGPT (Web)

1. Go to [ChatGPT](https://chat.openai.com/)
2. Click your profile → "Customize ChatGPT" → "Custom Instructions"
3. Paste the key sections from `KNOWLEDGE.md` into the instructions
4. Or simply upload `KNOWLEDGE.md` as a file attachment in your chat

## ChatGPT Custom GPT

1. Go to "Explore GPTs" → "Create"
2. Name: "UNSW CSE Scraper"
3. Instructions: Paste full `KNOWLEDGE.md` content
4. Upload `KNOWLEDGE.md` as a knowledge file

## OpenAI API (Python)

```python
from openai import OpenAI

client = OpenAI()

with open("KNOWLEDGE.md") as f:
    knowledge = f.read()

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[
        {"role": "system", "content": knowledge},
        {"role": "user", "content": "Generate a bash script to download all COMP2521 26T1 lecture slides"}
    ]
)
print(response.choices[0].message.content)
```

## Codex (codex-cli by OpenAI)

See [deploy-codex.md](deploy-codex.md).
