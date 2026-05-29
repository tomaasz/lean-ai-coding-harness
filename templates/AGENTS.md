# Agent Registry

This project uses multiple AI coding agents. This file defines routing rules and shared conventions.

## Agents

### Hermes Agent

Role: orchestrator and verifier.

Use Hermes for:
- Breaking down tasks
- Reading and editing small files directly
- Running shell commands and tests
- Coordinating Claude Code / Codex CLI / Antigravity CLI
- Comparing independent reviews
- Final user-facing summaries

### Claude Code

Role: primary implementation agent.

Use Claude Code for:
- Multi-file changes
- Refactors
- Debugging with repository context
- Test writing
- Architecture analysis

Preferred non-interactive pattern:

```bash
claude -p "<task>" --allowedTools "Read,Edit,Write,Bash" --max-turns 10
```

Use narrower `--allowedTools` where possible. For review-only tasks, prefer `--allowedTools "Read"`.

### Codex CLI

Role: independent reviewer or alternate implementer.

Use Codex for:
- Second-opinion review of diffs
- Parallel exploration in worktrees
- Independent bug-fix attempts
- Validating Claude Code output

Preferred pattern:

```bash
codex exec "<task>"
```

For edits:

```bash
codex exec --full-auto "<task>"
```

Codex generally requires a git repository and a PTY when orchestrated through Hermes.

### Antigravity CLI

Role: optional research agent and external second opinion.

Use Antigravity CLI (`agy`) when a task needs knowledge from outside this repository or broad synthesis across sources.

Good uses:
- Deep research before architecture decisions
- Library / framework / API comparison
- Product, UX, market, or competitor research
- External documentation and breaking-change synthesis
- Independent strategic opinions before writing an implementation plan

Avoid using `agy` for routine implementation tasks, small code edits, or default review. It can be token-expensive and should not be part of every workflow.

Use only if `agy` is installed and authenticated.

Preferred deep-research pattern:

```bash
agy -p "Deep research task: <topic>. Return: 1) executive summary, 2) key findings, 3) tradeoffs, 4) risks/unknowns, 5) sources/links, 6) recommendation, 7) follow-up actions."
```

For durable research, save the distilled result under `process/research/YYYY-MM-DD-short-topic.md`.

Safety rules:
- Do not send secrets, `.env` contents, private keys, credential dumps, or unnecessary proprietary data to `agy`.
- Prefer report output over direct file edits.
- Hermes or the human owner must distill and verify research before implementation.
- Promote only accepted, stable conclusions to `process/context.md` or `process/decisions.md`.

## Standard Multi-Agent Workflow

For important changes:

1. Hermes inspects repo and writes/updates a plan in `process/plans/`.
2. If the task needs external knowledge, Hermes may ask `agy` for a research brief and save the distilled result in `process/research/`.
3. Claude Code implements the change.
4. Hermes checks `git diff`, runs tests, and fixes simple issues.
5. Codex reviews the diff independently.
6. Hermes decides whether to apply review findings.
7. Hermes reports final changed files, tests run, and remaining risks.

## Review Prompt Template

```text
Review the current git diff. Focus on correctness, security, concurrency, data loss, migrations, API compatibility, and missing tests. Return prioritized findings with evidence. Do not comment on style unless it affects correctness or maintainability.
```

## Implementation Prompt Template

```text
You are working in this repository. First inspect relevant files and existing patterns. Then implement the minimal change requested. Add or update tests for changed behavior. Run the narrowest relevant verification. Report changed files, commands run, and remaining risks. Do not commit, push, deploy, or touch secrets.
```

## Verification Requirements

Before declaring success:

- Inspect `git status --short`.
- Inspect `git diff --stat`.
- Run relevant tests / lint / typecheck when available.
- Mention any verification that could not be run.
- Do not trust another agent's self-report without checking files or command output.
