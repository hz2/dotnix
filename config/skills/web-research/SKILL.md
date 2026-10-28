---
name: web-research
description: Search the web and read pages from the shell with dotnix-web. Use when built-in web search or fetch tools are unavailable or blocked, and the task needs current docs, changelogs, issues, or error messages.
---

# Web research from the shell

`dotnix-web` is on PATH. It only needs outbound https, so it works where built-in web tools are disabled.

```bash
dotnix-web search -n 5 "helix languages.toml formatter"   # numbered title, url, snippet
dotnix-web fetch https://docs.helix-editor.com/languages.html   # page as plain text, capped
dotnix-web fetch -r https://raw.githubusercontent.com/o/r/main/flake.nix   # raw body
```

Workflow:

1. Search with specific terms (tool name, version, exact error string).
2. Fetch the one or two most authoritative results: official docs, the project's repo, release notes. Prefer those over blogs and aggregators.
3. Cite the url you relied on in your answer.

If `dotnix-web` is missing, fall back to `curl -fsSL <url>`; for search, `curl -fsSL --data-urlencode "q=<query>" https://html.duckduckgo.com/html/` and read the `result__a` links.

Never send repository contents, secrets or internal hostnames as a search query.
