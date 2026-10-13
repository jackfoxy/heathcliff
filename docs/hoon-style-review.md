# Hoon style compliance review

Reviewed 2026-10-08 against
[/hoon-style-guide/SKILL.md](/mnt/mars/gitrepos/foxy-skills/hoon-style-guide/SKILL.md).

Result: the repository does not fully comply. This is a review; application
and dependency source files were not changed.

Scope: all 93 Hoon files (22,816 lines), including uncommitted additions,
tests, marks, shared urui code, and vendored Markdown. Every file received
lexical checks. Manual inspection covered Heathcliff's Hoon implementation,
shared Hoon helpers, marks, and matching constructs in dependencies and tests.
Embedded JavaScript/CSS was counted for line length; Hoon naming and rune
rules do not apply to those languages. This is not a functional or security
audit of the JavaScript bundles or WASM.

## Findings

1. **Recursive products passed directly to wet gates** — guide section 9.
   [heathcliff-perm.hoon:228](../desk/lib/heathcliff-perm.hoon#L228)
   passes `$(nam t.nam)` directly to `weld` in `+tally`. Prefer a standard
   join over the already constructed list of tapes, or bind the recursive
   product to a typed face before concatenation. The vendored Markdown
   encoder repeats this pattern at
   [markdown.hoon:2704](../desk/lib/markdown.hoon#L2704), 2726, and 2740.
   These violate the prescribed discipline; this review did not reproduce
   a compilation failure at those sites.

2. **Collection operations use explicitly discouraged patterns** — section 5,
   pattern 2. [urui-shell tests:257](../desk/tests/lib/urui-shell.hoon#L257)
   and line 262 use `?=(^ (skim ...))` for existence tests; use `lien`.
   [markdown.hoon:294](../desk/lib/markdown.hoon#L294) filters with `skim`,
   maps with `turn`, and asserts the filtered shape with `?>`; use `murn`
   with the shape check inside its gate. Markdown lines 2061, 2133, and
   2198 append one element with `(weld blanks ~[next])`; use `snoc`.

3. **Short helpers with one caller add unnecessary arms** — section 4.
   [heathcliff-web.hoon:202](../desk/lib/heathcliff-web.hoon#L202),
   `+clay-host`, only constructs an editor cell and is referenced once,
   at line 198. Inline the cell there. `+shortcuts` at line 96 similarly
   constructs a single-entry list used once by `+config`.
   [heathcliff-perm.hoon:39](../desk/lib/heathcliff-perm.hoon#L39),
   `+pear`, is a four-line helper called only at line 177, outside a
   conditional branch; its scry can be bound in that caller. Required
   Gall lifecycle and mark-interface arms are not unnecessary helpers.

4. **Identical switch branches are not grouped** — section 6, anti-pattern 3.
   [heathcliff-clay.hoon:57](../desk/lib/heathcliff-clay.hoon#L57) repeats
   the HTML MIME result for `%html`, `%hymn`, `%urb`, and `%snip`.
   The JPEG, Ogg, and jam/noun branches repeat the same pattern at lines
   68, 77, and 94. Group each set with `?(...)`.
   `+kin` lines 287–288 also has identical noun-dependency results and can
   include `%txt-diff` in the existing group.

5. **Boolean discriminants use `?-`** — section 5, pattern 7.
   [heathcliff-clay.hoon:439](../desk/lib/heathcliff-clay.hoon#L439),
   `+hunks`, switches on `%&`/`%|`; use a shape-refining `?:` and continue
   with the other branch. The same pattern appears in
   [test.hoon:40](../desk/lib/test.hoon#L40), 50, 76, and 138, and in
   the text mark's diff code. Preserve payload refinement when changing
   these tagged unions.

6. **Repeated list peeling instead of a shape test** — section 5, pattern 8.
   [urui-shell.hoon:984](../desk/lib/urui-shell.hoon#L984),
   `+initial-status`, walks through successive `rest` bindings and `?~`
   tests to reach the third status. After handling the empty list and
   editor case, test the three-element minimum shape directly and select
   the third label, retaining the first-label fallback for shorter lists.

7. **Missing explicit result types and inconsistent arm documentation** —
   sections 3 and 5. For example,
   [docket.hoon:167](../desk/lib/docket.hoon#L167), `+href`, and its
   `+glob-reference`, `+charge`, and `+chad` JSON encoders omit `^- json`.
   Many mark conversion gates likewise omit explicit products. Arm
   descriptions in older support code are above the arm or appended on
   the declaration rather than indented below it, e.g.
   [cram.hoon:2](../desk/lib/cram.hoon#L2) and
   [test.hoon:4](../desk/lib/test.hoon#L4).
   There are 525 `++` declarations not immediately preceded by a standalone
   `::`. Seven are in Heathcliff files: app lines 308–310, web line 13,
   Markdown wrapper line 5, and line 3 of each new API/Markdown test file.

8. **Lines exceed 80 characters** — section 2. There are 131 across Hoon
   files, including comments and embedded source. Of these, 115 are in
   vendored Markdown, four in support libraries, one in the Hoon mark's
   embedded JavaScript, and ten in Heathcliff:
   [heathcliff-api.hoon:61](../desk/lib/heathcliff-api.hoon#L61) and
   [heathcliff-web.hoon:489](../desk/lib/heathcliff-web.hoon#L489), 1556,
   1561, 1563, 1581, 1592, 1607, 1813, 2068. The API expression is Hoon;
   the nine web lines are embedded CSS/JavaScript. Wrap each in its own
   language's syntax.

## Coverage and verification

| File group | Files | Lines over 80 | `++` without preceding `::` |
| --- | ---: | ---: | ---: |
| Heathcliff application, libraries, tests | 13 | 10 | 7 |
| urui libraries, types, tests | 15 | 0 | 0 |
| Vendored Markdown library and types | 2 | 115 | 156 |
| Marks | 52 | 1 | 345 |
| Other support libraries and types | 11 | 4 | 17 |
| Total | 93 | 131 | 525 |

The separator counts are literal formatting checks, not counts of runtime
defects. No tab characters or uppercase/underscore `++`/`+$` declaration
names were found. The agent's pending-state paths use `=^`/`=.` without
redundant `this(state state)` write-back. Existing typed intermediate
results in `+scan`, `+browse-entries`, and `+browse-paths` follow the guide's
wet-gate precautions and should be retained.

`git diff --check` passed for the existing tracked changes. Tests were not
rerun because this review changed no executable code; prior passing tests
do not establish style compliance.

Markdown is documented as an unchanged upstream copy in
[vendor.md](vendor.md); urui ownership is recorded in
[urui-changes.md](urui-changes.md). Their violations are included here.
Any later cleanup should record dependency modifications accurately rather
than continuing to describe edited vendor files as unchanged.
