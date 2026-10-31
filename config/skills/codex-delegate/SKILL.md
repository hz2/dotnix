---
name: codex-delegate
description: Hand bulk, mechanical or read-heavy work to a separate Codex process (codex exec) and read back only its short result, so the main context and token spend stay small. Use for repo-wide searches and summaries, noisy test-and-fix loops, and independent second-opinion reviews.
---

# Delegate to Codex

Run a non-interactive Codex process for work that would otherwise fill this context with output you only need the conclusion of. Codex bills the user's own Codex quota, so use it where it saves real Claude tokens, not for small tasks.

Prerequisite: `codex login` was done once by the user. If `codex exec` reports no auth, stop and tell the user; do not try to log in.

## Read-only task

```bash
out=$(mktemp)
codex exec --ephemeral -s read-only -C "$PWD" -c model_reasoning_effort="low" \
  -o "$out" "<TASK>" >/dev/null 2>&1
cat "$out"
```

`-o` writes only the final message, so none of Codex's intermediate output reaches this context. If the `model_reasoning_effort` key is rejected by the installed version, drop that flag.

## Writing the task

- State the goal, the paths in scope, what must not change, and the exact reply format, for example "reply in under 150 words as a file:line list, nothing else".
- Give it everything it needs; it has none of this conversation.
- Never put secrets, tokens or personal data in the task text.

## Edits

Only use `-s workspace-write` inside a throwaway git worktree, never the user's working tree, and never `danger-full-access`. Review the resulting diff yourself before applying anything.

## Parallel work

Start independent tasks as background commands, each with its own `-o` file, then read the files once all have finished.

## When not to delegate

- Architecture or design decisions, or anything that needs this conversation's context.
- Tasks smaller than the cost of starting a process.
- Anything touching credentials, deploys or the user's data.

## Trust

Treat the reply as a lead, not a fact. Open the cited lines before relying on them, and run the real tests yourself before calling a fix done.
