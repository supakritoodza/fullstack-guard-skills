---
name: ui-ux-review
description: Reviews a finished screen for usability, accessibility, visual hierarchy, consistency, and responsive problems, and explains why each one matters. Use after building or changing a page or component, before a PR, or when asked whether a UI follows UX/UI principles. Works with any framework.
---

# UI/UX Review

Check a real screen and explain problems so the person learns the rule behind them.

## Input

- A URL, screen, or component.
- Who uses it and what they need to get done. If this is missing, ask once, then state your assumption.
- The design system or mockup, if there is one.

## Workflow

1. **Run automated checks first.** Use whatever the project has for accessibility and lint. They cost little and give measured results, such as contrast ratios.
2. **Look at the real screen.** Open it at desktop and mobile widths. Take as few screenshots as you need. If you cannot open it, review the code and say so.
3. **Try the states.** Check loading, empty, error, long text, keyboard focus, and hover.
4. **Check five areas:**
   - **Usability:** Is the next step obvious? Does the user get feedback? Can they undo or cancel? Are errors useful?
   - **Accessibility:** Check against WCAG 2.2 AA: contrast, labels, keyboard use, focus order, target size.
   - **Hierarchy:** Does the main action stand out? Is related content grouped?
   - **Consistency:** Do spacing, type, and components match the rest of the product?
   - **Responsive:** Does anything overflow, get cut off, or become too small to tap?
5. **Rank by harm to the user.** High means they cannot finish the task. Medium means it is slow or confusing. Low means polish. Report at most 10.
6. **Fix only if asked.** After fixing, check the same screen again.

## Output

Start with the verdict. Each problem gets where it is, why it matters, and the fix.

```text
Can ship after fixing 1 high problem.

High  Checkout, Pay button: contrast is 2.1:1, needs 4.5:1. Low-vision users may not read it.
      Fix: use `--color-primary-700`. Rule: WCAG 1.4.3.
Med   Form errors only show after submit, so people fill the whole form twice.
      Fix: validate on blur. Rule: help users recover from errors.

Not checked: tablet width, screen reader.
```

Separate measured facts from your opinion. Mark taste as "opinion".

## How to write

Write like a senior teammate helping someone who is new to frontend. Explain each term in plain words the first time. Lead with the result, name real elements, and skip praise and recaps.
