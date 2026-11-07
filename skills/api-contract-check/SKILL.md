---
name: api-contract-check
description: Checks that an API and the apps that call it agree on field names, nesting, types, null, and enum values, so a release does not silently drop data or crash a client. Use before releasing a backend together with web or mobile clients, after renaming or adding API fields, when a value shows up empty or zero in a client, or when asked whether frontend and backend match. Works with any stack.
---

# API Contract Check

Find every place where a client sends or reads a field differently from what the server sends or reads. These bugs pass type checks and code review on each side, then lose data in production.

## Input

- The server repo and the client repos. If client paths are unknown, ask once.
- The endpoints or feature to check. If none are given, use what changed against the base branch.

Do not change code unless asked.

## Workflow

### 1. Pick the scope

List the endpoints in scope with their server handler files. On a branch, start from the server and client diffs against base. Then grep every client repo for each endpoint's path, such as `users/profile`, and keep every folder that matches. One API is often called from more than one feature folder, and the folder you expect is not always the only one. Add the folders those files import their types and DTOs from. Keep the list narrow. A whole repo gives too many hits.

### 2. Run the script

The script is in this skill's own folder, such as `.claude/skills/api-contract-check/scripts/`, not in the project.

Always run it before reading code, even when you plan to compare by hand. It catches what reading misses. Run it directly; there is no need to read its code first.

```sh
scripts/field_gaps.sh -b <base> -e <endpoint-path> <server-dir> <client-repo> [client-repo ...]
```

With `-e` (repeatable, such as `-e users/profile`), pass whole client repos: the script finds every folder that calls the endpoint, so none is missed. Without `-e`, pass the client folders yourself.

It only reads files. It prints:

- **Typo?** a client name close to a server name.
- **Sent?** a client sets this on a request-like object, but the server never mentions it, so the value is dropped.
- **Decode?** a client annotation names a field the server never sends. A non-null field fails to decode.
- **Nested?** the client sets a field inside an object, and the server knows both names. Read the server to see whether it reads the field there or at the top level.
- **Missing** a client name the server never mentions, often a client-only field. Check the ones in scope, and do not list the rest.
- **Server wire-name changes** lines in the server diff that add, drop, or rename a JSON field. Search the clients for the old name.

The script compares names only. It cannot see the next step.

### 3. Compare each endpoint field by field

For every endpoint in scope, read the server's request and response shape: the struct tags, serializer, SQL aliases, or OpenAPI spec. Then read the client's type, DTO, or the code that builds the request. Check each field for:

| Check | Example of a break |
|---|---|
| Name | client reads `phone`, server sends `phone_number` |
| Nesting | client sends `address.zip_code`, server reads top-level `zip_code` |
| Type | server sends a decimal as a string, client expects a number |
| Null | server can send `null`, client field is non-null (Kotlin, Swift, Dart crash on decode) |
| Enum | client sends a status or method the server rejects, or misses one the server sends |
| Required | server requires a field the client never sends |

Look at both directions: what the client sends and what it reads.

### 4. Rank by what the user loses

- **Breaks**: a crash, a failed request, or data silently dropped or shown as empty or zero.
- **Risk**: works today but breaks when a value is null, missing, or a new enum value.
- **Note**: client-only fields or unused server fields. Mention them in one line, do not list them.

Mobile and device apps update late, so a break there lasts until users update. Say so when it applies.

## Output

Keep it under 20 lines. Start with whether it can ship. One line per break, with both sides' file and line.

```text
Not safe to release: 3 breaks, 1 risk.

Break  profile form sends `note`, API reads `remark`: the note is dropped
       web src/api/profile.ts:42  vs  api users/handler.go:88
Break  mobile reads "user_name" into a non-null String, API sends `username`: login fails to decode
       mobile UserDto.kt:17  vs  api users/serializer.go:30
Risk   `expires_at` can be null for trial plans, web formats it as a date

Not checked: endpoints outside users, runtime responses (read code only).
```

## How to write

Write like a teammate leaving a note on a PR. Lead with the result, name real files and fields, skip intros and recaps. Say which findings you confirmed by reading both sides and which come only from the script.

Every `Typo?`, `Sent?`, `Decode?`, and `Nested?` line in scope goes in the report, as a Break if reading both sides confirms it, or with one line on why it is fine.
