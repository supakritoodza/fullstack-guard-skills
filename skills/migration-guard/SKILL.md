---
name: migration-guard
description: Checks database migrations for conflicts, ordering problems, schema drift, and rollback failures before merge. Use when a branch adds or changes migration files, when merging migration work from several people, or when a migration fails after a merge. Works with any migration tool.
---

# Migration Guard

Catch migration problems before they reach the main branch.

## Input

- The branch to check and its base branch.
- A disposable test database. Without one, do steps 1 to 3 only and say the rest was not run.

## Safety

- Never run anything against production or a shared database. If you cannot tell that a connection is disposable, stop and ask.
- Do not edit a migration that may already have run somewhere. Add a new one instead.

## Workflow

1. **Find the tool.** Read the README, CI config, and project config for the commands that apply, roll back, and show migration status. If they are not there, ask, then write them in the report so nobody has to ask again.
2. **Find the migrations.** Use `git diff --name-status <base>...HEAD` on the migration folder. Flag any edited or deleted migration that already exists on the base branch.
3. **Compare with the base branch.** Check for:
   - duplicate numbers, or more than one head
   - a migration older than the newest one on base
   - two branches changing the same table or column
4. **Run them.** Apply from an empty database, then apply on top of the base branch schema. Report only the command and the error line, not the whole log.
5. **Try rolling back.** Roll back the new migrations, then apply them again.
6. **Check drift.** Use the tool's own diff or status command to see whether models and schema still match.
7. **Check deploy risk.** Read the SQL for dropped data, table rewrites, long locks, and new `NOT NULL` columns with no default. Locking differs by database, so if you are unsure, say that.

## Output

Keep it under 15 lines. Start with whether it can merge.

```text
Don't merge yet. `0042_add_status` and `0042_add_role` share a number and both change `users`.

Fix: rename `0042_add_role` to `0043`, then run it again.

Passed  empty database, on top of main
Failed  rollback of 0043: column "role" does not exist
Risk    0043 adds NOT NULL with no default, fails if `users` has rows
Not run deploy timing, test data is small
```

## How to write

Write like a teammate leaving a note on a PR. Lead with the result, name real files, skip intros and recaps, and keep what you ran separate from what you only read.
