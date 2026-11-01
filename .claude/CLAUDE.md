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
├── evals/                         # Eval cases built from real failures (claude plugin eval)
├── perspectives/                  # Source material: quality lenses (20 files)
│   ├── architecture.md            #   Layering by origin of operations, dependency direction
│   ├── api-design.md              #   Contract clarity, HTTP status semantics
│   └── ...                        #   (18 more perspectives)
└── skills/
    ├── bootstrap/                 # Engine: generates AI context into projects
    │   ├── SKILL.md
    │   └── resources/             #   context-template, checklist, review/acceptance contracts, ...
    ├── consult/                   # Thinking partner from vague ideas to concrete design
    ├── skill-feedback/            # Files owner feedback as Issues on this repo
    └── ai-box/                    # Per-machine container that reaches GitHub only as a GitHub App
        ├── SKILL.md
        └── resources/box/         #   Verified implementation, shipped as-is
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

- The main skill: the engine of this plugin
- Generates project-specific context (CLAUDE.md, agents, architecture tests, tool-agnostic files)
- References philosophy/ and perspectives/ as source material
- Does NOT contain How for technical infrastructure (AI derives that from its own knowledge)

### skills/ai-box/

- Exception to "no How": ships a verified implementation (`resources/box/`) as-is, because mistakes that break the credential boundary (agent forwarding, writable config mounts) are silent and the box does not vary by tech stack
- Keep the invariants in SKILL.md. Before changing `resources/box/`, run `ai-box check` and `resources/setup.md` steps 6-8 on a real machine
- Never put secrets or owner-specific values in resources
- Never add language toolchains to the box image. Project commands run in the project's dev image through rootless Podman (single-UID mode, `seccomp.json`). Do not "fix" Podman with `privileged`, `SYS_ADMIN` or `seccomp=unconfined`

## Working on this repository

- Develop from ai-box (`ai-box claude foo-543674/foo-skills`) so that PRs are opened by the GitHub App, not the owner. The ruleset requires the owner's approval; auto-merge is enabled, so an approved PR merges without further interaction
- Do not stop to ask "may I merge?" after each PR. List waiting PRs at a break
- Do not build in dependencies the changes do not need. Branch work whose content is independent from `main`, not from whatever branch you were on. Stack on an unmerged PR only when the content depends on it and the dependency cannot be cut; then open the PR anyway (do not keep work only locally), base it on the branch below so it shows only its own diff, and say what it depends on and what to look at. Enable auto-merge only on PRs whose base is `main`; after the PR below merges, retarget the next one to `main` yourself. Merge order is yours to track, not the owner's
- Ask the owner to approve only PRs that can be judged now: all checks on the current HEAD green, and the part that needs the owner's eyes named. Do not hand over conditional requests ("approve after #xx merges", "approve in N days")
- Edit files with the editor tools (Edit / Write), not `sed -i`, redirects or heredocs, and run one command per call (no `&&`, `|`, `$(...)`, `cd ... &&`). Permission rules are matched against each part of a chain, so one unallowed part (`cd`, `head`, ...) or a shell edit stops the work at a confirmation prompt while the owner is away
- PRs opened from the host with the owner's credentials cannot be approved by the owner; they merge only through the admin bypass
- When you ask the owner to decide something, say why you did not decide it yourself (which condition: money, conflict with the philosophy, no judgment axis even after deriving one from intent, missing permission) and on what axis the owner should decide. If you cannot name the condition, decide yourself and proceed
- Round trips with the owner are the bottleneck. Do not drip-feed requests ("do this" → "done" → "now this"). List every owner action and decision up front, say where you resume and what to send back, and if more round trips are unavoidable, say what each one is for and how many you expect. The consult skill is the exception: it digs out the owner's tacit knowledge through the back-and-forth itself

## Feedback Reflection

When receiving feedback about philosophy, perspectives or skill content:

1. Turn the real failure into an eval case under `evals/` (see `evals/README.md`) and run it on the current sources (`claude plugin eval . --case <name>`). Only real incidents; never invent cases. If the failure cannot be reproduced as a case, say why in the PR. Inside ai-box the AI's shell cannot see Claude's credentials and child `claude` runs fail with `Not logged in`; the owner runs evals from `ai-box shell`
2. Fix the target file
3. Run the same case the same number of times and compare. Do not judge from a single run (LLM output varies)
4. If the feedback is a general rule, update this CLAUDE.md
5. Check if other files violate the same rule and fix them
