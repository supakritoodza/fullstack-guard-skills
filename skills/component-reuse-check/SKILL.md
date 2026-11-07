---
name: component-reuse-check
description: Finds UI that already exists before new UI gets written, so pages stay consistent. Use before adding or changing a page, screen, form, dialog, menu, layout, button, or icon in any framework, and when reviewing UI changes for duplicated components.
---

# Component Reuse Check

Stop people and agents from rebuilding UI the project already has.

## Input

- What to build: a request, a design, or a list of UI parts.
- The project, as a git repo.

If the request is only a bug fix or copy change with no new UI, skip this skill.

## Workflow

Do these in order, and do step 2 before writing any UI code.

### 1. Build the inventory

Run `scripts/build_inventory.sh` from the project root. Scripts are in this skill's own folder, not in the project. It lists UI files with their names and how many files use each one. Short lists print directly. Long lists go to a file, and the script prints the path, so search that file instead of reading it all.

If it finds nothing, the project may keep UI somewhere unusual. Look at the folder layout and project config, then pass the right folders as arguments.

### 2. Plan each part

Break the request into parts. Include the parts nobody mentioned: page layout, page header, navigation entry, icons, and success and error messages.

Look up every part in the inventory. Names vary, so search for other words too:

| Part | Also search |
|---|---|
| dialog | modal, popup, sheet, confirm, drawer, overlay |
| toggle | switch, checkbox, flag |
| message | alert, notice, banner, toast, snackbar, flash |
| text input | field, textfield, form control |
| dropdown | select, picker, combobox, menu |
| layout | shell, frame, scaffold, template, base |
| menu | nav, sidebar, tabs, routes |

A component can sit in a feature folder and still be general. Check those too. Open only the files that look like a match, and read just enough to learn how to use them.

When two versions exist, prefer the one with more uses. Do not copy from an older page that builds its own controls.

Give each part one decision:

- **Use**: fits as it is.
- **Extend**: nearly fits. Add a small option to the existing component.
- **New**: nothing fits. Say what you searched for.

### 3. Write the code

Follow the plan. Use the project's existing colors, spacing, and icons. New components go where similar ones already live.

### 4. Check your changes

Run `scripts/check_diff.sh`, or `scripts/check_diff.sh <base-branch>` to compare against a branch. It lists new UI files and added lines with raw controls, inline icons, inline styles, or hard-coded colors.

Look at each hit. Replace it if an existing component covers it. Keep it if you can say why it has to stay. The script only knows common web patterns, so on other platforms read the diff yourself and look for the same mistakes.

Existing duplicates outside this change get reported, not fixed.

## Reviewing existing changes

When the code is already written, do not change it unless asked.

1. Run `scripts/build_inventory.sh`, then `scripts/check_diff.sh <base-branch>`.
2. Read the changed UI files. List every part they build by hand, including layout, page headers, icons, and messages.
3. Look up each part as in step 2 of the workflow, and name the component to use instead with its path. Check every icon by name.

Report one line per part:

```text
Replace  hand-built sidebar  ->  AppShell  src/shell/AppShell.tsx
```

## Output

Keep the report under 15 lines. Start with the result, then one line per part. Leave out any section with nothing to say.

```text
Settings page is done. Reused 8 parts, added 1.

Use     AppShell        src/shell/AppShell.tsx
Use     Button          src/ui/Button.tsx, variant="danger" for delete
Extend  Card            added a `compact` prop, existing pages unchanged
New     ColorPicker     searched color, swatch, picker: no match

Not sure: `Tag` and `Badge` look the same. Your call whether to merge them.
Already duplicated: `ReportsPage` builds its own buttons. Left alone.
Not checked: only read the code, did not open the page in a browser.
```

## How to write

Write like a teammate leaving a note on a PR.

- Lead with the result.
- Name real files and components instead of describing them.
- Skip intros, recaps, and praise.
- Avoid filler such as "comprehensive", "robust", "seamless", and "best practices".
- Say what you checked and what you did not. If you are unsure, say so and name what would settle it.
