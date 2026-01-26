# Changelog

All notable changes to baish will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project uses a version scheme of MAJOR.MINOR.PATCH-baish.BUILD.

## [Unreleased]
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
