# Project AI Coding Guide

This project uses a lean AI coding harness for Hermes Agent, Claude Code, and Codex CLI.

## Project Summary

Fill this section during setup:

- Product / purpose:
- Primary users:
- Main stack:
- Runtime / deployment:
- Database / storage:
- Test command:
- Lint command:
- Build command:

## Operating Principles

1. Understand before editing.
2. Prefer minimal, reviewable changes.
3. Follow existing patterns over introducing new architecture.
4. Update tests when behavior changes.
5. Run the narrowest useful verification first, then broader checks when needed.
6. Never read, print, or modify secrets unless explicitly requested.
7. Do not commit, push, deploy, or rewrite git history without explicit user approval.

## Required Workflow for Non-Trivial Changes

For any feature, refactor, migration, or bug fix touching more than one file:

1. Inspect relevant files and existing patterns.
2. Write or update a short plan under `process/plans/`.
3. State assumptions and risks.
4. Implement incrementally.
5. Run relevant tests / lint / type checks.
6. Summarize changed files and verification results.
7. If new stable project knowledge was discovered, update `process/context.md` or `process/decisions.md`.

## Code Review Expectations

When reviewing code, prioritize:

1. Correctness bugs
2. Security issues
3. Data loss / migration risks
4. Race conditions and concurrency bugs
5. Missing tests for changed behavior
6. Maintainability and unnecessary complexity

Avoid style-only comments unless they obscure correctness or violate established project conventions.

## Commands

Update these with real commands:

```bash
# install dependencies

# run tests

# run lint

# run typecheck

# run build
```

## Project Conventions

Fill in after scanning the repo:

- Formatting:
- Naming:
- Error handling:
- Logging:
- API conventions:
- Testing conventions:

## AI Agent Routing

Cost/routing rule for this setup:

- Prefer subscription-backed CLIs when they fit the task: Claude Code, Codex CLI, and Antigravity CLI are paid through the owner's subscriptions/plan limits.
- Treat BaishanAI GPT and DeepSeek via LiteLLM as per-token API spend. Use them deliberately: BaishanAI for premium reasoning/orchestration, DeepSeek for cheaper fast coding/orchestration, not as the automatic answer to every repo task.
- Before large coding/research/review work, check whether the relevant CLI is installed/authenticated and prefer it when suitable.

- Use Hermes for orchestration, verification, filesystem edits, and final reporting.
- Use Claude Code for primary implementation tasks, complex refactors, and multi-file reasoning.
- Use Codex CLI for independent review, alternate implementation attempts, and second opinions.
- Use Antigravity CLI (`agy`), if installed, for external research-heavy tasks and strategic second opinions, not routine implementation.

### Antigravity Research Lane

Use `agy` only when the task benefits from external information or broad synthesis, such as:

- architecture tradeoff research
- library / framework / API comparison
- current documentation or breaking-change survey
- product, UX, market, or competitor research
- vendor, cost, or risk comparison

Preferred command pattern:

```bash
agy -p "Deep research task: <topic>. Return: 1) executive summary, 2) key findings, 3) tradeoffs, 4) risks/unknowns, 5) sources/links, 6) recommendation, 7) follow-up actions."
```

Save durable research summaries under `process/research/YYYY-MM-DD-short-topic.md`. Promote only accepted, stable conclusions to `process/context.md` or `process/decisions.md`.

Do not send secrets, `.env` contents, private keys, credential dumps, or unnecessary proprietary data to `agy`. Prefer report output over direct file edits.

## Safety Boundaries

Agents must ask before:

- Installing new dependencies
- Running migrations against non-local databases
- Deleting files or directories
- Changing public APIs
- Editing CI/CD, deployment, billing, auth, or secrets
- Running commands that publish, deploy, push, or force-push

Agents must not include secret values in responses, logs, plans, or context files.
