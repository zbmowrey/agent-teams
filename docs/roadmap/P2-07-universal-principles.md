---
title: "Universal Shared Principles"
status: "not_started"
priority: "P2"
category: "core-framework"
effort: "medium"
impact: "medium"
dependencies: ["content-deduplication"]
created: "2026-02-19"
updated: "2026-02-19"
---

# Universal Shared Principles

## Problem

The shared content system (HTML markers + CI drift validator from P2-05) works well for keeping Shared Principles and Communication Protocol in sync across skills. However, each multi-agent SKILL.md carries a full copy of these sections. As the skill count grows, editing shared content requires updating every multi-agent SKILL.md file.

Currently 6 multi-agent skills carry shared content (7 total skills including 1 single-agent). Per ADR-002: "When the skill count exceeds 8, revisit this approach." Exceeds means >8 — the trigger fires at the 9th skill.

## Proposed Solution

Extract shared principles and communication protocol into authoritative source files that SKILL.md files reference rather than duplicate. The exact mechanism (includes, references, or build-time injection) depends on Claude Code plugin capabilities at the time of implementation.

## Trigger Condition

Per ADR-002: "When the skill count exceeds 8, revisit this approach." Exceeds means >8, so the formal trigger fires at the 9th skill. Current count: 7 total skills, 6 multi-agent skills with shared content. Pre-planning at 7 is prudent per RC5/RC7/RC8 recommendations to design the extraction mechanism ahead of the trigger.

## Success Criteria

- Shared content is defined in exactly one place
- All multi-agent skills reference the authoritative source
- CI validator confirms consistency
- Adding a new skill does not require copying shared content
