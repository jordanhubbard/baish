# Changelog

All notable changes to baish will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project uses a version scheme of MAJOR.MINOR.PATCH-baish.BUILD.

## [Unreleased]
## [5.3.0-baish.3] - 2026-01-26

### Changes

- Continue refactoring ask_builtin function
- Fix use-after-free bug and begin function refactoring
- Complete low-priority code quality improvements


## [5.3.0-baish.2] - 2026-01-26

### Changes

- Fix release script to force-add gitignored version files
- Fix changelog insertion in release script
- Add automated release system
- Complete code review implementation: security fixes, tests, and infrastructure
- Ignore temporary .tmp-* files
- Add rationale for builtin ask in README
- Merge pull request #2 from jordanhubbard/copilot/add-mcp-support-to-baish
- Merge main branch preserving MCP implementation
- Merge main branch with MCP implementation preserved
- Support round-robin ask endpoints and models
- bd sync: 2026-01-23 10:02:02
- Refine ask execution output and prompt guardrails to avoid unnecessary commands and file access. Align builtins cJSON build wiring.
- Tighten ask output parsing and silence notice by default
- Adopt openai-c transport and cJSON parsing for ask builtin
- Reuse keep-alive connections for ask to reduce latency and handle Responses output.
- Retry JSON parsing within ask output
- Ignore beads daemon-error file
- Include OS and arch context in ask prompt
- Remove now obsolete bash handbook and move source directory
- Add ask flags for JSON and execution
- bd sync: 2026-01-22 21:31:43
- Close bead baish-4pk
- Preflight models before ask output
- bd sync: 2026-01-22 20:55:58
- Close bead baish-4pk
- Improve ask notices and error guidance
- bd sync: 2026-01-22 20:42:22
- Add comment about ask interactive behavior
- Tame ask diagnostics and show config sources
- Remove checked-in LLM defaults
- Prevent ask hangs with timeouts and config guidance
- Improve ask builtin LLM diagnostics and preflight
- Document baish AI help and ignore build outputs
- Initial version
- Document baish AI config and support host-only base URLs
- bd sync: 2026-01-22 05:41:21
- Create baish fork with OpenAI ask builtin
- Update README with MCP feature documentation and build instructions
- Add test script and implementation summary documentation
- Fix memory safety issues in MCP implementation
- Add .gitignore and remove build artifacts from version control
- Add basic MCP builtin command with connect/disconnect/list subcommands
- Initial plan
- Initial checkin
- Merge pull request #1 from jordanhubbard/copilot/extract-bash-handbook-contents
- Fix extraction command to avoid nested directory
- Add bash handbook review and prepare bash source directory
- Initial plan
- Initial commit


- Remove checked-in LLM defaults
- Prevent ask hangs with timeouts and config guidance
- Improve ask builtin LLM diagnostics and preflight
- Document baish AI help and ignore build outputs
- Initial version
- Document baish AI config and support host-only base URLs
- bd sync: 2026-01-22 05:41:21
- Create baish fork with OpenAI ask builtin
- Update README with MCP feature documentation and build instructions
- Add test script and implementation summary documentation
- Fix memory safety issues in MCP implementation
- Add .gitignore and remove build artifacts from version control
- Add basic MCP builtin command with connect/disconnect/list subcommands
- Initial plan
- Initial checkin
- Merge pull request #1 from jordanhubbard/copilot/extract-bash-handbook-contents
- Fix extraction command to avoid nested directory
- Add bash handbook review and prepare bash source directory
- Initial plan
- Initial commit



### Added
- Automated release system with `make release` targets
- Comprehensive test infrastructure (unit tests, integration tests, mock servers)
- Security fixes for buffer overflows, JSON injection, and integer overflows
- Shared curl initialization system to prevent conflicts
- Named constants replacing magic numbers throughout codebase

### Changed
- Improved error handling and debug logging
- Enhanced documentation in README.md and code comments
- Better HTTP status parsing with bounds checking

### Fixed
- Critical curl initialization conflict between builtins (BEAD 21)
- Buffer overflow in MCP server name handling (BEAD 2)
- JSON injection vulnerability in ask builtin (BEAD 7)
- Integer overflow in round-robin model selection (BEAD 13)
- HTTP status parsing vulnerability (BEAD 19)

### Security
- All critical and high-severity security issues resolved
- 4/4 security tests passing
- Proper bounds checking on all user input

## Previous Work

This changelog tracks changes from the comprehensive code review and implementation
completed on 2026-01-26. See STEPS-1-5-COMPLETE.md for detailed history of initial
security fixes and improvements.
