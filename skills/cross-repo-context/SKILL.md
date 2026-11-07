---
name: cross-repo-context
description: Keeps work consistent across separate repos and across sessions. Finds what a change breaks in other repos and saves decisions in a handoff file. Use when work spans frontend and backend repos, when an API or shared contract changes, when resuming earlier work, or before ending a long session.
---

# Cross-Repo Context

Stop one repo's fix from breaking another, and stop decisions from getting lost between sessions.

## Input

- The task.
- Paths to the related repos. If they are unknown, ask once.

## Workflow

### When starting

Find the handoff notes. Many teams already keep them, such as `DEV_HANDOFF.md` or `docs/**/handoff-*.md`, so search for `*handoff*` before using `.handoff.md`. Read the newest one that covers this task. Check it against the code and `git log`, because the file can be out of date. Then say in 3 lines or fewer where the work stands. If the code disagrees with the file, trust the code and say so.

Do not re-decide what the file lists as decided, unless the code proves it wrong or the user asks.

### Before changing a contract

A contract is anything another repo depends on: API routes, fields, types, events, env vars, shared packages.

1. Name what is changing, such as `GET /users` field `name` becoming `fullName`.
2. Search the other repos for it, including generated clients and tests. Search for the exact name, and open only the files that match.
3. List the impact per repo.
4. Decide the order of changes. If the repos deploy separately, keep the old and new forms working together until every repo has moved. Mobile and device apps cannot be updated at once, so old versions keep calling the old form. Say how long the old form must stay.

### Before ending

Update the handoff file. Follow the team's existing name and folder; only create `.handoff.md` when there is none. Keep it under 40 lines by removing what is finished and no longer matters.

```markdown
# Handoff
Updated: 2026-01-15

## Task
Rename `name` to `fullName` in the users API.

## Decided
- API returns both fields until the frontend ships, so old clients keep working.

## Done
- backend `abc123`: added `fullName`

## Next
- frontend: `src/api/users.ts`, `src/pages/Profile.tsx`
- backend: remove `name` after the frontend deploys

## Open questions
- Does the mobile app use this API? Not in the repos I can see.
```

Never put secrets in this file. Ask whether it should be committed or added to `.gitignore`.

## Output

```text
Changing `name` to `fullName` affects 2 repos.

backend   src/users/serializer.py
frontend  src/api/users.ts, src/pages/Profile.tsx
Order     backend sends both, then frontend, then remove `name`

Not checked: mobile app, no access.
Handoff updated: .handoff.md
```

## How to write

Write like a teammate handing over work at the end of the day. Name real files and commits, and skip intros and recaps. List anything you could not check.
