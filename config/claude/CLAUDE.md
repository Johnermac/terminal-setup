# Global instructions

## Git commits

- **One line. No body.** The subject line is the whole message.
- Keep it short and direct: say what changed, not how or why. Detail belongs in the MR description or the code.
- Conventional prefix (`feat:`, `fix:`, `refactor:`, `chore:`, `test:`, `docs:`, `style:`, `perf:`), scope optional.
- **Never add a `Co-Authored-By:` trailer**, or any other trailer or attribution line.
- Same rule for PR/MR titles.

Good:
```
fix(ui): move SBOM page out of the route module
feat(api): paginate the assets endpoint
refactor: drop the unused resolved-approval queries
```

Bad (too long, explains rationale, has a trailer):
```
fix(ui): keep the SBOM repository page out of the route module so recharts stays lazy

Exporting a component from a route file disables autoCodeSplitting...

Co-Authored-By: ...
```

## Review gates

Enforced by `~/.claude/hooks/review-gates.sh` (PreToolUse on Bash): `git commit` is denied until `review-gates.sh mark commit` records the staged tree, `git push` until `review-gates.sh mark push` records HEAD. Mark only after the gate actually ran. `REVIEW_GATES=off` disables it.

### Gate depth by risk

- **Full gates** (code quality, security, validation) when the change touches scope, pacing,
  auth/identity, exploit/sandbox, secrets, migrations, or outbound target traffic.
- **Refactor or other code with no behavior change in those areas:** code quality before
  commit, validation before push. No security review.
- **Docs-only or test-only:** code quality before commit, then mark push after checking the
  diff for secrets. No security review, no validator.
- **Stop rounds at non-blocking.** When a security or validation round returns no blocking
  item, its non-blocking notes go to the backlog and the branch ships. Fix in-branch only what
  blocks.

### Code quality (before every commit)

```
Assess the code strictly for maintainability and clarity.
Check naming, readability, structure, duplication, complexity, abstractions, cohesion, coupling, dead code, inconsistent patterns, overly clever code, error-prone conventions, and unnecessary indirection.
Do not assess security, performance, or bugs unless directly relevant to maintainability.
Prioritize changes that meaningfully make the code easier to understand, modify, and review.
```

### Security assessment (before every push)

```
Assess the code strictly for security before it is pushed or merged.
Check authentication, authorization, input validation, injection risks, secrets/credentials, sensitive data exposure, cryptography, session handling, access control, insecure defaults, unsafe deserialization, SSRF, path/file handling, dependency risks, and security-relevant error handling/logging.
Prioritize vulnerabilities that are realistically exploitable and security weaknesses that could materially increase attack surface or impact.
Do not assess code quality, performance, style, or bugs unless directly relevant to security.
Do not report theoretical or low-value issues without a plausible attack path.
For each finding, explain the vulnerability, attack scenario, affected code, severity, and concrete remediation.
```

### Validation (before a batch of fixes, before push)

Run it as an independent reviewer: spawn a fresh Agent (not a fork, so it has no stake in the fixes) on the strongest model available. Order: Mythos if the Agent tool offers it, else `model: "fable"` (Fable 5.1), else `model: "opus"` (Opus 5.5). Never Sonnet or Haiku for this gate. Say in the result which model ran it. Give the agent the findings list, the commit range (`git log`/`git diff` base..HEAD) and the repo's test command, then this prompt:

```
You are the final validator before these fixes are pushed. You did not write them. Verify; do not trust commit messages or summaries.

Inputs: the list of findings the fixes claim to address, the commit range, and the test command.

For each finding:
1. Read the original problem and the diff that claims to fix it.
2. Check the fix addresses the root cause, not only the reported symptom, and covers every call site or input path with the same flaw.
3. Check for regressions: changed behavior elsewhere, broken invariants, removed checks, new error paths that are swallowed.
4. Check a test proves it: one that fails without the fix and passes with it. Run it.
5. Verdict: FIXED, PARTIAL (say what is missing), NOT FIXED, or REGRESSION (say what broke). Cite file:line and the evidence.

Then for the branch as a whole:
- Run the full test suite and linters; report exact failures.
- Check for changes in the range that no finding explains (scope creep, debug leftovers, unrelated edits).
- Check the project's own rules (CLAUDE.md, commit format, no secrets).

End with merge readiness: READY or NOT READY, followed by the blocking items in priority order. A single NOT FIXED, REGRESSION or failing test means NOT READY. Report only what you verified; mark anything you could not check as UNVERIFIED.
```
