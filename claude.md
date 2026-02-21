# Claude Code — New Project Playbook

A universal reference for starting and executing any project with Claude Code. Consolidates workflows, agent strategies, planning patterns, and quality gates refined across multiple shipped projects.

---

## Table of Contents

1. [Project Discovery & Requirements Intake](#1-project-discovery--requirements-intake)
2. [Project Kickoff Checklist](#2-project-kickoff-checklist)
3. [Claude Folder Structure](#3-claude-folder-structure)
4. [Document Templates](#4-document-templates)
5. [Development Workflow](#5-development-workflow)
6. [Task Classification & Approach](#6-task-classification--approach)
7. [Context Gathering](#7-context-gathering)
8. [Implementation with Progressive Validation](#8-implementation-with-progressive-validation)
9. [Phase-Based Development](#9-phase-based-development)
10. [Task Breakdown Format](#10-task-breakdown-format)
11. [Testing Strategy](#11-testing-strategy)
12. [Error Handling Philosophy](#12-error-handling-philosophy)
13. [Documentation Requirements](#13-documentation-requirements)
14. [Communication Pattern](#14-communication-pattern)
15. [Safety & Code Quality](#15-safety--code-quality)
16. [Git & Version Control](#16-git--version-control)
17. [Agents & Commands Reference](#17-agents--commands-reference)
18. [Phase Completion Checklist](#18-phase-completion-checklist)
19. [Definition of Done](#19-definition-of-done)

---

## 1. Project Discovery & Requirements Intake

This is the most important section in the playbook. Before planning, before architecture, before writing a single line of code — we need to deeply understand what we're building. A 15-minute discovery conversation prevents days of rework.

### How Discovery Works

Discovery happens in **rounds**. Each round builds on the previous. Don't dump every question at once — ask a round, listen, absorb, then go deeper based on what was learned.

Use `AskUserQuestion` to present focused questions (2-4 at a time). Summarize understanding back to the user after each round before moving on.

```
ROUND 1: The Big Picture
    │
    ▼
ROUND 2: Scope & Platform
    │
    ▼
ROUND 3: Technical Foundation
    │
    ▼
ROUND 4: UX & Design (if applicable)
    │
    ▼
ROUND 5: Domain Knowledge (if specialized)
    │
    ▼
ROUND 6: Business & Distribution (if relevant)
    │
    ▼
SUMMARY: Read back the full understanding
    │
    ▼
CONFIRM: "Is this right? What did I miss?"
    │
    ▼
PROCEED TO KICKOFF
```

---

### Round 1: The Big Picture (Always Ask)

These questions establish the foundation. Every project starts here.

| # | Question | Why It Matters | Example from Past Projects |
|---|----------|---------------|---------------------------|
| 1 | **What are we building?** Give me the elevator pitch — 1-2 sentences. | Frames the entire project scope | "A musician networking app with Tinder-style matching" / "A macOS app that converts photos to cross-stitch patterns" |
| 2 | **Who is this for?** Describe the target user — age, skill level, context, pain points. | Drives every UX and technical decision | "18-year-old broke musicians with no connections" / "Delaney — an avid cross-stitcher with an Intel MacBook Pro" |
| 3 | **What problem does this solve?** What's the user doing today without this, and why is that painful? | Keeps the project focused on real value | "Musicians have no good way to find local bandmates" / "Converting photos to patterns manually takes hours and produces poor results" |
| 4 | **What does success look like?** How do we know the project is done and working? | Defines the finish line before we start | "Users can match with musicians and message them" / "Delaney can import a photo, generate a pattern, and print a PDF" |

**After Round 1**: Summarize the understanding back. Example:
> "So we're building [X] for [Y] that solves [Z]. It's done when [success criteria]. Is that right?"

---

### Round 2: Scope & Platform (Always Ask)

Now we narrow down what's buildable and what's aspirational.

| # | Question | Why It Matters |
|---|----------|---------------|
| 1 | **What platform?** iOS, macOS, web, CLI, API, cross-platform? What OS versions? | Determines frameworks, language, architecture, testing approach |
| 2 | **What's the MVP?** If you could only ship 3-5 features, what are they? | Prevents scope creep — we build the core first, expand later |
| 3 | **What's the full vision?** Beyond MVP, what's the dream version? | Informs architecture decisions — we design for the future, build for today |
| 4 | **Any existing work?** Designs, wireframes, code, references, similar apps to draw from? | Saves time by building on existing thinking |
| 5 | **Timeline or constraints?** Deadline, budget, gift date, launch window? | Shapes how aggressive the phasing needs to be |

**After Round 2**: Update the summary. Example:
> "Got it — iOS app, iOS 17+, SwiftUI. MVP is: profiles, matching, and chat. Full vision adds a feed, audio samples, and band formation tools. No hard deadline but we want to ship Phase 1 in a few weeks. Right?"

---

### Round 3: Technical Foundation (Ask Based on Rounds 1-2)

Dig into the specifics that shape architecture and data model decisions.

| # | Question | When to Ask |
|---|----------|-------------|
| 1 | **What are the core data entities?** Users, posts, patterns, songs — what objects exist in this system? | Always |
| 2 | **How does data persist?** Local only (SwiftData, CoreData, files)? Cloud (Firebase, Supabase, custom API)? Both? | Always |
| 3 | **Any external APIs or services?** MusicKit, MapKit, OpenAI, Stripe, third-party SDKs? | Always |
| 4 | **Authentication?** Sign in with Apple, email/password, social login, none? | If the app has users |
| 5 | **Device-specific constraints?** Landscape only? Dynamic Island? Touch Bar? Offline support? Large touch targets? | If the platform has special hardware/context |
| 6 | **Content strategy?** User-generated? Embedded from other platforms? Stored locally? CDN? | If the app has media or content |

**After Round 3**: Sketch the initial architecture mentally. Example:
> "Architecture-wise, I'm thinking MVVM with @Observable, SwiftData for local persistence, MusicKit for playback, MapKit for navigation. Services layer between views and frameworks. Sound right?"

---

### Round 4: UX & Design (Ask for Apps with UI)

Skip this round for CLIs, APIs, and backend-only projects.

| # | Question | Why It Matters |
|---|----------|---------------|
| 1 | **What are the key screens?** Walk me through the main user flow from open to goal. | Defines the view hierarchy and navigation |
| 2 | **Navigation model?** Tabs, sidebar, stack navigation, single screen? | Shapes the app skeleton |
| 3 | **Any design references?** Apps you like the look/feel of, screenshots, wireframes, color preferences? | Prevents building something that doesn't match their vision |
| 4 | **Accessibility requirements?** Large text, VoiceOver, specific contrast ratios, special input methods? | Must be designed in, not bolted on |
| 5 | **Orientation & layout?** Portrait, landscape, both? Phone, tablet, desktop? Responsive? | Affects every view from the start |

**After Round 4**: Summarize the UX model. Example:
> "5-tab layout: Home, Now Playing, Library, Map, Settings. Landscape only. Large touch targets for motorcycle use. Dynamic Island menu on supported devices. Got it."

---

### Round 5: Domain Knowledge (Ask for Specialized Projects)

If the project involves a specialized field, we need to understand it before we can build correctly. This is what made the DCS Pro technical spec so valuable — the domain knowledge section prevented building wrong assumptions into the code.

| # | Question | When to Ask |
|---|----------|-------------|
| 1 | **What terminology should I know?** Industry-specific words, abbreviations, standards. | When the domain is unfamiliar |
| 2 | **Are there algorithms or specialized logic?** Color matching, scoring systems, signal processing, financial calculations? | When the core feature involves non-trivial computation |
| 3 | **Are there industry standards or formats?** File formats, protocols, data standards, compliance requirements? | When the project interfaces with an existing ecosystem |
| 4 | **What are the gotchas?** Common mistakes, edge cases that trip people up, things that seem simple but aren't? | Always worth asking — the user knows their domain |

**After Round 5**: Document the domain knowledge in TECHNICAL_SPEC.md so agents can reference it autonomously.

---

### Round 6: Business & Distribution (Ask When Relevant)

Skip for personal projects, gifts, or internal tools unless the user raises it.

| # | Question | When to Ask |
|---|----------|-------------|
| 1 | **How will this be distributed?** App Store, TestFlight, web deploy, npm package, internal? | Affects build config, signing, packaging |
| 2 | **Monetization model?** Free, freemium, paid, subscription, ads? | Affects feature gating, StoreKit integration, paywall design |
| 3 | **Analytics or tracking?** What usage data matters? Conversion funnels? | May need analytics SDK integration |
| 4 | **Launch strategy?** Soft launch, beta testers, public release, geographic rollout? | Shapes what "Phase 1 ship" means |

---

### Discovery Rules

1. **Ask in rounds, not all at once.** 2-4 questions per round maximum. Let the user think and respond.
2. **Listen more than you assume.** The user's words reveal priorities, constraints, and preferences that shape every decision.
3. **Summarize after each round.** Read back your understanding so the user can correct misunderstandings early.
4. **Skip rounds that don't apply.** A CLI tool doesn't need UX questions. A personal project doesn't need business questions. Adapt.
5. **Go deeper where the user has energy.** If they light up talking about the matching algorithm, dig in. If they wave off monetization, move on.
6. **Capture everything.** After discovery, the answers feed directly into PROJECT_PLAN.md, TECHNICAL_SPEC.md, and the phase breakdown.
7. **End with a full summary and explicit confirmation.** "Here's my understanding of what we're building. What did I miss or get wrong?"

### Discovery Anti-Patterns

- **Starting to code before discovery is complete.** The most expensive bugs are wrong assumptions.
- **Asking vague questions.** "What do you want?" is useless. "What are the 3-5 features you'd ship with if you could only pick a few?" is useful.
- **Asking questions you can answer yourself.** If the user said "iOS app" don't ask "what platform?" Research first, ask what you genuinely don't know.
- **Skipping Round 1.** Even if the project seems obvious, verify. "Musician app" could mean 50 different things.
- **Not summarizing.** If you don't read back your understanding, misalignments compound silently.
- **Over-questioning.** If the user has given you a detailed brief or existing docs, don't re-ask what they already answered. Read first, then fill gaps.

### After Discovery: The Handoff

Once discovery is complete and the user confirms the summary, the output flows directly into project setup:

| Discovery Output | Feeds Into |
|-----------------|------------|
| Elevator pitch + target user + success criteria | PROJECT_PLAN.md (Overview, Success Criteria) |
| Platform + MVP features + full vision | PROJECT_PLAN.md (Target Platform, Phase Summary) |
| Data entities + persistence + APIs + auth | PROJECT_PLAN.md (Architecture, Key Technical Decisions) |
| Screens + navigation + design direction | PROJECT_PLAN.md (Phase Details for UI phases) |
| Domain terminology + algorithms + standards | TECHNICAL_SPEC.md (Domain Knowledge, Algorithms) |
| Distribution + monetization | PROJECT_PLAN.md (Future Phases), separate monetization-plan.md if needed |

---

## 2. Project Kickoff Checklist

Before writing any code, complete these steps in order. Discovery (Section 1) must be done first.

### Step 1: Understand the Vision
- [ ] Define the core problem being solved and for whom
- [ ] Identify the target platform(s) and minimum OS/runtime versions
- [ ] List must-have features for MVP vs. nice-to-have
- [ ] Establish success criteria — how do we know the project is "done"?

### Step 2: Set Up the Claude Folder
- [ ] Create `Claude/` folder in the project root
- [ ] Create `PROJECT_PLAN.md` — architecture, phases, key decisions
- [ ] Create `WORKFLOW.md` — project-specific coding standards and conventions
- [ ] Create `AGENT_TASKS.md` — granular task breakdown (for moderate+ projects)
- [ ] Create `TECHNICAL_SPEC.md` — domain knowledge, algorithms, data models (for complex projects)
- [ ] Copy or reference this `claude.md` playbook

### Step 3: Define Architecture
- [ ] Choose architecture pattern (MVVM, MVC, clean architecture, etc.)
- [ ] Document key technical decisions with rationale in PROJECT_PLAN.md
- [ ] Define folder/file structure
- [ ] Identify external dependencies and frameworks
- [ ] Document the data model layer

### Step 4: Plan Phases
- [ ] Break the project into 3-9 sequential phases
- [ ] Each phase should deliver a testable, buildable increment
- [ ] Define exit criteria for each phase
- [ ] Identify risks and mitigations

### Step 5: Break Down Tasks
- [ ] Create task breakdown for at least Phase 1 in AGENT_TASKS.md
- [ ] Each task gets: description, acceptance criteria, files to create/modify, dependencies, complexity estimate
- [ ] Tasks within a phase are sequential; phases are sequential
- [ ] Validation task at the end of every phase

---

## 3. Claude Folder Structure

Every project gets a `Claude/` folder with documentation that lives alongside the code. This is the single source of truth for project planning and agent execution.

### Minimum (Small Projects)
```
Claude/
├── PROJECT_PLAN.md          # Architecture + phases + decisions
└── WORKFLOW.md              # Coding standards + conventions
```

### Standard (Most Projects)
```
Claude/
├── PROJECT_PLAN.md          # Architecture + phases + decisions
├── WORKFLOW.md              # Coding standards + conventions
├── AGENT_TASKS.md           # Granular task breakdown per phase
└── AGENTS_AND_COMMANDS.md   # Agent reference (copy from this playbook)
```

### Full (Complex Projects)
```
Claude/
├── PROJECT_PLAN.md          # Architecture + phases + decisions
├── WORKFLOW.md              # Coding standards + conventions
├── AGENT_TASKS.md           # Granular task breakdown per phase
├── TECHNICAL_SPEC.md        # Domain knowledge, algorithms, data models
├── AGENTS_AND_COMMANDS.md   # Agent reference
├── CHANGELOG.md             # Version history
└── [feature]-plan.md        # Individual feature planning docs as needed
```

---

## 4. Document Templates

### PROJECT_PLAN.md Template

```markdown
# [Project Name] - Project Plan

## Overview
[1-2 sentence description of what the project is and who it's for]

## Quick Links
| Document | Purpose |
|----------|---------|
| `TECHNICAL_SPEC.md` | Complete technical specifications |
| `AGENT_TASKS.md` | Task breakdown for execution |
| `WORKFLOW.md` | Development workflow and standards |

## Target Platform
- **OS**: [e.g., iOS 17+, macOS 14+, Node 20+, Python 3.11+]
- **Architecture**: [e.g., Universal Binary, ARM64, x86_64]
- **Key Frameworks**: [e.g., SwiftUI, React, Django]

## Architecture Overview
[ASCII diagram of layers/components]

### Key Technical Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| [Decision] | [Choice] | [Why] |

## Phase Summary
| Phase | Name | Tasks | Key Deliverable | Status |
|-------|------|-------|-----------------|--------|
| 1 | Foundation | 1.1-1.X | [Deliverable] | Pending |
| 2 | [Name] | 2.1-2.X | [Deliverable] | Pending |

## Phase Details
### Phase 1: [Name]
**Status**: Pending

[Description of what this phase delivers]

**Files Created**: [list after completion]

**Exit Criteria**:
- [ ] [Specific, verifiable criterion]
- [ ] All tests pass
- [ ] Project builds without warnings

## Testing Strategy
[What to test, what not to test, performance targets]

## Risk Mitigation
| Risk | Mitigation |
|------|------------|
| [Risk] | [Mitigation] |

## Success Criteria
[How we know the project is complete and ready]
```

### AGENT_TASKS.md Template

```markdown
# [Project Name] Agent Task Breakdown

## How to Use This Document

Each phase contains tasks designed to be:
1. **Self-contained**: All context needed is in the spec documents
2. **Testable**: Clear acceptance criteria define "done"
3. **Sequential within phase**: Tasks may have dependencies
4. **Validated at phase end**: Build + test gate before next phase

### Task Format
- Task X.Y: [Name]
- Agent Type: Plan | Explore | General-purpose | Bash
- Dependencies: Prerequisite tasks
- Estimated Complexity: Low | Medium | High
- Description: What needs to be done
- Acceptance Criteria: Specific, verifiable checkboxes
- Files to Create/Modify: Exact paths
- Reference: Spec section for implementation details

## Phase 1: [Name]
### Task 1.1: [Name]
[Follow format above]
```

---

## 5. Development Workflow

The core loop for every task, refined across multiple projects:

```
RECEIVE TASK
    │
    ▼
CLASSIFY (Trivial / Moderate / Complex)
    │
    ▼
GATHER CONTEXT (Explore agent, read files, search codebase)
    │
    ▼
PLAN (TodoWrite for multi-step, Plan agent for complex)
    │
    ▼
IMPLEMENT (Write code, progressive validation at each step)
    │
    ▼
VALIDATE (Build, test, review)
    │
    ▼
DOCUMENT (Update plan, record decisions, note completions)
    │
    ▼
REPORT (Clear summary of what was done and current state)
```

---

## 6. Task Classification & Approach

When receiving any task, classify it first to determine the right approach:

### Trivial
**Signals**: 1-2 file changes, obvious implementation, no unknowns
**Approach**: Direct implementation. No planning overhead needed.
**Examples**: Fix a typo, add a log statement, rename a variable, adjust a constant

### Moderate
**Signals**: New feature across multiple files, some unknowns, clear requirements
**Approach**: Explore first to understand existing patterns, then implement.
**Steps**:
1. Use Explore agent or read relevant files to understand current code
2. Create TodoWrite with implementation steps
3. Implement sequentially with validation at each step
4. Write tests
5. Build and verify

### Complex
**Signals**: Architectural decisions needed, multiple valid approaches, significant scope
**Approach**: Use Plan agent for design before writing any code.
**Steps**:
1. Use Plan agent to design the approach
2. Present plan to user for approval
3. Break into sub-tasks in AGENT_TASKS.md
4. Execute phase by phase with validation gates
5. Write tests at each phase
6. Document decisions and learnings

---

## 7. Context Gathering

Context gathering prevents hallucination and ensures we build on existing patterns rather than creating conflicting code.

### Rules
- **Always read files before editing** — see actual code structure, never assume
- **Search before creating** — check if functionality already exists (`Glob`, `Grep`)
- **Use Explore agent** for "how does X work?" questions about the codebase
- **Use DocumentationSearch** for framework/API questions (Apple, third-party SDKs)
- **Use WebSearch** for current best practices, library docs, or domain knowledge
- **Read the Claude/ folder** at session start to understand project context and conventions

### Anti-Patterns
- Editing a file you haven't read in this session
- Creating a new file without searching for existing similar functionality
- Assuming an API shape without checking documentation
- Implementing a pattern that contradicts existing codebase conventions

---

## 8. Implementation with Progressive Validation

Catch errors early and often. Don't write 500 lines then try to build — validate incrementally.

### Validation Stages

**Stage 1 — After writing each file** (seconds):
- Check for syntax errors, missing imports, type mismatches
- For Xcode projects: `XcodeRefreshCodeIssuesInFile`
- For other projects: language-specific linters or type checkers

**Stage 2 — For UI work** (seconds):
- Visual validation of components/views
- For SwiftUI: `RenderPreview`
- For web: Browser preview or screenshot

**Stage 3 — Before marking a task complete** (minutes):
- Full compilation/build validation
- For Xcode: `BuildProject`
- For other: `npm run build`, `cargo build`, `go build`, etc.

**Stage 4 — After completing a feature/phase** (minutes):
- Run the full test suite
- For Xcode: `RunAllTests`
- For other: `npm test`, `pytest`, `cargo test`, etc.

### Validation Rules
- Never skip Stage 3 (build) before declaring a task complete
- Never skip Stage 4 (tests) before declaring a phase complete
- If a build fails, fix it before moving to the next task
- If tests fail, fix them before moving to the next phase

---

## 9. Phase-Based Development

Every project is broken into sequential phases. Each phase delivers a testable increment.

### Phase Design Principles

1. **Each phase builds on the previous** — Phase 2 depends on Phase 1 being complete and stable
2. **Each phase is independently testable** — you can verify the phase works before moving on
3. **Foundation first** — Phase 1 is always project structure, data models, and core infrastructure
4. **UI after logic** — Build services and business logic before views when possible
5. **Polish last** — Optimization, branding, and edge cases come in the final phase(s)

### Typical Phase Progression

| Phase | Focus | What Gets Built |
|-------|-------|-----------------|
| 1 | Foundation | Project structure, data models, core types, configuration |
| 2 | Core Engine | Primary business logic, services, algorithms |
| 3 | Basic UI / Interface | Views that exercise the core engine |
| 4 | Full Workflow | Complete user flows from start to finish |
| 5 | Persistence | Save/load, database, caching, state management |
| 6 | Secondary Features | Editing, advanced features, integrations |
| 7 | Polish & Optimization | Performance, branding, accessibility, error recovery |

Adjust the number of phases to fit the project. Small projects may have 3-4 phases. Large projects may have 8-10.

### Phase Execution Flow

```
START PHASE
    │
    ▼
Review phase tasks in AGENT_TASKS.md
    │
    ▼
Execute tasks sequentially (1.1 → 1.2 → 1.3 → ...)
    │
    ▼
After each task: validate (build compiles, no regressions)
    │
    ▼
After all tasks: write/run phase tests
    │
    ▼
Run FULL test suite (all phases)
    │
    ▼
Update PROJECT_PLAN.md (mark phase complete, note deviations)
    │
    ▼
Update CHANGELOG.md if applicable
    │
    ▼
PHASE COMPLETE — proceed to next phase
```

---

## 10. Task Breakdown Format

Use this format for every task in AGENT_TASKS.md. This structure has been proven across multiple projects to give agents exactly what they need to execute autonomously.

```markdown
### Task X.Y: [Descriptive Name]
**Agent Type**: General-purpose | Plan | Explore | Bash
**Dependencies**: Task X.Z (or "None")
**Estimated Complexity**: Low | Medium | High

**Description**:
[2-4 sentences describing what needs to be done and why]

**Implementation Requirements**:
1. [Specific requirement]
2. [Specific requirement]
3. [Specific requirement]

**Files to Create**:
- `path/to/new/file.ext`

**Files to Modify**:
- `path/to/existing/file.ext`

**Acceptance Criteria**:
- [ ] [Specific, verifiable criterion]
- [ ] [Specific, verifiable criterion]
- [ ] [Specific, verifiable criterion]
- [ ] Code compiles without errors
- [ ] No regressions in existing tests

**Reference**: TECHNICAL_SPEC.md Section X (if applicable)
```

### Task Complexity Guide

| Complexity | Typical Scope | Examples |
|------------|---------------|---------|
| **Low** | 1-2 files, straightforward logic | Data models, simple views, config files |
| **Medium** | 3-5 files, some logic, known patterns | Services, view models, API integrations |
| **High** | 5+ files, complex algorithms, new patterns | Core engines, complex UI, state machines |

---

## 11. Testing Strategy

### When to Write Tests

- **After each phase** — write unit tests covering new services and logic
- **After each significant feature** — cover the happy path and critical edge cases
- **Before marking a phase complete** — all tests must pass (new and existing)
- **When fixing a bug** — write a test that reproduces it first, then fix

### What to Test

| Layer | Test Focus | Priority |
|-------|------------|----------|
| **Models** | Initialization, computed properties, encoding/decoding, equality | High |
| **Services** | Core business logic, state transitions, error handling | High |
| **ViewModels** | Data transformations, actions, computed properties | Medium |
| **Utilities** | Helper functions, extensions, formatters, parsers | Medium |
| **Algorithms** | Correctness, edge cases, performance boundaries | High |

### What NOT to Unit Test

- UI views directly (use previews, snapshots, or UI tests instead)
- External API calls in unit tests (mock the services)
- Singleton initialization mechanics
- Framework internals (trust the framework)

### Test File Organization

Mirror the source structure under a tests directory:
```
[Project]Tests/
├── Models/
│   └── [Model]Tests.ext
├── Services/
│   └── [Service]Tests.ext
├── ViewModels/
│   └── [ViewModel]Tests.ext
└── Utilities/
    └── [Utility]Tests.ext
```

### Test Quality Standards

- Each test should test one thing
- Test names should describe the scenario and expected outcome
- Prefer real assertions over "doesn't crash" tests
- Cover: happy path, error cases, boundary values, empty/nil inputs
- Performance-sensitive code gets benchmark tests with explicit thresholds

---

## 12. Error Handling Philosophy

A clear decision framework prevents wasted time on the wrong problems.

### Attempt Automatic Fix
- Syntax errors
- Missing imports
- Type mismatches
- Common compiler errors
- Formatting issues

### Stop and Report to User
- Architectural issues that need a design decision
- Ambiguous requirements where multiple valid approaches exist
- External service failures that block progress
- Test failures that suggest a design problem (not a typo)

### Never
- Silently ignore errors
- Comment out failing code to make the build pass
- Skip tests to move forward
- Force-unwrap or force-cast to bypass type errors
- Introduce hacks to work around a problem without understanding the root cause

---

## 13. Documentation Requirements

### What to Document and When

| When | What | Where |
|------|------|-------|
| **Before starting complex work** | The plan and approach | PROJECT_PLAN.md, AGENT_TASKS.md |
| **After completing a phase** | Phase status, files created, deviations | PROJECT_PLAN.md |
| **When making significant decisions** | Decision, alternatives considered, rationale | PROJECT_PLAN.md (Key Technical Decisions table) |
| **When discovering limitations** | What doesn't work and why | PROJECT_PLAN.md (Known Limitations section) |
| **When shipping a version** | What changed, what's new, what's fixed | CHANGELOG.md |

### Documentation Principles

- **Concise and actionable** — docs should help you (or an agent) do the work, not narrate it
- **Live in Claude/ folder** — all project docs stay together, separate from code comments
- **Avoid redundancy** — don't duplicate what code comments already say
- **Update, don't append** — keep documents current by editing in place, not appending notes
- **Tables over prose** — use tables for decisions, phases, and comparisons

---

## 14. Communication Pattern

Balance clarity with efficiency during task execution.

### During Implementation

- **Show the plan** with TodoWrite for any multi-step task (3+ steps)
- **Work sequentially** through todos, marking progress in real-time
- **Explain significant decisions** but don't over-narrate routine operations
- **Use code references** in `file_path:line_number` format when discussing specific locations
- **Report results clearly** when tasks complete — what was done, what state things are in

### When Blocked

- Describe what you tried and what happened
- Propose alternatives if you have them
- Ask specific questions rather than open-ended ones
- Never silently retry the same failing approach

### Progress Visibility

- For multi-phase work: update the TodoWrite list as tasks complete
- For long operations: communicate at phase boundaries, not every file
- At completion: summarize what was built, what tests pass, what's next

---

## 15. Safety & Code Quality

Core principles that apply to every project, every language.

### Universal Principles

- **Never force-unwrap, force-cast, or suppress errors** unless explicitly requested
- **Prefer the language's type system** — let the compiler catch bugs at compile time
- **Use modern concurrency patterns** — async/await over callbacks or reactive chains where available
- **Follow platform conventions** — use the framework's patterns, not invented abstractions
- **Validate work before declaring complete** — build it, test it, then report it
- **Avoid over-engineering** — only implement what's requested, nothing speculative
- **Delete unused code completely** — no commented-out code, no backwards-compat shims, no "TODO: remove" markers
- **No security vulnerabilities** — sanitize inputs, avoid injection, follow OWASP top 10

### Code Style (Adapt Per Project)

Document project-specific conventions in WORKFLOW.md. Common universal standards:

- Consistent naming conventions (document which casing for what)
- Consistent indentation (document spaces vs tabs and count)
- Imports organized and minimal
- Clear separation of concerns (models, services, views, view models)
- Comments only where logic isn't self-evident

---

## 16. Git & Version Control

### Commit Practices

- Commit at meaningful boundaries (feature complete, phase complete, bug fixed)
- Write concise commit messages that describe the "why" not just the "what"
- Never commit secrets, credentials, API keys, or .env files
- Stage specific files, not `git add -A` (avoid accidentally including unwanted files)
- Never force-push to main/master without explicit user approval

### Branch Strategy

- Work on feature branches for non-trivial changes
- Branch names should be descriptive: `feature/user-auth`, `fix/login-crash`, `phase-2/core-engine`
- Keep branches focused — one feature or phase per branch

### PR Practices

- Title under 70 characters
- Body includes: summary (bullet points), test plan
- Link to relevant phase or task if applicable

---

## 17. Agents & Commands Reference

### Available Agents

| Agent | Best For | Tools Available |
|-------|----------|-----------------|
| **Bash** | Git operations, terminal commands, build scripts | Bash |
| **General-purpose** | Multi-step tasks, complex research, file searching | All tools |
| **Explore** | Codebase exploration, finding files/patterns, understanding architecture | All except Task, Edit, Write |
| **Plan** | Designing implementation strategy, architectural trade-offs | All except Task, Edit, Write |
| **Statusline-setup** | Status line configuration | Read, Edit |

### Explore Agent Thoroughness Levels

| Level | When to Use |
|-------|-------------|
| `quick` | Simple file/symbol lookup, "where is X defined?" |
| `medium` | Understanding a feature's implementation across a few files |
| `very thorough` | Full architectural understanding, tracing data flow across the codebase |

### Agent Usage Patterns

- **Before implementing**: Use Explore agent to understand existing patterns
- **Before complex features**: Use Plan agent to design the approach
- **For independent research**: Launch multiple agents in parallel
- **For codebase questions**: Explore agent over manual Grep/Glob for non-trivial searches

### Tool Categories

**File Operations**: Read, Write, Edit, Glob, Grep

**Xcode Operations** (Apple platform projects):
- XcodeRead, XcodeWrite, XcodeUpdate, XcodeLS, XcodeGlob, XcodeGrep, XcodeMV, XcodeRM, XcodeMakeDir

**Xcode Build & Test**:
- BuildProject, RunAllTests, RunSomeTests, GetTestList, GetBuildLog
- XcodeListNavigatorIssues, XcodeRefreshCodeIssuesInFile

**Xcode Development**: ExecuteSnippet, RenderPreview

**Documentation**: DocumentationSearch (Apple Developer Docs)

**Web & Search**: WebFetch, WebSearch

**Task Management**: TodoWrite, Task, TaskOutput

**Planning**: EnterPlanMode, ExitPlanMode, AskUserQuestion

### Best Practices

1. Use specialized agents for complex, multi-step tasks
2. Launch agents in parallel when tasks are independent
3. Use Explore agent for codebase research rather than manual searching
4. Use Plan agent for implementation planning before writing complex code
5. Prefer Xcode tools when working in Xcode projects
6. Use DocumentationSearch for the latest Apple framework information
7. Use WebSearch for third-party library docs or current best practices

---

## 18. Phase Completion Checklist

Run through this checklist before marking any phase as complete:

### Code Quality
- [ ] All new code compiles without errors
- [ ] No new compiler warnings introduced
- [ ] Code follows project conventions documented in WORKFLOW.md
- [ ] No TODOs left unresolved within this phase's scope
- [ ] No commented-out code or dead code

### Testing
- [ ] Unit tests written for all new services and logic
- [ ] All new tests pass
- [ ] All existing tests still pass (no regressions)
- [ ] Edge cases covered (empty inputs, error states, boundary values)

### Build
- [ ] Full project builds successfully
- [ ] No runtime crashes on basic usage paths
- [ ] Target platform(s) verified (if applicable: Intel + ARM, multiple OS versions)

### Documentation
- [ ] PROJECT_PLAN.md updated — phase marked complete with status and files created
- [ ] Key decisions recorded if any were made during implementation
- [ ] CHANGELOG.md updated (if the project tracks versions)
- [ ] Deviations from the original plan noted

### Ready for Next Phase
- [ ] This phase's deliverables are stable enough to build on
- [ ] No blocking issues that would affect the next phase
- [ ] Next phase's tasks reviewed and still make sense given this phase's outcome

---

## 19. Definition of Done

A task/feature/phase is **done** when:

1. **It works** — the feature functions as described in the acceptance criteria
2. **It builds** — the project compiles cleanly with no new warnings or errors
3. **It's tested** — automated tests cover the core logic and pass
4. **It's documented** — the project plan reflects the current state
5. **It doesn't break anything** — all existing tests still pass
6. **It's clean** — no hacks, no dead code, no suppressed errors

A task is **not done** if:
- Tests are failing
- The build is broken
- Implementation is partial
- Errors were encountered but not resolved
- It only works with workarounds

---

## Appendix: Executing Phases with Agents

### Running a Full Phase

```
Execute Phase [N] of [Project Name].

Reference documents:
- Claude/TECHNICAL_SPEC.md (specs and algorithms)
- Claude/AGENT_TASKS.md (tasks and acceptance criteria)
- Claude/WORKFLOW.md (coding standards)

Complete tasks [N.1] through [N.X] in order.
Run tests and build after each major task.
Report any blockers.
```

### Running a Single Task

```
Execute Task [X.Y] ([Task Name]) for [Project Name].

Reference:
- TECHNICAL_SPEC.md Section [N] for implementation details
- AGENT_TASKS.md Task [X.Y] for acceptance criteria

Create the files, ensure it compiles, and verify all acceptance criteria.
```

### Running Validation

```
Validate Phase [N] of [Project Name]:
1. Run all unit tests
2. Build project
3. Verify all acceptance criteria from AGENT_TASKS.md
4. Report status
```

---

*This playbook evolves with each project. Update it when new patterns prove useful or existing ones need refinement.*
