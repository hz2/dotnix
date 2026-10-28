---
name: cheap-test
description: Run builds, tests, formatters, or linters in a separate cheap Pi process and return only actionable failures to the main agent. Use when validation output is noisy or should not consume the primary model context.
---

# Cheap validation

Use a separate ephemeral Pi process with the cheapest suitable model. Keep the main agent responsible for interpreting and fixing failures.

Run from the repository root:

```bash
pi --no-session --model @cheapModel@ -p "Run the requested validation command in the current repository. Do not edit files. Report only: exit status, failing command, concise error messages with file and line references, and the smallest likely fix. Do not include successful output. Command: <COMMAND>" 2>/dev/null
```

Replace `<COMMAND>` with the actual build, test, formatter, or linter command. If the command is interactive or requires credentials, ask the user before running it.

The cheap process may run the command and inspect its output, but it must not modify the working tree. Feed its concise report back into the main task and verify fixes with the real command when practical.
