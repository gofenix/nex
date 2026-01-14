# Constitution

## The Constitution of Nex

*This constitution represents a binding agreement between human contributors and AI agents working on the Nex project.*

---

## Article I: Core Values

### Section 1.1: User-Centric Development
All decisions, code, and documentation must ultimately serve the end users—indie hackers, startups, and teams building real products. Complexity that does not directly benefit users is technical debt.

### Section 1.2: Simplicity Over Cleverness
Code should be readable by humans first, machines second. A simple solution that anyone can understand is preferable to an elegant solution that requires explanation.

### Section 1.3: Pragmatism Over Perfection
Ship working software. Good enough is often better than perfect but never shipped. Iteration is the path to improvement.

---

## Article II: AI Agent Principles

### Section 2.1: Scope of Authority
AI agents may propose, draft, and refactor code within the boundaries established in `AGENTS.md`. Agents must not:
- Merge code without human approval
- Modify production credentials or security configurations
- Alter the fundamental architecture without explicit authorization
- Introduce breaking changes without clear documentation and migration paths

### Section 2.2: Transparency Requirement
Every significant change must be accompanied by a clear explanation of:
- What was changed and why
- The reasoning behind the approach taken
- Potential implications or trade-offs
- Tests added or modified to verify correctness

### Section 2.3: Changelog Discipline
Per `AGENTS.md` Principle 1, no framework modification is complete until the changelog reflects the change. This is not optional—it is a constitutional requirement.

### Section 2.4: Proposal Before Action
For changes that affect:
- Public APIs
- The developer experience (DX)
- Version numbering
- Dependencies

Agents must propose the change and receive explicit approval before implementation.

---

## Article III: Code Quality Standards

### Section 3.1: Testing Mandate
- All new functionality must include tests
- Bug fixes must include regression tests
- Tests must be meaningful and not merely for coverage metrics

### Section 3.2: Documentation Requirements
- Public APIs must have documentation (Docstrings/Moduledoc)
- Complex logic must include inline comments explaining the "why"
- Examples should be provided for non-trivial APIs

### Section 3.3: Backward Compatibility
Breaking changes require:
- A migration guide
- Deprecation warnings (where applicable)
- Version bump following the rules in `VERSIONING.md`

---

## Article IV: Communication Standards

### Section 4.1: Commit Messages
Per `AGENTS.md`, all commits follow Conventional Commits format:
- `<type>(<scope>): <subject>`
- Subject is 50 characters or fewer
- Written in imperative mood
- NO triple backticks in commit messages

### Section 4.2: Pull Request Descriptions
Every PR must include:
- A clear description of the change
- The problem it solves (or feature it adds)
- How to test the change
- Screenshots for UI changes

### Section 4.3: Code Review Conduct
- Review comments must be constructive and specific
- Suggestions should include reasoning
- Disagreements must be resolved through discussion, not assertion

---

## Article V: Security Covenant

### Section 5.1: Secure by Default
- Never expose sensitive data in logs
- Never hardcode credentials—use environment variables
- Validate all inputs, even from trusted sources
- Use parameterized queries for database operations

### Section 5.2: Vulnerability Response
Suspected security vulnerabilities must:
- NOT be disclosed publicly
- Be reported immediately to maintainers
- Be handled through private channels until a fix is ready

### Section 5.3: Dependency Trust
- Only add dependencies with proven track records
- Prefer well-maintained, popular packages
- Audit new dependencies for security implications

---

## Article VI: The "Zero Boilerplate" Promise

Nex commits to handling common web application concerns automatically:
- CSRF protection
- Asset versioning
- Hot reloading in development
- Standard security headers

Agents must NOT add boilerplate for these concerns unless explicitly requested.

---

## Article VII: Amendment Process

This constitution may be amended by:
1. Proposal by human or AI agent
2. Discussion and consensus among maintainers
3. Approval by a majority of maintainers
4. Documentation of the amendment in this file

---

## Signatures

*By contributing to Nex, all parties agree to be bound by these principles.*

**For Humans:**
- I commit to reviewing AI-generated code with the same rigor I apply to human contributions
- I commit to providing clear, actionable feedback
- I commit to being available for questions and clarifications

**For AI Agents:**
- I commit to operating within my scope of authority
- I commit to transparency in my reasoning
- I commit to respecting human judgment in disputed matters
- I commit to never bypassing safety constraints for speed

---

*This constitution was established to ensure that Nex remains a project built by humans, for humans—with AI as a powerful tool in service of that mission.*

**Last Updated:** 2025-01-13
