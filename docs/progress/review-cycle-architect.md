---
feature: "review-cycle"
team: "plan-product"
agent: "architect"
phase: "complete"
status: "complete"
last_action: "Architecture assessment approved by Skeptic with notes"
updated: "2026-02-18T17:00:00Z"
---

# Architecture Assessment: Remaining P2 Items

## Overview

Assessment of the four remaining P2 roadmap items (P2-02 through P2-05) from an architectural perspective. The analysis covers complexity, risk, dependencies, implementation readiness, and recommended approach for each item.

### Current System Architecture

The Council of Wizards project is a Claude Code plugin consisting of:
- **3 SKILL.md files** (~375-465 lines each) that orchestrate multi-agent teams
- **Plugin structure**: `plugins/conclave/` with a `.claude-plugin/plugin.json` manifest
- **Documentation system**: `docs/` with `roadmap/`, `specs/`, `progress/`, `architecture/`, `stack-hints/` directories
- **No executable code**: The entire system is markdown-driven orchestration instructions consumed by Claude Code's agent framework

Key architectural characteristics:
- Skills are self-contained markdown documents with YAML frontmatter
- Agent coordination is file-based: agents write to role-scoped progress files, leads aggregate
- Quality gates are enforced by Skeptic agents (never bypassed)
- State persistence uses checkpoint files in `docs/progress/`
- Shared Principles (~50 lines) and Communication Protocol (~50 lines) are duplicated across all 3 SKILL.md files

---

## P2-02: Skill Composability

**Effort**: Large | **Impact**: Medium | **Dependencies**: state-persistence (P1-02, complete)

### Architectural Complexity: HIGH

This is the most architecturally complex remaining item. It introduces a new abstraction layer:

**Components required:**
1. A new `/run-workflow` skill (new SKILL.md file)
2. A workflow definition format (YAML files in `docs/workflows/`)
3. A handoff protocol formalizing the data contract between skill outputs and inputs
4. Workflow state tracking (which step is current, outcomes of prior steps)

**Interactions:**
- The workflow skill must invoke existing skills sequentially. In Claude Code's plugin model, this means the workflow orchestrator agent must trigger skill execution for each step. The mechanism for one skill to programmatically invoke another skill within Claude Code is not clearly documented.
- Each step's Skeptic must still operate independently -- the workflow cannot suppress quality gates.
- Error states (Skeptic rejection, agent crash, context exhaustion) must pause the workflow with resumable state.

### Risk Assessment: HIGH

1. **Platform constraint risk**: Claude Code's plugin/skill system may not support skill-to-skill invocation. If skills can only be triggered by user input (slash commands), a `/run-workflow` skill cannot programmatically call `/plan-product` then `/build-product`. This is a potential showstopper that requires platform research.
2. **Context window risk**: A workflow orchestrator that monitors multiple sequential skill invocations will accumulate enormous context. Five Opus agents per step, across 3 steps, could exhaust context.
3. **Complexity ceiling**: The roadmap correctly notes "keep workflows simple (linear sequences)." Even linear workflows introduce substantial state management. Conditional branching should remain firmly out of scope.
4. **Quality gate integrity**: If the workflow auto-advances past a Skeptic gate, the core quality guarantee is broken.

### Implementation Readiness: LOW

The roadmap description is conceptually sound but lacks critical platform-level answers:
- Can a skill invoke another skill programmatically?
- How does workflow state persist across skill invocations (each skill invocation may be a fresh context)?
- What is the handoff data contract format?

**Needs research** before speccing: A focused investigation into Claude Code's plugin API capabilities for skill chaining.

### Recommended Approach

1. **Defer** until P2-03 (Progress Observability) and P2-05 (Content Deduplication) are complete -- both provide infrastructure this feature benefits from.
2. **Research first**: Before speccing, investigate Claude Code's mechanism for one skill to trigger another. If not supported, re-scope to a "manual workflow checklist" pattern (skill writes "next step" guidance, user invokes manually).
3. **Start with handoff protocol only**: Even without a workflow skill, formalizing the data contract between plan-product output and build-product input is independently valuable and low-risk.

---

## P2-03: Progress Observability

**Effort**: Medium | **Impact**: Medium | **Dependencies**: state-persistence (P1-02, complete)

### Architectural Complexity: LOW

This is the simplest remaining item. It extends existing infrastructure rather than creating new abstractions.

**Components required:**
1. A "status" argument handler in each skill's "Determine Mode" section
2. File-reading logic that aggregates checkpoint files from `docs/progress/`
3. A summary output format (human-readable, optionally machine-parseable)

**Interactions:**
- Reads existing checkpoint files -- no new file formats needed
- Does not spawn agents (the whole point is lightweight status checking)
- Minimal changes to SKILL.md (add a mode to Determine Mode, add summarization logic)

### Risk Assessment: LOW

1. **Checkpoint format dependency**: Relies on agents actually writing consistent checkpoint files. If checkpoint discipline is poor, the status view is unreliable. This is a people/process risk, not an architecture risk.
2. **Stale data**: Checkpoint files are written by agents during execution. Between checkpoints, the status view may be out of date. This is inherent to a file-based state model and acceptable.
3. **End-of-session summary**: Already partially implemented -- build-product's orchestration flow step 7 mentions writing to `{feature}-summary.md`. Formalizing this is low-risk.

### Implementation Readiness: HIGH

The roadmap description is clear and complete. The checkpoint format already exists in all 3 SKILL.md files. The progress template exists (`docs/progress/_template.md`). The implementation is mostly additive -- a new mode in Determine Mode plus summarization instructions.

### Recommended Approach

1. **Implement early** -- this is the lowest-risk, highest-readiness item.
2. **Add `status` argument to all 3 skills**: `/plan-product status`, `/build-product status`, `/review-quality status`
3. **No new SKILL.md file needed**: The status mode is a lightweight handler within each existing skill.
4. **End-of-session summary**: Formalize the cost summary and team progress summary that team leads already write, ensuring they follow the progress template.

---

## P2-04: Automated Testing Pipeline

**Effort**: Large | **Impact**: High | **Dependencies**: None

### Architectural Complexity: MEDIUM

Introduces external tooling (scripts, CI) but the architecture is straightforward.

**Components required:**
1. A validation script (Node.js or Python) that parses SKILL.md and roadmap files
2. Structural checks: YAML frontmatter, required sections, teammate name cross-references
3. Consistency checks: Shared Principles and Communication Protocol match across skills
4. CI configuration (GitHub Actions workflow)

**Interactions:**
- Operates on static markdown files -- no agent interaction, no Claude API needed
- Validates structural contracts that are currently implicit (section names, frontmatter fields)
- Cross-validates the 3 SKILL.md files against each other for consistency

### Risk Assessment: LOW-MEDIUM

1. **Brittle parsing**: Markdown is not a structured format. A validation script that parses section headers is fragile against formatting changes. The script must be tolerant of minor variations (extra blank lines, different heading levels).
2. **Maintenance burden**: Every structural change to SKILL.md requires updating the validation script. If the tests are too strict, they become an impediment to iteration.
3. **False sense of security**: Structural validation catches formatting errors but cannot validate behavioral correctness. An agent that follows the format but misunderstands the instructions will pass all tests.
4. **Technology choice**: The project has no executable code today. Introducing a Node.js or Python script adds a runtime dependency and requires a `package.json` or `requirements.txt`.

### Implementation Readiness: MEDIUM

The roadmap description defines clear structural checks. However:
- No decision on language (Node.js vs. Python vs. shell)
- No decision on markdown parsing library
- The "contract tests" (consistency between skills) need specific assertions defined
- The P2-05 content deduplication outcome affects whether consistency tests check for identical content or shared file references

### Recommended Approach

1. **Implement after P2-05** -- if content is deduplicated, consistency checks become simpler (verify reference exists vs. verify identical content across 3 files).
2. **Start with YAML frontmatter validation** -- this is the most structured, least brittle check.
3. **Use a simple shell script with `yq`** for YAML validation, avoiding a full runtime dependency. Graduate to a proper language if checks grow complex.
4. **GitHub Actions CI**: A single workflow file (`.github/workflows/validate.yml`) that runs on PRs touching `plugins/` or `docs/`.
5. **Keep checks minimal initially**: Frontmatter validation, required section headers, cross-skill consistency for shared sections. Resist the urge to validate content semantics.

---

## P2-05: Content Deduplication

**Effort**: Medium | **Impact**: Medium | **Dependencies**: None

### Architectural Complexity: MEDIUM

Touches the core architectural decision of skill self-containment.

**Components required (Option A -- CLAUDE.md extraction):**
1. Extract Shared Principles and Communication Protocol to `CLAUDE.md` or `plugins/conclave/shared/principles.md`
2. Replace duplicated content in each SKILL.md with a brief reference note
3. Verify Claude Code's context mechanism loads the shared file for all skill invocations

**Components required (Option B -- Validated duplication):**
1. Keep content duplicated in all 3 SKILL.md files
2. Add a CI check (P2-04) that verifies the duplicated sections are byte-identical

### Risk Assessment: MEDIUM

1. **CLAUDE.md loading behavior**: If shared content is moved to CLAUDE.md, it is loaded into every Claude Code conversation (not just skill invocations). This may add unnecessary context for non-skill interactions. Need to verify whether plugin-scoped CLAUDE.md files are supported.
2. **Portability regression**: The current architecture is intentionally self-contained -- each SKILL.md works without external files. Option A breaks this. If a user copies a single SKILL.md to another project, it loses the shared principles.
3. **Token cost impact**: The duplicated content is ~100 lines. With 5 agents reading the skill file, that's ~500 redundant reads per invocation. Deduplication saves tokens, but only if the shared file isn't also loaded redundantly.
4. **Partial extraction risk**: If only some shared content is extracted, maintainers must remember which sections are shared vs. skill-specific. This creates a new category of consistency bug.

### Implementation Readiness: MEDIUM

The roadmap presents two clear options. The decision between them depends on:
- Whether Claude Code supports plugin-scoped CLAUDE.md files (or only project-root CLAUDE.md)
- Whether the self-containment principle is negotiable
- Whether P2-04 testing infrastructure is available for Option B

### Recommended Approach

1. **Research Claude Code's CLAUDE.md loading behavior first** -- does it support plugin-scoped configuration files? This determines Option A feasibility.
2. **Prefer Option B (validated duplication) initially** -- it preserves portability and is lower risk. The maintenance burden is manageable with CI enforcement from P2-04.
3. **If Option A is feasible**, extract to a shared file within the plugin directory (`plugins/conclave/shared/`) rather than project-root CLAUDE.md, to avoid polluting non-skill conversations.
4. **Implement after P2-04** -- Option B directly depends on having CI validation in place.

---

## Recommended Implementation Order

Based on dependencies, risk, and readiness:

| Priority | Item | Rationale |
|----------|------|-----------|
| 1st | **P2-03 Progress Observability** | Lowest complexity, highest readiness, no blockers. Provides immediate user value. |
| 2nd | **P2-05 Content Deduplication** | Medium complexity, clears the path for P2-04 consistency checks. Requires research on CLAUDE.md loading. |
| 3rd | **P2-04 Automated Testing** | Benefits from P2-05 outcome (simpler consistency checks). Introduces external tooling. |
| 4th | **P2-02 Skill Composability** | Highest complexity and risk. Benefits from all prior P2 items. Requires platform research before speccing. |

### Dependency Graph

```
P2-03 (Observability) ─────────────────────────────────┐
                                                        v
P2-05 (Deduplication) ──> P2-04 (Testing) ──> P2-02 (Composability)
```

P2-03 is independent and should start immediately. P2-05 informs P2-04 design. P2-02 benefits from all three.

### Key Research Questions (Must Answer Before Speccing)

1. **For P2-02**: Can a Claude Code skill programmatically invoke another skill? What is the invocation mechanism?
2. **For P2-05**: Does Claude Code support plugin-scoped CLAUDE.md or shared configuration files? How is context loaded for plugin skills vs. general conversations?
3. **For P2-04**: What is the project's preferred scripting language for tooling? (No runtime dependencies exist today.)
