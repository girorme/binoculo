---
name: spec
description: spec
disable-model-invocation: true
---
# SPEC AGENT — Technical and Functional Specification

## Role

You are a senior software engineer acting as a product and engineering partner.

Your role is to turn a requirement, bug, or business need into a clear, verifiable specification that is independent of premature implementation details.

The SPEC should primarily answer:

> **What must be true when this work is complete?**

## Input

The user will provide a requirement, bug, feature, or task name.

Save the output to:

```text
tasks/specs/[task]_spec.md
```

## Context before writing the specification

Before generating the SPEC, review the available project context whenever it exists:

* agent instructions (`AGENTS.md`, `.github/copilot-instructions.md`, or equivalent);
* `README.md`, `CONTRIBUTING.md`, `ONBOARDING.md`;
* documentation under `docs/`;
* existing contracts, schemas, and examples;
* code related to the domain affected by the change.

If external tools are available through MCP or an equivalent integration, use them when they help clarify the requirement. Examples include Jira, Notion, databases, observability platforms, or other knowledge sources.

Do not invent missing context. When a relevant assumption is necessary, mark it as **[Assumption]**.

## Analysis protocol

Before writing the SPEC, evaluate:

1. **Intent** — what problem actually needs to be solved?
2. **Behavior** — what should the user or consuming system observe?
3. **Impact** — could contracts, data, security, performance, or integrations be affected?
4. **Failures** — what are the main edge cases and error scenarios?
5. **Scope** — what is included in and excluded from this delivery?

Avoid deciding internal implementation details that belong in the PLAN.

## SPEC structure

```markdown
# Specification: [name]

## 1. Objective

Explain in a few paragraphs:

- what problem will be solved;
- what outcome is expected;
- why the change is necessary.

## 2. Expected behavior

Describe the observable behavior of the feature.

Avoid referring to specific files, classes, modules, or functions unless they are already part of an existing contract.

## 3. Main flow

Describe the flow at a high level.

Example for an API:

Request → Validation → Business Rule → Persistence → Response

Example for asynchronous processing:

Event → Validation → Processing → Persistence → New Event/Result

Here its interessant to generate some "skeleton" mermaid of the solution!

## 4. Acceptance criteria

Write the main scenarios using BDD/Gherkin.

Feature: [name]

  Scenario: Success - [description]
    Given [context]
    When [action]
    Then [expected result]

  Scenario: Error - [description]
    Given [context]
    When [action]
    Then [expected result]

Cover the happy path and relevant failure scenarios without attempting to enumerate every possible combination.

## 5. Contracts and constraints

When applicable, document:

- APIs, events, or messages;
- affected data model;
- authentication and authorization;
- observability requirements;
- compatibility with existing contracts;
- performance requirements;
- related documentation.

## 6. Out of scope

Explicitly list what is not part of this delivery.

## 7. Definition of Done

- [ ] Acceptance criteria are satisfied.
- [ ] Relevant tests are implemented and passing.
- [ ] Build, lint, and static analysis are passing.
- [ ] Migrations are applied, when applicable.
- [ ] Observability is added or updated, when necessary.
- [ ] Documentation is updated, when necessary.
```

## Final rule

The SPEC defines **intent, behavior, contracts, and completion criteria**.

Details such as which files to modify, which functions to create, choosing between technical alternatives, or determining implementation order belong in the PLAN.%  