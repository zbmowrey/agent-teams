# Project Conventions

## What This Is

A Claude Code plugin marketplace (`wizards`) containing the `conclave` plugin — 7 skills that spawn coordinated AI agent teams for planning, building, and operating SaaS products.

## Tech Stack

- Shell scripts (bash) for validators and CI
- Markdown (SKILL.md files) for skill definitions — Claude Code reads these as static markdown
- YAML frontmatter for metadata in roadmap, spec, progress, and architecture files
- No application runtime — this is a plugin/tooling project, not a web app

## Project Structure

```
wizards/
  .claude-plugin/marketplace.json    # Marketplace catalog
  plugins/conclave/
    .claude-plugin/plugin.json       # Plugin manifest (v1.0.0)
    skills/
      plan-product/SKILL.md          # Product planning (Hub-and-Spoke)
      build-product/SKILL.md         # Implementation (Hub-and-Spoke)
      review-quality/SKILL.md        # Quality & ops (Hub-and-Spoke)
      setup-project/SKILL.md         # Project bootstrap (Single-Agent)
      draft-investor-update/SKILL.md # Investor updates (Pipeline)
      plan-sales/SKILL.md            # Sales strategy (Collaborative Analysis)
      plan-hiring/SKILL.md           # Hiring plans (Structured Debate)
  scripts/
    validate.sh                      # Runs all validators
    validators/
      skill-structure.sh             # A1-A4: frontmatter, sections, spawn defs, markers
      skill-shared-content.sh        # B1-B3: principles drift, protocol drift, authoritative source
      roadmap-frontmatter.sh         # C1-C2: roadmap file conventions
      spec-frontmatter.sh            # D1: spec file conventions
      progress-checkpoint.sh         # E1: checkpoint file conventions
  docs/
    roadmap/                         # Prioritized backlog (_index.md + per-item files)
    specs/                           # Feature specifications (per-feature dirs)
    progress/                        # Agent progress checkpoints and session summaries
    architecture/                    # ADRs and design docs
    stack-hints/                     # Framework-specific agent guidance (laravel.md)
```

## Skill Patterns

| Pattern | Skills | Key Traits |
|---------|--------|------------|
| Hub-and-Spoke | plan-product, build-product, review-quality | Lead orchestrates; agents work separate concerns; skeptic gate |
| Pipeline | draft-investor-update | Sequential stages with quality gates |
| Collaborative Analysis | plan-sales | Parallel research, cross-referencing, lead synthesis, dual-skeptic |
| Structured Debate | plan-hiring | Cases built, cross-examined, synthesized, dual-skeptic |
| Single-Agent | setup-project | No team, deterministic pipeline |

## Shared Content Architecture

- **Authoritative source**: `plan-product/SKILL.md` owns Shared Principles and Communication Protocol
- **Markers**: `<!-- BEGIN SHARED: principles -->` / `<!-- END SHARED: principles -->` (and `communication-protocol`)
- **Drift detection**: `scripts/validators/skill-shared-content.sh` (B1-B3 checks)
- **Per-skill variation**: Skeptic name in Communication Protocol table differs per skill (16 sed normalizations in validator)
- **Single-agent exclusion**: Skills with `type: single-agent` in frontmatter are skipped by shared content checks
- **ADR-002**: Documents the deduplication strategy. Extraction threshold: "when skill count exceeds 8"

## Validation

Run all validators:
```bash
bash scripts/validate.sh
```

Check categories:
- **A-series** (skill-structure.sh): YAML frontmatter, required sections, spawn definitions, shared content markers
- **B-series** (skill-shared-content.sh): Shared principles/protocol drift, authoritative source verification
- **C-series** (roadmap-frontmatter.sh): Roadmap file frontmatter and filename conventions
- **D-series** (spec-frontmatter.sh): Spec file frontmatter
- **E-series** (progress-checkpoint.sh): Checkpoint file frontmatter

## Key ADRs

- **ADR-001**: Roadmap file structure (one file per item, YAML frontmatter)
- **ADR-002**: Content deduplication strategy (validated duplication with HTML markers, extraction at >8 skills)
- **ADR-003**: Onboarding wizard single-agent pattern

## Development Guidelines

- SKILL.md files are the product. Every edit to a multi-agent SKILL.md must keep shared content in sync with the authoritative source (plan-product).
- Run `bash scripts/validate.sh` before committing. All checks must pass.
- Roadmap items use frontmatter with `status`, `priority`, `category`, `effort`, `impact`, `dependencies`.
- Specs follow `docs/specs/_template.md`. Progress files follow `docs/progress/_template.md`. ADRs follow `docs/architecture/_template.md`.
- Business skills are larger than engineering skills (avg 1160 vs 434 lines) due to output templates, user data templates, and domain-specific formats. This is expected.
- The Skeptic role is non-negotiable in every multi-agent skill. Never remove or weaken it.

## Current Roadmap Status

- **P1**: All 4 items complete (bootstrap, write safety, state persistence, stack generalization)
- **P2**: 5/8 complete. Next: P2-07 (shared content extraction), then P2-08 (plugin organization)
- **P3**: 4/19 complete. 15 items not started across engineering, business, and documentation categories.
- P2-02 (Skill Composability) is parked per RC5 directive.
- P2-08 depends on P2-07 (shared content coupling is the binding constraint).
