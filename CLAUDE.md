# CLAUDE.md

Notes for AI assistants working in `u-observers`.

## How to work in this repo

### 1. Think before coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

- State assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them — don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity first

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes,
simplify.

### 3. Surgical changes

**Touch only what you must. Clean up only your own mess.**

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it — don't delete it.
- Remove imports/variables/functions that _your_ changes orphaned. Don't
  remove pre-existing dead code unless asked.

The test: every changed line should trace directly to the user's request.

### 4. Goal-driven execution

**Define success criteria. Loop until verified.**

Turn vague tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step work, state a brief plan with a verification check per step.

---

## What this is

`u-observers` is a small, dependency-free implementation of the observer
pattern, organized under `lib/micro/observers/`. The core (`require
'u-observers'`) gives any object an `#observers` collection
(`Micro::Observers::Set`) for attaching/detaching subscribers and notifying
them of events — built from cohesive pieces: `Set`, `Event` (+ `Event::Names`),
`Broadcast`, `Subscribers`, and `Utils`. On top of that sit two **optional**
Rails integrations that are loaded only when explicitly required:

- `require 'u-observers/for/active_model'` → `Micro::Observers::For::ActiveModel`
- `require 'u-observers/for/active_record'` → `Micro::Observers::For::ActiveRecord`

ActiveRecord/ActiveModel are **not** runtime dependencies — they're brought in
only by the host app (and by the test appraisals). The public API is small and
widely used downstream, so behavior changes — especially anything affecting the
public API or the supported `ruby` / `activerecord` matrix — are highly visible.

## Running tests

```bash
bundle exec rake test                  # default suite, current bundle (no activerecord)
bundle exec appraisal <name> rake test # one Rails appraisal (see Appraisals)
bundle exec rake matrix                # full local matrix for the active Ruby
```

`bin/setup` reinstalls and refreshes appraisals; `bin/matrix` reinstalls then
runs `rake matrix`. CI runs the baseline suite plus the per-Rails appraisals
across the Ruby × ActiveRecord grid (`.github/workflows/ci.yml`). Tests are the
success criterion for any behavior change — write or update a test first, then
make it pass (rule 4).

How the suite picks up ActiveRecord (`test/test_helper.rb`):

- The baseline `rake test` run has **no** activerecord, so the integration
  tests are skipped. Each Rails appraisal adds `activerecord` + `sqlite3`, which
  flips `ACTIVERECORD_AVAILABLE` on and exercises the `For::ActiveRecord` /
  `For::ActiveModel` tests.
- `test_helper` must `require 'logger'` **before** `require 'active_record'` —
  ActiveSupport <= 6.1 references `::Logger` at load time and newer
  `concurrent-ruby` no longer requires it first. Don't remove that line; the
  Rails 6.x appraisals fail without it.

Running the matrix locally (multiple Rubies via mise, see `.tool-versions`):

- Clear `Gemfile.lock` / `gemfiles/*.lock` between Rubies — a stale `BUNDLED
  WITH` from another Ruby breaks resolution.
- Pin a 2.x bundler per Ruby when needed: bare `bundle` can grab an incompatible
  4.x on Ruby 3.1 (and 2.7/3.0 need bundler `2.4.22`, as CI does).

## README is part of every change

Both READMEs are user-facing and **must stay in sync with each other**:

- **`README.md`** (English) and **`README.pt-BR.md`** (Portuguese) — any
  documented-API or compatibility change goes into **both** in the same commit.
- The **Compatibility** table near the top references the supported Ruby ×
  ActiveRecord bounds. Update it when the matrix moves.
- If you change a documented API, update the relevant Usage section (and its
  table-of-contents entry) in both files.

There is no `CHANGELOG.md` in this repo — release notes live in
[GitHub Releases](https://github.com/serradura/u-observers/releases) (the
gemspec `changelog_uri` points there).

## Bumping the version

1. Edit `lib/micro/observers/version.rb` — change `Micro::Observers::VERSION`.
   Follow [SemVer](https://semver.org/): patch for fixes, minor for additive
   user-visible changes, major for breaking changes.
2. Update the **Compatibility** table in `README.md` and `README.pt-BR.md`: if
   supported Ruby / ActiveRecord bounds changed, add a new row; otherwise bump
   the existing row's version label.
3. If the supported matrix moved, double-check that the Compatibility table, the
   CI matrix (`.github/workflows/ci.yml`), and the `Appraisals` file all reflect
   the new bounds.

Don't tag, push, `gem release`, or draft the GitHub Release — humans do that.
