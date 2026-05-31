# Lean AI Coding Harness

A small, auditable project harness for Hermes Agent + Claude Code + Codex CLI + Antigravity CLI.

It gives you the useful parts of larger vibe-coding frameworks without installing a giant prompt stack:

- `CLAUDE.md` project instructions
- `AGENTS.md` routing rules for Hermes, Claude Code, Codex, and Antigravity
- `.claude/agents/` focused Claude Code agents
- `.claude/commands/` simple plan/review commands
- `.codex/agents/` lightweight Codex role prompts
- `process/` durable project context, decisions, plans, research briefs, reviews
- `deployments.yaml` registry of projects where this harness is installed
- `bin/sync-deployments.py` conservative template sync for registered projects
- `bin/install-sync-hook.sh` optional git post-merge hook that runs deployment sync after harness updates

## What this harness is for

Use it when you want AI agents to work in a repository with clear local rules instead of ad-hoc prompting.

The intended roles are:

- Hermes Agent: orchestrator, verifier, filesystem edits, final reporting
- Claude Code: primary implementation agent for multi-file coding work
- Codex CLI: independent reviewer or alternate implementation attempt
- Antigravity CLI (`agy`): optional external/deep research agent

Cost/routing assumption for this harness:

- Claude Code, Codex CLI, and Antigravity CLI are subscription/plan-limit backed for the owner, so prefer them for suitable coding, review, and research tasks before spending per-token LiteLLM API keys.
- BaishanAI GPT and DeepSeek through LiteLLM are per-token API spend. Use BaishanAI for premium reasoning/orchestration and DeepSeek for cheaper fast coding/orchestration, but do not default to them for large work when a suitable subscription-backed CLI is available.

The harness intentionally stays small. It does not install hooks, background daemons, package dependencies, or destructive automation.

## Quick start: apply to a new project

From this repository:

```bash
cd /home/tomaasz/lean-ai-coding-harness

# Always dry-run first
./bin/install-lean-harness.sh /path/to/project --dry-run

# Install into a git repository
./bin/install-lean-harness.sh /path/to/project
```

Then in the target project:

```bash
cd /path/to/project
git status --short
```

Open and customize:

1. `CLAUDE.md` — fill product summary, stack, commands, conventions.
2. `process/context.md` — fill stable facts agents should remember about this repo.
3. `process/decisions.md` — add important accepted architecture/product decisions as they happen.
4. `process/plans/` — keep short implementation plans for non-trivial tasks.
5. `process/research/` — keep distilled external/deep research briefs, including `agy` outputs.
6. `process/reviews/` — keep review notes worth preserving.

Commit the harness files if they should be shared with collaborators:

```bash
git add CLAUDE.md AGENTS.md .claude .codex process
git commit -m "chore: add lean AI coding harness"
```

If this is one of your recurring local projects, add it to `deployments.yaml` in this repository so future harness updates can be audited and synchronized.

## Install options

Dry run:

```bash
./bin/install-lean-harness.sh /path/to/project --dry-run
```

Install:

```bash
./bin/install-lean-harness.sh /path/to/project
```

Install into a directory that is not a git repository:

```bash
./bin/install-lean-harness.sh /path/to/project --allow-non-git
```

Overwrite existing harness files after creating timestamped backups under `.lean-ai-harness-backup/`:

```bash
./bin/install-lean-harness.sh /path/to/project --force
```

Use `--force` only when you intentionally want to replace existing files. Without `--force`, existing files are skipped.

## Deployment registry and sync

This repository tracks known installs in `deployments.yaml`.

Current registered projects:

- `/home/tomaasz/cavi`
- `/home/tomaasz/akta-trans`
- `/home/tomaasz/broker`
- `/home/tomaasz/akta-ocr`
- `/home/tomaasz/akta-gotova`

Each registry entry separates:

- `project_files` — files expected to contain project-specific instructions, e.g. `CLAUDE.md`, `AGENTS.md`, `process/context.md`. Sync preserves these and reports their presence; it does not overwrite them.
- `managed_files` — generic harness support files that can safely track templates, e.g. `.claude/agents/*`, `.codex/agents/*`, `process/plans/README.md`, `process/research/README.md`, `process/reviews/README.md`.

After updating templates in this repository, check all registered installs:

```bash
./bin/sync-deployments.py --dry-run
```

Apply safe managed-file updates:

```bash
./bin/sync-deployments.py
```

Sync one project only:

```bash
./bin/sync-deployments.py --project cavi --dry-run
./bin/sync-deployments.py --project cavi
```

Conservative behavior:

- Project-specific files are never overwritten by the sync script.
- Managed files are updated only from `templates/`.
- If a managed file is dirty in git, sync skips it unless you pass `--allow-dirty` after manual review.
- Every overwrite creates a timestamped backup under the target project's `.lean-ai-harness-backup/`.
- Use dry-run first and inspect `git status --short` / `git diff` in target projects after sync.

For changes that affect `CLAUDE.md`, `AGENTS.md`, or `process/context.md`, manually merge the relevant section into each project because these files intentionally contain local rules.

Optional automatic sync after this harness is updated by git pull/merge:

```bash
./bin/install-sync-hook.sh
```

The hook runs `./bin/sync-deployments.py` after a successful merge. It is deliberately non-blocking (`|| true`) so a dirty target project cannot break a harness update; review its output and then inspect target project diffs.

## Installing from GitHub

After cloning this repository:

```bash
git clone git@github.com:tomaasz/lean-ai-coding-harness.git
cd lean-ai-coding-harness
./bin/install-lean-harness.sh /path/to/project --dry-run
./bin/install-lean-harness.sh /path/to/project
```

Or run the installer from any location using the absolute path:

```bash
/home/tomaasz/lean-ai-coding-harness/bin/install-lean-harness.sh /path/to/project --dry-run
/home/tomaasz/lean-ai-coding-harness/bin/install-lean-harness.sh /path/to/project
```

## After install checklist

1. Run `git status --short` in the target project.
2. Review every created file before committing.
3. Fill real commands in `CLAUDE.md`:
   - install dependencies
   - run tests
   - run lint
   - run typecheck
   - run build
4. Fill stable repo facts in `process/context.md`.
5. Do not store secrets in any harness file.
6. Commit the harness files if they should travel with the project.

## Recommended workflow

For important changes:

1. Hermes inspects the repo and writes or updates a short plan in `process/plans/`.
2. Hermes checks whether the suitable subscription-backed CLI is available/authenticated before spending per-token LiteLLM API calls for large work.
3. If external knowledge is needed, Hermes may use Antigravity CLI (`agy`) to create a research brief in `process/research/`.
4. Claude Code implements the change, or Codex implements when a second independent attempt is more useful.
5. Hermes checks `git status`, `git diff`, and runs verification.
6. Codex reviews the diff independently when it was not the implementer; otherwise use Claude Code or Hermes review.
7. Hermes applies accepted fixes and reports final status.

For small changes, keep it simple: inspect, edit, run the narrowest relevant check, summarize.

## Antigravity research lane

Use `agy` as an optional research agent, not as a default implementer.

Good uses:

- deep research before architecture decisions
- library / framework / API comparison
- product, UX, market, or competitor research
- external documentation synthesis
- vendor, cost, or risk comparison

Preferred pattern:

```bash
agy -p "Deep research task: <topic>. Return: 1) executive summary, 2) key findings, 3) tradeoffs, 4) risks/unknowns, 5) sources/links, 6) recommendation, 7) follow-up actions."
```

Save distilled outputs under `process/research/YYYY-MM-DD-short-topic.md`.

Rules:

- Do not send secrets, `.env` contents, private keys, credential dumps, or unnecessary proprietary data to `agy`.
- Prefer report output over direct file edits from `agy`.
- Hermes or the human owner should verify and distill research before implementation.
- Promote only accepted, stable conclusions to `process/context.md` or `process/decisions.md`.

## Updating an existing project that already has AI files

If the target project already has `CLAUDE.md`, `AGENTS.md`, `.claude/`, `.codex/`, or `process/`:

1. Run the dry-run first.
2. Install without `--force` so existing files are skipped.
3. Manually merge useful sections from `templates/` into the project-specific files.
4. Use `--force` only after reviewing backups/overwrite behavior.

Example:

```bash
./bin/install-lean-harness.sh /path/to/project --dry-run
./bin/install-lean-harness.sh /path/to/project
```

Then compare templates manually:

```bash
diff -u /path/to/project/CLAUDE.md templates/CLAUDE.md || true
diff -u /path/to/project/AGENTS.md templates/AGENTS.md || true
```

## Files installed

```text
CLAUDE.md
AGENTS.md
.claude/agents/architect.md
.claude/agents/code-reviewer.md
.claude/agents/debugger.md
.claude/agents/security-reviewer.md
.claude/agents/test-writer.md
.claude/commands/plan.md
.claude/commands/review.md
.codex/agents/fixer.md
.codex/agents/reviewer.md
process/context.md
process/decisions.md
process/plans/README.md
process/research/README.md
process/reviews/README.md
```

## Safety

Do not store secrets in any harness file. Do not auto-enable destructive hooks. Add hooks later only when you understand their behavior.
