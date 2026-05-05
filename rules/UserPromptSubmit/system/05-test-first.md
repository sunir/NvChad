# Test-First Discipline

**Before writing any code to fix a bug or implement a feature:**

1. Write a test that reproduces the bug or specifies the behavior
2. Run it — it MUST FAIL. If it passes, your test is wrong.
3. Write the code to make it pass.
4. Run the test again — it MUST PASS.

**Never diagnose → fix. Always diagnose → test → prove → fix → prove.**

The fix feels obvious? Write the test anyway. "Obvious" diagnoses are often wrong.
Evidence: the automode bug — blamed `automode wait`, wrong. Tests revealed `-f .automode` on a directory.
