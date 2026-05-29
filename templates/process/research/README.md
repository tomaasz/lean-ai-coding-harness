# Research Artifacts

Store durable external research briefs here.

Use this directory for research-heavy inputs that should inform plans or architecture decisions, especially when using Antigravity CLI (`agy`) as a research agent.

## When to create a research brief

Create a file here when a task needs knowledge from outside the repository, for example:

- library / framework / API comparison
- current documentation or breaking-change survey
- product, UX, market, or competitor research
- architecture tradeoff analysis
- cost / risk / vendor comparison

Do not create research files for routine implementation details that are obvious from the codebase.

## Suggested filename

```text
YYYY-MM-DD-short-topic.md
```

Examples:

```text
2026-02-14-realtime-sync-options.md
2026-02-14-onboarding-ux-patterns.md
```

## Suggested structure

```markdown
# <Topic>

Date: YYYY-MM-DD
Tool: agy / manual / other
Prompt: <short prompt summary>

## Executive Summary

## Findings

## Tradeoffs

## Risks / Unknowns

## Sources

## Recommendation

## Follow-up Actions
```

## Antigravity CLI pattern

Prefer report generation over direct repository edits:

```bash
agy -p "Deep research task: <topic>. Return: 1) executive summary, 2) key findings, 3) tradeoffs, 4) risks/unknowns, 5) sources/links, 6) recommendation, 7) follow-up actions."
```

Rules:

- Do not send secrets, `.env` contents, private keys, or credential dumps to `agy`.
- Do not paste large proprietary datasets unless the user explicitly approves.
- Do not let `agy` be the final authority. Hermes or the human owner should distill the result before implementation.
- Promote only stable, accepted outcomes to `process/context.md` or `process/decisions.md`.
