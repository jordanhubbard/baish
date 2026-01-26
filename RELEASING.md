# Release Process for Baish

This document describes the automated release process for baish.

## Overview

Baish uses an automated release system modeled after nanolang's release automation. The system handles:

- Version number management
- Changelog generation
- Git tagging
- GitHub release creation
- Test execution before release

## Version Scheme

Baish uses the version scheme: `MAJOR.MINOR.PATCH-baish.BUILD`

Example: `5.3.0-baish.1`

- **MAJOR**: Major version (incremented for major releases)
- **MINOR**: Minor version (incremented for minor releases, reset to 0 on major)
- **PATCH**: Patch level (incremented for minor releases, reset to 0 on minor/major)
- **BUILD**: Build version (incremented for patch releases, reset to 1 on minor/major)

## Prerequisites

Before creating a release, ensure you have:

1. **GitHub CLI (`gh`)** installed and authenticated:
   ```bash
   brew install gh
   gh auth login
   ```

2. **Clean working directory**: All changes committed
3. **On main branch**: `git checkout main`
4. **Up to date with remote**: `git pull origin main`

## Creating a Release

There are three types of releases:

### 1. Patch Release (Most Common)

Increments the BUILD version for bug fixes and small improvements.

```bash
make release
```

Example: `5.3.0-baish.1` → `5.3.0-baish.2`

### 2. Minor Release

Increments the PATCH version for new features or significant improvements.

```bash
make release-minor
```

Example: `5.3.0-baish.2` → `5.3.1-baish.1`

### 3. Major Release

Increments the MAJOR or MINOR version for breaking changes or major milestones.

```bash
make release-major
```

Example: `5.3.1-baish.1` → `5.4.0-baish.1`

## What Happens During a Release

The automated release process performs these steps:

1. **Prerequisites Check**
   - Verifies `gh` CLI is installed
   - Ensures working directory is clean
   - Confirms you're on the main branch
   - Checks you're up to date with remote

2. **Version Calculation**
   - Reads current version from `src/version.h` and `src/patchlevel.h`
   - Calculates next version based on release type

3. **Version Files Update**
   - Updates `DISTVERSION` in `src/version.h`
   - Updates `BUILDVERSION` in `src/version.h`
   - Updates `PATCHLEVEL` in `src/patchlevel.h`

4. **Changelog Generation**
   - Generates changelog entry from git commits since last release
   - Updates `CHANGELOG.md` with new entry

5. **Test Execution**
   - Runs `make test` to ensure all tests pass
   - Aborts release if tests fail

6. **Git Commit & Tag**
   - Creates a version bump commit
   - Creates a git tag with the new version

7. **Push to Remote**
   - Pushes the commit to origin/main
   - Pushes the new tag

8. **GitHub Release**
   - Creates a GitHub release using `gh` CLI
   - Includes changelog entry in release notes

## Interactive vs Batch Mode

### Interactive Mode (Default)

The release script will prompt for confirmation at key steps:

```bash
make release
```

You'll be asked to confirm:
- Proceeding with the calculated version
- Pushing changes and creating the GitHub release

### Batch Mode

For CI/CD or automated releases, use batch mode to skip confirmations:

```bash
BATCH=1 make release
```

## Manual Release Process

If you need to create a release manually:

```bash
# 1. Update version files
vim src/version.h       # Update DISTVERSION and BUILDVERSION
vim src/patchlevel.h    # Update PATCHLEVEL

# 2. Update changelog
vim CHANGELOG.md

# 3. Run tests
make test

# 4. Commit changes
git add src/version.h src/patchlevel.h CHANGELOG.md
git commit -m "Bump version to X.Y.Z-baish.B"

# 5. Create tag
git tag -a X.Y.Z-baish.B -m "Release X.Y.Z-baish.B"

# 6. Push
git push origin main
git push origin X.Y.Z-baish.B

# 7. Create GitHub release
gh release create X.Y.Z-baish.B --title "Release X.Y.Z-baish.B" --notes "..."
```

## Troubleshooting

### "gh: command not found"

Install the GitHub CLI:

```bash
brew install gh
gh auth login
```

### "Working directory is not clean"

Commit or stash your changes:

```bash
git status
git add -A
git commit -m "Your commit message"
```

### "Not on main branch"

Switch to the main branch:

```bash
git checkout main
```

### "Tests failed"

Fix the failing tests before releasing:

```bash
make test
# Fix any failures
git add -A
git commit -m "Fix failing tests"
```

### "Local branch is not up to date with origin/main"

Pull or push to synchronize:

```bash
git pull origin main
# or
git push origin main
```

## Version File Locations

- **DISTVERSION**: `src/version.h` - Major.Minor (e.g., "5.3")
- **PATCHLEVEL**: `src/patchlevel.h` - Patch number (e.g., 0)
- **BUILDVERSION**: `src/version.h` - Build number (e.g., 1)

These files are automatically updated by the release script.

## Changelog Format

The `CHANGELOG.md` follows [Keep a Changelog](https://keepachangelog.com/) format with entries like:

```markdown
## [5.3.0-baish.2] - 2026-01-26

### Changes

- Fix buffer overflow in MCP builtin
- Add security improvements
- Update documentation
```

The release script automatically generates these entries from git commit messages.

## Best Practices

1. **Keep commits atomic**: One logical change per commit for better changelog generation
2. **Write clear commit messages**: They appear in the changelog
3. **Run tests before releasing**: Always verify with `make test` first
4. **Review the changelog**: Check the auto-generated entry makes sense
5. **Use semantic versioning**: Choose the appropriate release type

## Example Workflow

```bash
# 1. Ensure you're up to date
git checkout main
git pull origin main

# 2. Create a release
make release

# 3. Review the output
# - Check calculated version
# - Review changelog entry
# - Confirm tests pass

# 4. Confirm when prompted
# The script will:
# - Update version files
# - Update changelog
# - Run tests
# - Commit and tag
# - Push to GitHub
# - Create release

# 5. Verify the release
gh release view 5.3.0-baish.2
```

## References

- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)
- [GitHub CLI](https://cli.github.com/)
