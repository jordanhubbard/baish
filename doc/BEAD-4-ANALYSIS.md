# BEAD 4: Const Correctness and Potential Use-After-Free

## Issue Analysis

The `baish_handle_preflight_failure` function in ask.def has a const correctness issue that may mask a use-after-free bug.

### Problem

```c
static int
baish_handle_preflight_failure (int preflight_result, int preflight_status,
                                const char *label, const char *host, const char *port,
                                ...)
{
  if (preflight_result == -1)
    {
      // Casts away const and frees host/port
      baish_cleanup_and_exit (question, (char *)host, (char *)port, ...);

      // Then uses host/port after they've been freed! (use-after-free)
      if (host && port)
        builtin_error (_("%s (cannot reach %s:%s)"), label, host, port);
      else if (host)
        builtin_error (_("%s (cannot reach %s)"), label, host);
      ...
    }
}
```

### Root Cause

`baish_cleanup_and_exit` frees `host` and `port` (lines 1413-1416), but `baish_handle_preflight_failure` uses them afterward for error messages (lines 1443-1446, 1459-1461).

### Investigation Needed

1. **Ownership**: Who allocates host and port? Are they always dynamically allocated or sometimes static/const?
2. **Usage pattern**: Trace all callers to determine if host/port should be freed here
3. **Error message timing**: Do we need host/port after cleanup?

### Proposed Solutions

#### Option 1: Don't Free host/port in cleanup (Safest)
```c
// Change baish_cleanup_and_exit signature
baish_cleanup_and_exit (char *question, const char *host, const char *port, ...)
{
  // ... existing cleanup ...
  // Remove these lines:
  // if (host) free(host);
  // if (port) free(port);

  // Caller responsible for freeing host/port after error messages
}
```

Then in baish_handle_preflight_failure:
```c
baish_cleanup_and_exit (question, host, port, ...);
builtin_error (..., host, port);  // Safe to use
// Free host/port here if owned by this function
if (owns_host) free(host);
if (owns_port) free(port);
return EXECUTION_FAILURE;
```

#### Option 2: Save strings before cleanup
```c
char *host_copy = host ? strdup(host) : NULL;
char *port_copy = port ? strdup(port) : NULL;
baish_cleanup_and_exit (question, (char *)host, (char *)port, ...);
builtin_error (..., host_copy, port_copy);
free(host_copy);
free(port_copy);
```

#### Option 3: Refactor to clarify ownership
- Rename cleanup function to indicate it doesn't free everything
- Create separate function for final cleanup including host/port
- Document ownership clearly

### Recommended Action

**Option 1** is safest and clearest:
1. Change `baish_cleanup_and_exit` to NOT free host/port
2. Let caller handle host/port freeing after error messages
3. Add comments documenting ownership
4. Audit all callers to ensure no memory leaks

### Risk Assessment

- **Current bug severity**: Medium - use-after-free in error paths
- **Likelihood of trigger**: Low - only on preflight failures
- **Impact**: Possible crash or garbled error messages
- **Fix complexity**: Medium - requires understanding ownership throughout ask_builtin

### Status

**DEFERRED** - Requires careful analysis of entire ask_builtin function flow (651 lines).
Recommend addressing this in BEAD 9 refactoring when function is broken into smaller pieces.

### Workaround

The current code may work by accident if:
1. The freed memory hasn't been reused yet when error message prints
2. The allocator doesn't zero freed memory immediately

But this is undefined behavior and unreliable.
