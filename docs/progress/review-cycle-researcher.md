---
feature: "review-cycle"
team: "plan-product"
agent: "researcher"
phase: "research"
status: "complete"
last_action: "Completed full investigation of all remaining P2/P3 items"
updated: "2026-02-18T12:00:00Z"
---

# Research Findings: P2/P3 Roadmap Prioritization

## Summary

Investigated all 7 remaining roadmap items (4 P2, 3 P3) against the current codebase state. The three SKILL.md files total 1,269 lines with ~126 lines of verbatim duplication across them. All P1 dependencies are satisfied. Identified one stale README reference and one roadmap gap not currently tracked. Recommend P2-05 Content Deduplication as the next item to spec -- it has the best effort-to-impact ratio and directly reduces operational cost on every invocation.

## Key Facts

### Current State of the Codebase

- **3 SKILL.md files**: plan-product (376 lines), review-quality (431 lines), build-product (462 lines). Total: 1,269 lines.
- **Shared Principles section**: Duplicated identically in all 3 files, starts at lines 141/151/159 respectively.
- **Communication Protocol section**: Duplicated identically in all 3 files, starts at lines 169/181/189 respectively.
- **All P1 items complete**: project-bootstrap, concurrent-write-safety, state-persistence, stack-generalization.
- **All completed P2 items**: cost-guardrails (P2-01), artifact-format-templates (P2-06).
- **Stack generalization is fully done**: No hardcoded Laravel/PHP references remain in SKILL.md files. Stack hints are properly externalized.
- **Artifact templates are in place**: `docs/specs/_template.md`, `docs/progress/_template.md`, `docs/architecture/_template.md` all exist and are referenced in Setup sections.
- **Plugin system**: Simple plugin.json manifest with marketplace.json. No shared-file injection mechanism observed.

### Stale Reference Found

**README.md line 199**: Still says "The default is Laravel/PHP -- adjust for your stack in the spawn prompts" -- but P1-03 Stack Generalization removed all hardcoded stack references. This is misleading.

## Item-by-Item Analysis

### P2-02 Skill Composability (Large effort, dependency: state-persistence DONE)

**What it is**: A `/run-workflow` skill that chains plan -> build -> review with YAML workflow definitions.

**Assessment**: The dependency (state-persistence) is satisfied, so this is technically unblocked. However, the current handoff between skills already works via artifact files (specs, progress, roadmap). The three skills are invoked manually, and users control timing and review between steps. Automating this chain introduces significant complexity (error recovery, mid-workflow failure, quality gate enforcement across skill boundaries) for a convenience improvement.

- **Impact**: Medium. Power users may benefit, but the manual workflow is functional.
- **Effort**: Large. Requires a new skill, a workflow definition format, handoff protocol formalization, and cross-skill error handling.
- **Risk if deferred**: Low. Users can chain skills manually.
- **Confidence**: High (based on direct codebase reading).
- **Recommendation**: Defer. Not the next priority.

### P2-03 Progress Observability (Medium effort, dependency: state-persistence DONE)

**What it is**: A status summary command and end-of-session summaries for visibility into running teams.

**Assessment**: The checkpoint protocol (P1-02) already writes structured progress files. The cost summary (P2-01) already writes invocation summaries. The missing piece is a cheap "read all checkpoints and summarize" command. This is largely a read-only operation -- it reads existing files and produces a consolidated view. The SKILL.md files already have a "resume from checkpoint" mechanism (empty-args mode reads checkpoint files). A status subcommand would be a lightweight extension.

- **Impact**: Medium-high. Users currently have no way to check team progress without reading individual checkpoint files. The tmux pane approach is available but chaotic for 5 agents.
- **Effort**: Small-medium. It's mostly reading and summarizing existing files. Could be a new argument mode in existing skills or a standalone utility.
- **Risk if deferred**: Low-medium. Users manage without it, but visibility gaps reduce trust in the system.
- **Confidence**: High.
- **Recommendation**: Moderate priority. Worth doing but not the most impactful next step.

### P2-04 Automated Testing Pipeline (Large effort, no dependencies)

**What it is**: Structural validation scripts for SKILL.md files, contract tests for shared content consistency, CI integration.

**Assessment**: This is fundamentally important for project health, but the project is still young (3 SKILL.md files, ~14 roadmap items). The risk of undetected regressions is real but manageable at the current scale. The artifact-format-templates (P2-06) already created structured formats with YAML frontmatter that would be testable. The content deduplication item (P2-05) would significantly change what needs testing -- doing testing first means rewriting tests after dedup.

- **Impact**: High for long-term quality. Low for immediate user value.
- **Effort**: Large. Requires markdown/YAML parsing, cross-file consistency checks, CI setup.
- **Risk if deferred**: Medium. Manual review has worked so far, but errors become more likely as the codebase grows.
- **Confidence**: High.
- **Recommendation**: Important but should follow P2-05. Doing dedup first means fewer test targets and more stable content to validate.

### P2-05 Content Deduplication (Medium effort, no dependencies)

**What it is**: Extract the ~126 lines of duplicated Shared Principles and Communication Protocol from 3 SKILL.md files into a single authoritative location.

**Assessment**: This is the highest-impact, most actionable item remaining. The duplication is verifiably present (confirmed by line-by-line analysis). Each skill invocation loads one SKILL.md into every agent's context -- with 5 Opus agents on `/plan-product`, that's 5x the duplicated content across the team. Eliminating ~126 lines per file reduces per-invocation token cost and eliminates the maintenance burden of syncing 3 copies.

The roadmap item identifies three approaches:
1. Extract to CLAUDE.md (ideal -- agents inherit it automatically)
2. Extract to a shared reference file (requires SKILL.md to reference it)
3. Validated duplication via CI (pragmatic fallback)

Based on my investigation, there is no shared-file injection mechanism in the plugin system (plugin.json is a simple manifest). However, CLAUDE.md is loaded into every Claude Code conversation automatically. If the shared content is in a project-level CLAUDE.md, agents get it without per-skill duplication. This is a real, achievable path.

**Key consideration**: The README notes that SKILL.md files should be self-contained for portability. Option 1 (CLAUDE.md) works for projects that use the plugin, but a standalone SKILL.md copied to another project would lose the shared principles. The spec should address this tradeoff.

- **Impact**: High. Direct token cost savings on every invocation. Eliminates maintenance burden. Reduces SKILL.md complexity.
- **Effort**: Medium. Well-defined scope -- the content to extract is known, the destination is clear.
- **Risk if deferred**: Medium. Every edit to shared principles requires 3 manual edits. Divergence risk increases over time.
- **Confidence**: High.
- **Recommendation**: This should be the NEXT item to spec. Best effort-to-impact ratio.

### P3-01 Custom Agent Roles (Large effort, dependency: stack-generalization DONE)

**What it is**: Allow users to define custom agent roles (e.g., Data Engineer, ML Engineer) without editing SKILL.md files.

**Assessment**: Dependency satisfied. However, the current agent roles cover the most common SaaS development scenarios well. This is a power-user feature that adds significant complexity to the skill orchestration system -- skills would need to discover, parse, and compose teams from external role definitions at runtime. The spawn prompts in SKILL.md are already ~50 lines per role, tightly integrated with the orchestration flow.

- **Impact**: Medium for niche users. Most users are well-served by the default roles.
- **Effort**: Large. Significant SKILL.md refactoring, new file format, dynamic team composition logic.
- **Risk if deferred**: Low. Users who need custom roles can edit SKILL.md directly (README documents this).
- **Confidence**: High.
- **Recommendation**: Defer. High effort, niche impact.

### P3-02 Onboarding Wizard (Small effort, no dependencies)

**What it is**: A `/setup-project` skill that auto-detects stack, creates docs structure, and writes a starter CLAUDE.md.

**Assessment**: The existing skills already handle directory creation in their Setup sections (Step 1 in every SKILL.md creates docs directories if missing). The onboarding wizard would front-load this setup and add CLAUDE.md generation. This becomes more valuable if P2-05 (deduplication) puts shared principles in CLAUDE.md -- the onboarding wizard could generate the CLAUDE.md with the right shared content.

- **Impact**: Medium for new users. Low for existing users.
- **Effort**: Small. Single-agent skill with no team spawning.
- **Risk if deferred**: Low. Existing Setup sections handle the basics.
- **Confidence**: Medium. Value depends on P2-05 outcome.
- **Recommendation**: Consider after P2-05 lands, especially if shared principles move to CLAUDE.md.

### P3-03 Contribution Guide (Small effort, no dependencies)

**What it is**: Architecture overview and step-by-step instructions for contributors.

**Assessment**: Useful for open-source adoption but not blocking any functionality. The existing README covers usage well. The ADR-001 and roadmap index provide some architectural context. A full contribution guide would be most valuable after the codebase stabilizes -- doing it now means rewriting it after dedup and testing changes.

- **Impact**: Low-medium. Useful for contributors, not for end users.
- **Effort**: Small. Documentation-only.
- **Risk if deferred**: Low. The project is still in active development; premature documentation will need updates.
- **Confidence**: High.
- **Recommendation**: Defer until P2-05 and P2-04 are done. Write it when the architecture is stable.

## Identified Gaps

### Gap 1: Stale README Content

README.md line 199 says "The default is Laravel/PHP -- adjust for your stack in the spawn prompts" but stack generalization (P1-03) removed all hardcoded references. This should be corrected to describe the stack-hints system.

**Recommendation**: Fix as a cleanup task (not a roadmap item). Small, isolated change.

### Gap 2: No Error Recovery Testing

The 3 SKILL.md files all have "Failure Recovery" sections (unresponsive agent, skeptic deadlock, context exhaustion), but there's no evidence these recovery paths have been exercised. This is adjacent to P2-04 (automated testing) but distinct -- it's about validating the behavioral contracts, not structural integrity.

**Recommendation**: Note this as a sub-concern of P2-04 when it's specced. Not a separate roadmap item.

### Gap 3: Plugin Versioning Strategy

The plugin.json and marketplace.json both hardcode version "1.0.0". There's no versioning strategy for when SKILL.md changes break backward compatibility (e.g., if dedup changes how shared principles are loaded). Users who pinned to a version would get stuck on old skills.

**Recommendation**: Consider adding a lightweight versioning note to the contribution guide (P3-03). Not urgent enough for a standalone roadmap item.

## Recommended Priority Ordering

Based on effort, impact, dependencies, and sequencing logic:

| Rank | Item | Rationale |
|------|------|-----------|
| 1 | **P2-05 Content Deduplication** | Best effort-to-impact. Reduces cost, eliminates maintenance burden. No dependencies. Should be done before testing (P2-04) to stabilize what's being tested. |
| 2 | **P2-04 Automated Testing Pipeline** | Important for project health. Should follow dedup so tests validate the final structure. |
| 3 | **P2-03 Progress Observability** | Quality-of-life improvement. Well-scoped, medium effort. |
| 4 | **P3-02 Onboarding Wizard** | Small effort, good synergy with P2-05 if shared principles move to CLAUDE.md. |
| 5 | **P2-02 Skill Composability** | Large effort, convenience feature. Manual workflow works. |
| 6 | **P3-03 Contribution Guide** | Write after architecture stabilizes. |
| 7 | **P3-01 Custom Agent Roles** | Large effort, niche impact. Defer. |

## Recommendation: Next Item to Spec

**P2-05 Content Deduplication** should be specced next. It has:
- The best effort-to-impact ratio among remaining items
- No blocking dependencies
- A clear, well-defined scope (the duplicated content is known and measurable)
- Positive sequencing effects (stabilizes structure for P2-04 testing, enables P3-02 onboarding)
- Direct cost savings on every skill invocation

## Open Questions

1. Does Claude Code's CLAUDE.md loading work for plugin-installed projects, or only for repos with a CLAUDE.md committed to the project root? This affects whether Option 1 (extract to CLAUDE.md) is viable for all users.
2. Should the portability constraint (SKILL.md being self-contained) be relaxed for plugin-installed users? The plugin marketplace already implies a dependency on the plugin infrastructure.
3. Is there appetite for a "P2-05.5" item that fixes the stale README content, or should it be bundled with the next implementation cycle?
