# Agent tooling plan

Draft. Nothing here is built unless a section says so. Covers issue #1 (verification skills),
MCP servers, and agent memory. Decisions stay with the owner.

## 1. MCP servers

Every MCP server adds tool schemas to every session, so each one costs tokens before it does
anything. Keep the default set small and turn the rest on per project.

Declared through `dotnix.ai.mcp.servers`, which feeds `programs.mcp` and then claude and codex.

| server | package | why | default |
|---|---|---|---|
| mcp-nixos | nixpkgs `mcp-nixos` | looks up real nixos and home-manager options and packages, so config is not guessed from memory | on |
| context7 | nixpkgs `context7-mcp` | current library docs instead of stale training data | on |
| funes | llm-agents `funes` | searchable memory of past agent sessions (section 3) | on, once tried |
| github | nixpkgs `github-mcp-server` | issues and PRs; needs a token, read from a file or a `gh auth token` command, never a literal | off |
| playwright | nixpkgs `playwright-mcp` | drives a real browser for verification skills | off, per project |

Skipped on purpose: a fetch server (`dotnix-web` already covers search and fetch), a filesystem
server (the agents already have file tools), and sequential-thinking (extra tokens for no new
capability).

Secrets follow the repo rule: file paths or command strings only.

## 2. Skills and verification (issue #1)

The `cursor/plugins` pstack skills in the issue have no license, so they are references, not
something to copy into this public repo. Write our own, borrowing the ideas:

| idea | our skill | what it does |
|---|---|---|
| prove it works | `prove-it-works` | before saying done, check the real artifact (run it, read the value, inspect the diff), and prefer a re-runnable script over an eyeballed check |
| benchmark checklist | `benchmark-checklist` | seven questions before reporting a speedup: limiter, tuned, limits, errors, repeatable, relevant, did the work happen |
| create verification skill | `create-verify-skill` | generate a project-local skill that launches the app, drives it like a user, and captures evidence |
| maintain verification skill | `maintain-verify-skill` | periodic pass that re-checks the feature map against the code and ships at most one PR of proven fixes |
| formal variants | `create-formal-verify-skill`, `maintain-formal-verify-skill` | pick the target where a bug costs most and tests reach least, then pick the tool by the question |

Ideas worth keeping in the formal variants:

- A check that has never been seen failing proves nothing, so each property must be shown failing
  on a deliberately broken variant.
- Record which files a check covers and the commit where it was last confirmed in sync. A passing
  check that describes deleted code looks like a proof and is not one.
- Never weaken the property or the model to make a result pass; report it as a finding.
- Tool choice: a model checker for ordering and concurrency, Lean for properties that must hold at
  every size, a Rust verifier (Kani, Verus, or Aeneas into Lean) for code-level properties.

Lean fits here where the claim is a pure function: arithmetic invariants, idempotence, digests,
folds over logs. It does not replace tests for floating point or hardware kernels, which need a
reference implementation, a tolerance and repeated measurement.

Suggested order: `prove-it-works` and `benchmark-checklist` first (text only, no tooling), then the
verify-skill pair, then the formal pair once there is a repo with something worth proving
(hive's admission check and registry digest are the first candidates).

## 3. Agent memory

Goal: agents on this machine stop re-deriving context, and a long session stops dragging its whole
history along. Constraint from AGENTS.md: low RAM and CPU, no always-on heavy service.

### Adopt first

`funes` already indexes past Claude Code, Codex and Pi sessions and serves them over MCP. Try it
for a few weeks before building anything. Measure what it misses.

Binding a memory to a remote dataset publishes it. Keep it local-only (see hive D19).

### If something is missing: a small local store

Shared store: one SQLite file, not Postgres. One machine and a few agents do not need a server,
and SQLite adds no idle memory. Add Postgres only if memory has to be shared across hosts.

| kind | storage | rules |
|---|---|---|
| episodic | SQLite table, append only | transcripts and tool traces, never rewritten, retention policy |
| semantic | SQLite table plus FTS5, vectors via `sqlite-vec` | `valid_from`, `valid_to`, `superseded_by`, `source`, `author_agent`, `trust` columns; supersede, never delete |
| procedural | markdown in git (skills, playbooks, AGENTS.md) | reviewed like code; the memory most worth a human glance |
| working | assembled per call | fixed prefix, pinned core, retrieved facts, compacted buffer |

Write path: extract facts at session end, compare against similar facts, supersede on conflict,
tag provenance. Anything derived from untrusted input (web pages, tool output) gets a low trust
label and is never promoted into pinned memory or procedural files without review.

Read path: full-text plus vector, fused with reciprocal rank fusion, filtered to currently valid
facts, returned with dates and sources, cut to a token budget, scoped by project and agent.

Consolidation: one background worker, one writer, on a small local model, niced. Agents only
append. It merges duplicates, resolves contradictions and proposes edits to procedural files.

Embeddings: one local model for the whole store, its name and dimension recorded per vector. A
model change means re-embedding, so treat it as a schema version.

Audit: log every mutation with agent, cause and diff; snapshot the file (`litestream` or a plain
copy on a timer).

Exposed as a small MCP server with `remember`, `recall` and `forget` tools, so every agent uses
the same store.

### Evaluation

A few dozen planted facts, updated facts, abstention questions and injection probes from this
repo's own domain, re-run as the store ages, with a read-everything baseline at the short horizon.
Score the write stage separately from the answers. Public leaderboards tell you to skip memory on
short histories, so they say little here.

## 4. Order of work

1. MCP: enable mcp-nixos and context7 through `dotnix.ai.mcp`.
2. Skills: `prove-it-works`, `benchmark-checklist`.
3. Memory: try funes; write the evaluation set before deciding to build.
4. Skills: verify-skill pair; formal pair when a target exists.
5. Memory store only if step 3 shows a gap.
