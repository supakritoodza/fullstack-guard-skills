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
2. **Run the checks script.** Run `scripts/check_migrations.sh <base-branch>` from the project root (the script is in this skill's own folder, not in the project), adding the migration folder if it is not found. Run it directly; there is no need to read its code first. It only reads git. It lists edited or deleted migrations that exist on base, numbers already used on base, numbers older than base's newest, `.up.sql` files with no `.down.sql`, and risky SQL or ORM operations. Every `Number`, `Edited`, and `Pair` line goes in the report. Read each `Risk` line before you decide.
3. **Check what the script cannot.** Tools that link migrations by id instead of number, such as Alembic or Django dependencies, can have more than one head, so use the tool's own command for that. Also look for two branches changing the same table or column.
4. **Run them.** If the project has its own verify command, such as a make target that applies, rolls back, and re-applies, use it. Otherwise apply from an empty database, then on top of the base branch schema. An empty table hides failures such as `NOT NULL` with no default, so add a row first or say the run cannot show it. Report only the command and the error line, not the whole log.
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
