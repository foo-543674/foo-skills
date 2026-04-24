# foo-skills Repository

AI self-running context generator based on foo-543674's engineering philosophy.

## Core Philosophy

**This plugin is a "seed", not a "tool".**

The plugin generates AI self-running context INTO projects. Once generated, the project works with any AI tool (Claude Code, Copilot, Cursor) without this plugin.

- `philosophy/` and `perspectives/` are **source material** (the creator's values and quality standards)
- `skills/bootstrap/` is the **engine** that compiles source material into project-specific context
- The plugin's deliverable is **what it generates in the target project**, not the plugin itself

## Repository Structure

```
foo-skills/
├── .claude-plugin/
│   └── plugin.json                # Plugin manifest
├── .claude/
│   └── CLAUDE.md                  # For plugin developers (this file)
├── CLAUDE.md                      # For plugin consumers
├── PROPOSAL-v2.md                 # Design proposal for v2 architecture
├── philosophy/                    # Source material: values & judgment criteria
│   ├── core-principles.md         #   Vocabulary obligation, escape prohibition, disposability
│   ├── technology-choices.md      #   Static typing, FP, tech selection criteria
│   ├── quality-standards.md       #   Product vs technical quality, three-layer defense
│   └── development-values.md      #   Vertical slicing, test-first, 0→0.1 / 99.9→100
├── perspectives/                  # Source material: quality lenses (20 files)
│   ├── architecture.md            #   Layering by origin of operations, dependency direction
│   ├── api-design.md              #   Contract clarity, HTTP status semantics
│   └── ...                        #   (18 more perspectives)
└── skills/
    └── bootstrap/                 # Engine: generates AI context into projects
        ├── SKILL.md
        └── resources/
            ├── context-template.md
            └── checklist.md
```

## Editing Rules

### philosophy/ files

- Encode **What/When/Why** only. Never encode How (AI already knows how)
- These are the creator's values, not general best practices
- Changes here affect ALL future projects bootstrapped with this plugin

### perspectives/ files

- Each file must work for BOTH design guidance AND code review
- Structure: "What we value" → "Judgment criteria" → "Anti-patterns" → "Quality checkpoints"
- No step-by-step procedures or templates
- Keep each file under 120 lines

### skills/bootstrap/

- The only skill in this plugin
- Generates project-specific context (CLAUDE.md, agents, architecture tests, tool-agnostic files)
- References philosophy/ and perspectives/ as source material
- Does NOT contain How for technical infrastructure (AI derives that from its own knowledge)

## Feedback Reflection

When receiving feedback about philosophy or perspectives content:

1. Fix the target file
2. If the feedback is a general rule, update this CLAUDE.md
3. Check if other files violate the same rule and fix them
