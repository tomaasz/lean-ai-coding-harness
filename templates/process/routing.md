# Agent Routing Policy

This file documents the lightweight routing policy for AI-agent work in this repository. It is intentionally procedural, not a hard-coded model router: choose the cheapest suitable lane, record the route for non-trivial work, and verify outputs before trusting any agent.

## Cost classes

- `subscription`: already paid through the owner's plan/subscription. Prefer these lanes when they fit the task.
  - Claude Code CLI (`claude`)
  - Codex CLI (`codex`)
  - Antigravity CLI (`agy`)
- `per-token-cheap`: billed per token, but intended as worker/backbone capacity.
  - DeepSeek via LiteLLM
- `per-token-premium`: billed per token and should be used deliberately.
  - BaishanAI GPT via LiteLLM

## Default route table

| Task type | Preferred route | Fallback | Notes |
|---|---|---|---|
| `code_implementation` | `claude-cli` or `codex-cli` | `deepseek-v4-pro` | Use subscription CLI for multi-file edits when available. |
| `code_review` | `codex-cli` | `claude-cli`, then `deepseek-v4-pro` | Keep reviews independent from the implementer where possible. |
| `debugging` | `claude-cli` | `codex-cli`, then `deepseek-v4-pro` | For small fixes Hermes may edit directly after inspection. |
| `repo_research` | `hermes-local` | `claude-cli` or `codex-cli` | Prefer local file inspection before external calls. |
| `external_research` | `agy-cli` | `deepseek-v4-flash`, then premium if strategic | Do not send secrets or unnecessary proprietary data to external research lanes. |
| `devops` | `hermes-local` + `deepseek-v4-flash/pro` | `claude-cli` | Use premium only for risky architecture or incident reasoning. |
| `multimodal_ocr` | project-specific OCR/Gemini flow | `deepseek-v4-pro` for code reasoning | Preserve project-specific OCR guardrails. |
| `premium_reasoning` | `baishan-gpt` | `deepseek-v4-pro` | Use only when high-quality strategy/architecture materially matters. |
| `batch_simple` | `deepseek-v4-flash` | `codex-cli` | Avoid premium model for repeated simple tasks. |
| `docs_planning` | `hermes-local` or `claude-cli` | `deepseek-v4-pro` | Save durable plans under `process/plans/`. |

## Route decision log

For non-trivial work, include a short route decision in the plan, review, or final report:

```text
Route decision:
- task_type: <code_implementation|code_review|external_research|...>
- route: <claude-cli|codex-cli|agy-cli|hermes-local|deepseek-v4-pro|deepseek-v4-flash|baishan-gpt>
- cost_class: <subscription|per-token-cheap|per-token-premium|local>
- reason: <why this route fits>
- fallback: <what to use if unavailable>
```

Use `per-token-premium` only with an explicit reason, for example architecture, product strategy, or high-risk decision support.

## Manual route override

If the owner specifies a route, follow it unless it is unsafe or unavailable:

```text
force_route: claude-cli
force_route: codex-cli
force_route: agy-cli
force_route: deepseek-v4-pro
force_route: deepseek-v4-flash
force_route: baishan-gpt
```

If a forced route is unavailable, report the failure and use the declared fallback only when the owner has not prohibited it.

## Availability check

Before large coding/research/review work, run the harness check from the repository root when available:

```bash
/path/to/lean-ai-coding-harness/bin/check-agent-routes
```

or from inside the harness repo:

```bash
./bin/check-agent-routes
```

The check should confirm whether `claude`, `codex`, `agy`, and the configured LiteLLM routes are reachable. Treat CLI version checks as advisory: authentication can still fail at task runtime.

## Guardrails

- Never send secrets, `.env` contents, private keys, credential dumps, or unnecessary proprietary data to any external or subscription CLI.
- Do not let a routing choice bypass project-specific rules in `CLAUDE.md`, `AGENTS.md`, or `process/context.md`.
- Verify another agent's self-report by reading files, checking diffs, and running relevant tests.
- Prefer narrow, reversible edits over broad autonomous rewrites.
