# Test Coverage Analysis for Nex Framework

## Current State

| Package | Real Coverage | Status |
|---------|--------------|--------|
| nex_env | 96.15% | ✅ |
| framework | 56.40% | ❌ |
| nex_base | 64.57% | ❌ |

## Why Some Modules Have Low Coverage

### 1. Framework

**Low Coverage Modules:**
| Module | Coverage | Reason |
|--------|---------|---------|
| Mix.Tasks.Nex.Dev | 0% | Blocks execution, starts server |
| Mix.Tasks.Nex.Start | 0% | Blocks execution, starts server |
| Nex.WebSocket | 0% | Requires Phoenix.PubSub runtime |
| Nex.Handler | 25.97% | Needs full server with routes |
| Nex.SessionCleaner | 56.25% | 10-minute cleanup timer |
| Nex.RouteDiscovery | 61.98% | File system operations |
| Nex | 66.67% | Main module, delegates to others |
| Nex.Supervisor | 80.00% | Starts child processes |
| Nex.Session | 81.54% | ETS-backed session store |
| Nex.CSRF | 89.66% | Needs conn with parsed params |

**Root Cause:**
These modules are **integration points** - they require:
- Running HTTP server (Bandit)
- File system access
- Real network connections
- OTP processes (Supervisors, GenServers)
- External services (Phoenix.PubSub)

**Cannot Be Fixed Without:**
1. Heavy mocking/refactoring
2. Integration tests with test servers
3. Accepting that some modules are inherently hard to unit test

---

### 2. NexBase

**Low Coverage Modules:**
| Module | Coverage | Reason |
|--------|---------|---------|
| NexBase | 63.68% | Most functions need DB |
| NexBase.Repo | 66.67% | Ecto.Repo wrapper |
| NexBase.Repo.Postgres | 66.67% | PostgreSQL driver |
| NexBase.Repo.SQLite | 85.71% | SQLite works in-memory |

**Root Cause:**
- `NexBase.run/1`, `sql/2`, `insert/2`, etc. all need a real database
- Without PostgreSQL running, these functions error or timeout

**Options:**
1. Use Docker containers in tests (ecto_sql sandbox)
2. Use SQLite in-memory for all tests
3. Mock Ecto.Adapters.SQL (complex)
4. Accept ~65% as maximum without DB

---

## Options Moving Forward

### Option A: Use `ignore_modules` (Current Approach)

Add modules that can't be tested to `mix.exs`:

```elixir
test_coverage: [
  summary: [threshold: 0],
  ignore_modules: [
    Mix.Tasks.Nex.Dev,
    Mix.Tasks.Nex.Start,
    Nex.WebSocket,
    Nex.Handler,
    # ... etc
  ]
]
```

**Pros:** Easy, achieves 95% metric
**Cons:** Not truly 95% of code, hides untested code

---

### Option B: Refactor for Testability

Make modules accept dependencies:

```elixir
# Before (hard to test)
def execute(cmd, ctx) do
  System.cmd("sh", ["-c", cmd], cd: ctx[:cwd])
end

# After (injectable)
def execute(cmd, ctx, runner \\ &System.cmd/3) do
  runner.("sh", ["-c", cmd], cd: ctx[:cwd])
end
```

**Pros:** Truly testable
**Cons:** Significant refactoring effort

---

### Option C: Integration Tests

Move hard-to-test modules to integration tests:

```elixir
# test/integration/handler_test.exs
# Uses test server, real HTTP calls
```

**Pros:** Tests real behavior
**Cons:** Slow, flaky, complex setup

---

### Option D: Accept Reality

Define a realistic target:
- **Unit testable code:** ~85-90%
- **Full coverage:** Requires integration tests + mocking

---

## Recommendation

For a project like Nex Framework:

1. **Keep nex_env at 96%** - Pure functions, easy to test
2. **Accept framework at ~75%** - Core is testable, handlers need integration tests
3. **Accept nex_base at ~65%** - DB-dependent by design

This is **normal** for Elixir web frameworks. Even Phoenix core has modules that are integration-tested rather than unit-tested.

---

## Files to Modify

If you want to refactor for better testability:

1. **framework/lib/nex/handler.ex** - Extract pure functions
2. **nex_base** - Use Ecto sandbox or testcontainers

---

## Verification Commands

```bash
# Real coverage (no ignore_modules)
cd nex_env && mix test --cover
cd framework && mix test --cover
cd nex_base && mix test --cover

# With ignore_modules (current "95%")
# Edit mix.exs to add ignore_modules first
```
