Review the current changes. Focus: $ARGUMENTS

Process:
1. Inspect `git status --short` and `git diff --stat`.
2. Review the diff and relevant surrounding files.
3. Prioritize correctness, security, data loss, concurrency, and missing tests.
4. Return findings with severity and evidence.
5. If the diff is too large, summarize scope and ask to narrow it.

Do not modify files unless explicitly asked.
