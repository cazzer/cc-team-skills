# Coding Principles

## Correctness

- Code should be correct first, clean second, fast third.
- Handle errors explicitly. Silent failures are the hardest bugs to find.
- Test behavior, not implementation. Tests should survive refactors.

## Simplicity

- Write the obvious solution first. Optimize when you have evidence it's needed.
- Three similar lines are better than a premature abstraction.
- Delete code freely. Dead code is confusing code.
- No feature flags or backwards-compatibility shims when you can just change the code.

## Minimal surface

- Don't add features, refactoring, or abstractions beyond what the task requires.
- A bug fix doesn't need surrounding cleanup.
- Don't design for hypothetical future requirements.
- One concern per change. Mixing refactors with features makes both harder to review.

## Readability

- Names should be specific and accurate. `getUserById` not `getData`.
- No comments explaining what code does — that's the code's job. Comments explain why, when the why is surprising.
- Functions should do one thing. If you need "and" in the description, split it.

## Safety

- Validate at system boundaries (user input, external APIs). Trust internal code.
- Parameterize queries. Encode output. Sanitize uploads.
- No secrets in code. No credentials in logs.
- Prefer immutable data. Mutation is the root of most state bugs.

## Dependencies

- Every dependency is a liability. Justify the addition.
- Pin versions. Understand what you're importing.
- Prefer standard library solutions over third-party for simple tasks.

## Verification

- Typecheck and test after every change.
- Run the thing you built. Type-checking verifies code correctness, not feature correctness.
- If you can't test it, say so explicitly rather than claiming success.
