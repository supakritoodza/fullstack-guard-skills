---
name: verify-it-runs
description: Proves a code change works by starting the app and using the changed behavior, instead of stopping at "it builds". Use after changing or fixing an endpoint, page, job, or command, and before saying the work is done. Works with any stack that can run locally.
---

# Verify It Runs

A change is not done because it compiles or reads well. Start the app and use the thing that changed.

## Safety

Check these before starting anything:

- Find which database and services the default config points at. Some projects default to production. If the target is not local or clearly disposable, set a local one, or stop and ask.
- Use fake values for third-party keys. Do not send real emails, SMS, payments, or push messages.
- Do not run commands that delete shared data, such as `docker compose down -v` or reset targets, on services you did not start.

## Workflow

1. **Say what would prove it.** Write one concrete check before running anything, such as "POST /x returns 200 with field y". Include one failure case when the change touches validation or errors.
2. **Find how it runs.** Read the README, Makefile, package scripts, compose file, and CI config. CI often has the most complete setup. Use a free local port.
3. **Prepare the minimum.** Local database, migrations, one or two rows, and a login if the route needs it. If setup is long, use the project's test client or an integration test that sends a real request through routing.
4. **Use the changed behavior.** Send the real request or open the real page. Check the status and the content, not only that nothing crashed. For a UI, use a browser tool and take one screenshot if one is available.
5. **Follow any failure.** If it fails, find the cause, even when the cause is outside your diff. Fix it if the task cannot work without it, and say that you did. Then run the same check again.
6. **Stop what you started.** Stop servers and remove temporary data.

A unit test with mocks does not count, and neither does a build or a type check. Run those as well if the project has them, but report them separately.

## Output

Lead with whether it worked, and show the evidence. Keep it under 12 lines.

```text
Works. `GET /users/42` now returns `last_login`.

Ran     go run ./cmd/api on :8123 with a local Postgres
Check   curl /users/42 -> 200, "last_login":"2026-01-15T09:00:00Z"
Check   curl /users/999 -> 404
Found   the query selected a column that does not exist, 500 on every request. Fixed in users/repo.go:31.
Not run the mobile client
```

If you could not run it, say so first and name what blocked it. Never write "works" or "verified" for something you only read.

## How to write

Write like a teammate leaving a note on a PR. Give the commands and results you saw, and keep them apart from anything you only assume.
