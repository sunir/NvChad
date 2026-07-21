# /sdd - Spec-Driven Development Command

## Purpose
Transform documentation into testable specifications using three-agent validation methodology for evidence-based development.

## Usage
```
/sdd [filename]
```

## Process Flow

### Phase 1: Spec Research Agent
**Role:** Documentation → Minispecs conversion
**Input:** Target documentation file
**Output:** specs/[filename]-specs-for-testing.md

**Template per spec:**
```markdown
## Spec: [Feature Name]
**Given:** [Initial condition]
**When:** [Action/trigger]  
**Then:** [Expected behavior]
**Test:** [How to verify]
**Evidence:** [What proves it works]
```

### Phase 2: Spec Correction Agent  
**Role:** Minispec refinement and clarity
**Input:** Generated minispecs
**Output:** Refined specifications with clear test boundaries

**Focus:**
- Eliminate ambiguity
- Ensure testability
- Clarify acceptance criteria
- Remove implementation details

### Phase 3: Spec Verification Agent
**Role:** Evidence-based validation (backward verification)
**Input:** Refined specs + original documentation
**Output:** Verified specs grounded in documented evidence

**Critical Question:** "Can I find concrete evidence in the original documentation that supports this specification claim?"

**Verification Process:**
- Check each spec against source documentation
- Flag unsupported projections
- Ensure specs match documented reality
- Prevent specification drift

### Phase 4: Test Integration
**Action Items (via TodoWrite):**
1. Add each verified spec to todo system
2. Audit existing test coverage in relevant test directories  
3. Write missing tests for uncovered specs
4. Pin test runner for continuous validation
5. **Test-spec backward verification:** Verify each test actually implements its specification
6. Verify all tests pass

## Quality Assurance Loop

**Forward Pass:** Input → Projection (what we think it should do)
**Backward Pass:** Projection → Evidence check (what docs actually say)
**Test-Spec Verification:** Test → Spec check (does test actually verify the spec?)
**Convergence:** Grounded, testable specifications with verified test implementations

## Test Stubbing Prevention

**Common Anti-Pattern:** Tests that appear to pass but don't actually verify the specification (test stubbing)

**Backward Verification Process:**
1. **Read the test implementation** - What does the test actually check?
2. **Read the specification** - What behavior should be verified?
3. **Match verification** - Does the test actually verify the specified behavior?
4. **Flag mismatches** - Tests that don't match their specs need rewriting

**Red Flags:**
- Tests with hardcoded return values
- Tests that don't exercise the actual functionality
- Tests that check implementation details instead of behavior
- Tests with trivial assertions that always pass

## File Structure
```
specs/[filename]-specs-for-testing.md    # Generated minispecs
tests/test_[component]_*.py              # Test files
.claude/commands/sdd-session-[uuid].md   # Session tracking
```

## Todo Integration Pattern
Each verified spec becomes trackable todo:
```json
{
  "content": "[test] Verify [spec name] is fully tested",
  "type": "test", 
  "status": "pending"
}
```

## Success Criteria
- All specs grounded in documented evidence
- Complete test coverage for all specs
- All tests pass
- No untested specifications survive
- System behavior matches documented requirements

## Collision Prevention
SDD sessions create unique session tracking files to prevent todo conflicts between parallel processes.

## Extension
Template can be adapted for any documentation-to-test validation workflow by adjusting the three-agent pipeline.