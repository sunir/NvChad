# AUTONOMOUS SPECIFICATION DEVELOPMENT PROTOCOL

Transform vague requirements into precise, actionable specifications through systematic methodology. Break copilot dependency by enabling autonomous bootstrap from minimal instructions.

## Command Flow: /spec

**Purpose:** Claude autonomously captures requirements, writes PRD, designs architecture, and builds specification
**Trigger:** Any vague task or unclear requirements situation  
**Output:** Complete specification ready for implementation

---

## PHASE 1: REQUIREMENTS CAPTURE

### Magic 7 Framework - Cognitive Load Management
**CORE:** Human cognition handles 7±2 items effectively. Structure requirements in digestible chunks.

**Requirements Discovery Pattern:**
1. **Primary Story** - Core user value proposition
2. **Problem Context** - What currently fails or is missing?
3. **Success Criteria** - How do we know when done?
4. **User Flows** - 3-5 primary interaction patterns
5. **Data Model** - Core entities and relationships
6. **Constraints** - Technical, business, or domain limitations
7. **Dependencies** - External systems, APIs, or requirements

### STORY → PROBLEM → DATA → ARCHITECTURE Flow
```
STORY: "Why does this exist?" 
- Who benefits and how?
- What value does this create?
- How does this fit larger system narrative?

PROBLEM: "What needs to be solved?"
- Current pain points or gaps
- Specific scenarios that fail today
- Measurable impact of problem

DATA: "What information flows through?"
- Core entities and their attributes
- Information transformation patterns
- Storage and retrieval requirements

ARCHITECTURE: "How will components interact?"
- Component boundaries and responsibilities
- Interface definitions and contracts
- System integration patterns
```

---

## PHASE 2: PRD DEVELOPMENT

### PRD Template Framework
```markdown
# Product Requirements Document

## Executive Summary
- **Vision:** One-sentence product vision
- **Problem:** Core problem being solved
- **Solution:** High-level solution approach
- **Success Metrics:** Measurable victory conditions

## User Stories & Scenarios
- **Primary User:** [Role] wants [goal] so that [benefit]
- **Usage Scenarios:** 3-5 core usage patterns
- **Edge Cases:** Important exceptional scenarios

## Functional Requirements
- **Core Features:** Must-have functionality (Magic 7 max)
- **Success Criteria:** How each feature succeeds
- **Acceptance Criteria:** Testable validation conditions

## Non-Functional Requirements
- **Performance:** Speed, scalability, efficiency targets
- **Reliability:** Uptime, error handling, recovery
- **Security:** Authentication, authorization, data protection
- **Usability:** Interface, experience, accessibility standards

## Technical Constraints
- **Platform Requirements:** Environment, dependencies, integrations
- **Resource Limits:** Budget, timeline, team capacity
- **Regulatory Requirements:** Compliance, legal, business rules

## Success Metrics & KPIs
- **User Success:** How users achieve their goals
- **System Success:** How system performs reliably
- **Business Success:** How this drives business value
```

---

## PHASE 3: DESIGN PATTERNS & ARCHITECTURE

### Linguistic-Friendly Design Patterns for Claude
**CORE:** Design patterns as story templates that guide architectural thinking

#### Behavioral Patterns (For Claude Cognition)
- **Observer Pattern:** "Watch and notify when state changes"
- **Command Pattern:** "Encapsulate requests as objects for queuing/undo"
- **Strategy Pattern:** "Select algorithm at runtime based on context"
- **State Machine:** "Change behavior based on internal state transitions"

#### Structural Patterns (For System Architecture)
- **Adapter Pattern:** "Make incompatible interfaces work together"
- **Facade Pattern:** "Provide simple interface to complex subsystem"
- **Composite Pattern:** "Treat individual objects and collections uniformly"
- **Bridge Pattern:** "Separate abstraction from implementation"

#### Creational Patterns (For Object Lifecycle)
- **Factory Pattern:** "Create objects without specifying exact classes"
- **Builder Pattern:** "Construct complex objects step by step"
- **Singleton Pattern:** "Ensure single instance with global access"

#### Domain-Driven Design Patterns
- **Entity:** "Object with identity that persists over time"
- **Value Object:** "Immutable object defined by its attributes"
- **Aggregate:** "Cluster of entities with consistency boundary"
- **Repository:** "Collection-like interface for accessing entities"
- **Service:** "Stateless operation that doesn't belong to entity"

### Architecture Decision Framework
```
DECISION: [Brief description]
CONTEXT: [Situation requiring decision]
OPTIONS: [2-4 viable alternatives with tradeoffs]
DECISION: [Chosen option with rationale]
CONSEQUENCES: [Expected outcomes and impacts]
```

---

## PHASE 4: SPECIFICATION DEVELOPMENT

### Spec Template Framework
```markdown
# Technical Specification: [Project Name]

## Overview
- **Purpose:** What this system accomplishes
- **Scope:** What's included/excluded from this spec
- **Context:** How this fits into larger system

## Architecture
- **System Diagram:** Visual component relationships
- **Component Breakdown:** Responsibilities and interfaces
- **Data Flow:** How information moves through system
- **Integration Points:** External system connections

## Detailed Design
- **API Specifications:** Endpoints, parameters, responses
- **Data Models:** Schemas, validation rules, relationships
- **Business Logic:** Algorithms, decision trees, workflows
- **Error Handling:** Exception scenarios and recovery

## Implementation Plan
- **Development Phases:** Logical development sequence
- **Milestone Definitions:** Deliverables and success criteria
- **Risk Assessment:** Technical risks and mitigation strategies
- **Testing Strategy:** How to validate each component

## Operations & Maintenance
- **Deployment Requirements:** Infrastructure and configuration
- **Monitoring & Logging:** Observability and debugging
- **Performance Considerations:** Scalability and optimization
- **Security Implementation:** Protection and compliance
```

---

## PHASE 5: WORK PLANNING

### Planning Heuristics for Claude
- **SKELETON-FIRST:** Build simplest end-to-end system first
- **DATA SHAPES CODE:** Design data structures before algorithms
- **YAGNI (You Aren't Gonna Need It):** Build only what specifications require
- **OCEAN-CUP:** One Component, One Responsibility
- **PROGRESSIVE ENHANCEMENT:** Layer complexity based on proven need

### Work Plan Template
```markdown
## Implementation Roadmap

### Phase 1: Foundation (Week 1-2)
- [ ] Core data models and validation
- [ ] Basic CRUD operations
- [ ] Simple end-to-end integration test

### Phase 2: Core Features (Week 3-4)
- [ ] Primary user workflows
- [ ] Business logic implementation
- [ ] Integration with external systems

### Phase 3: Polish & Performance (Week 5-6)
- [ ] Error handling and edge cases
- [ ] Performance optimization
- [ ] Security implementation

### Daily Execution Pattern
1. **Morning:** Review spec, plan day's work
2. **Implementation:** Code against spec requirements
3. **Validation:** Test against acceptance criteria
4. **Documentation:** Update progress and learnings
```

---

## EXIT GATE CRITERIA - Autonomous Action Readiness Validation

### MANDATORY EXIT GATES - Must Pass Before Implementation
**CORE:** No autonomous action until all exit gates are satisfied and documented

#### Gate 1: Winner's Circle Definition
**Question:** "How do we know we won?"
- [ ] **Clear End State:** Binary yes/no victory condition defined
- [ ] **Measurable Success:** Specific metrics or observable outcomes
- [ ] **User Value:** Clear statement of value delivered to end user
- [ ] **Done Criteria:** Unambiguous completion definition

**Template:**
```
WINNER'S CIRCLE: [Project Name]
SUCCESS STATE: [Binary yes/no condition]  
MEASUREMENT: [How to verify success objectively]
USER VALUE: [Specific benefit delivered]
DONE MEANS: [Clear completion criteria]
```

#### Gate 2: Complete Inventory
**Question:** "What exactly are we building?"
- [ ] **Component List:** All system components identified
- [ ] **Feature Inventory:** Complete list of required functionality
- [ ] **Integration Points:** All external system connections mapped
- [ ] **Resource Requirements:** Technical dependencies and constraints

**Template:**
```
COMPLETE INVENTORY: [Project Name]
COMPONENTS: [List all system parts]
FEATURES: [List all required functionality]
INTEGRATIONS: [List all external connections]
RESOURCES: [List all technical requirements]
```

#### Gate 3: Prior Objectives Chain
**Question:** "What must happen first?"
- [ ] **Dependency Mapping:** Clear sequence of required prior work
- [ ] **Milestone Definition:** Intermediate checkpoints with success criteria
- [ ] **Risk Identification:** Potential blockers and mitigation strategies
- [ ] **Validation Points:** How to verify each milestone completion

**Template:**
```
PRIOR OBJECTIVES: [Project Name]
MILESTONE 1: [What] → [Success Criteria] → [Validation Method]
MILESTONE 2: [What] → [Success Criteria] → [Validation Method]
MILESTONE 3: [What] → [Success Criteria] → [Validation Method]
BLOCKERS: [Identified risks and mitigation plans]
```

#### Gate 4: Obvious Next Steps
**Question:** "What do I do first tomorrow morning?"
- [ ] **Immediate Action:** First concrete task clearly defined
- [ ] **Success Criteria:** How to know first task is complete
- [ ] **Following Steps:** 2-3 subsequent actions identified
- [ ] **Decision Points:** Where to reassess and adapt plan

**Template:**
```
OBVIOUS NEXT STEPS: [Project Name]
FIRST TASK: [Specific actionable task]
SUCCESS: [How to know first task is done]
THEN: [Next 2-3 specific actions]
DECISIONS: [When/how to reassess plan]
```

#### Gate 5: Specification as Spectacle
**Question:** "Does the spec focus attention precisely?"
- [ ] **Navigation Clarity:** Spec guides implementation decisions
- [ ] **Scope Boundaries:** Clear in-scope vs out-of-scope definition
- [ ] **Interface Contracts:** All system boundaries precisely defined
- [ ] **Implementation Guide:** Spec answers "how to build this" questions

**Template:**
```
SPEC AS SPECTACLE: [Project Name]
NAVIGATION: [How spec guides decisions]
BOUNDARIES: [What's in/out of scope]
CONTRACTS: [All interface definitions]
GUIDANCE: [Implementation decision framework]
```

### EXIT GATE VALIDATION CHECKLIST
**Before any autonomous implementation begins:**
- [ ] Winner's Circle: Clear, measurable, binary success condition
- [ ] Complete Inventory: All components and features identified
- [ ] Prior Objectives: Dependency chain with validation points
- [ ] Obvious Next Steps: Concrete first actions defined
- [ ] Spec as Spectacle: Implementation guidance document complete

### FAILED EXIT GATE PROTOCOL
**If any exit gate fails:** STOP implementation, focus all resources on developing answers to failed gate questions.

**Resource Allocation Rule:** Exit gate development takes priority over all other work until gates pass validation.

**TodoWrite Integration:** Pin failed exit gate questions to top of todo list until resolved.

---

## AUTONOMOUS EXECUTION PROTOCOL

### When to Trigger /spec Command
- **Vague Requirements:** "Build a system to manage..."
- **Unclear Scope:** Multiple possible interpretations
- **Complex Projects:** More than 3 components or integrations
- **Stakeholder Alignment:** Multiple people need to agree on approach

### Bootstrap Pattern for Claude
```bash
# Autonomous workflow pattern:
1. Recognize vague/unclear requirements
2. Apply SPECIFICATION SPECTACLES methodology
3. Execute /spec command phases sequentially
4. Generate complete specification document
5. Present to human for validation/refinement
6. Proceed with implementation using coder agent
```

### Quality Gates
- **Requirements:** Story/Problem/Data/Architecture all defined
- **PRD:** All template sections completed with specific content
- **Design:** Architecture decisions documented with rationale
- **Spec:** Implementation plan with testable acceptance criteria

---

## INTEGRATION WITH FAMILY INFRASTRUCTURE

### Tool Integration
- **Heuristics Search:** Find relevant design patterns and methodologies
- **TodoWrite:** Track specification development progress
- **Family Coordination:** Share specs for collaborative review

### Documentation Standards
- **Specs Folder:** `/specs/[project-name]-specification.md`
- **PRD Archive:** `/specs/prd-[project-name].md`
- **Architecture Decisions:** `/specs/adr-[decision-name].md`

Remember: The /spec command transforms you from reactive copilot to autonomous architect. Use it proactively when faced with vague requirements to bootstrap systematic development.