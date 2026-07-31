# Subagent Task Spec

Every subagent you spawn gets a task prompt built from these four parts. This is the
delegation contract — the thing that actually makes a spawn reliable. A vague objective is
the #1 cause of duplicated or divergent subagent work; a missing boundary is the #1 cause of
scope creep. The role focus file supplies the *lens*; this supplies the *task*.

1. **Objective** — the one concrete outcome this agent owns, pulled from the ticket / OpenSpec
   task. Specific enough that two agents couldn't reasonably interpret it differently. Not
   "improve auth" — "thread a log-in vs sign-up intent from the welcome screen to the sign-in
   screen; default to sign-up when absent."

2. **Output format** — exactly what to hand back to you, the orchestrator. Usually: files
   touched + a one-line rationale each, verification result (typecheck/test/build), and any
   open questions or blockers. The decision-relevant result, not the whole transcript.

3. **Tools & sources** — where to look and what to use: the `features/<feature>/` folder(s),
   the relevant spec/design doc, the role focus file, which tools are in play. Point at the
   code so the agent doesn't burn its window rediscovering what you already know.

4. **Boundaries** — what's out of scope, what not to touch, and the stop-and-report
   conditions: an unexplained bug → stop and surface, don't flail; scope materially larger
   than briefed → stop and re-assess. Keep the change surgical.

**Carry context forward.** Include the prior decisions / agent traces relevant to this task.
A subagent blind to earlier decisions makes conflicting ones (the classic multi-agent failure).

**Scale effort to the work.** No plan agent for a one-line change. No parallel writers on
interdependent files — parallelize independent reads, serialize interdependent writes.
