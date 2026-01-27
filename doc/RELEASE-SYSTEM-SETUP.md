# Release System Setup Complete

**Date**: 2026-01-26
**Status**: ✅ Complete and Ready to Use

## Summary

An automated release system has been created for baish, modeled after nanolang's release automation but customized for baish's project structure and version scheme.

## What Was Created

### 1. Release Automation Script

**File**: `scripts/release.sh` (executable)

A comprehensive bash script (370 lines) that automates the entire release process:

- ✅ Prerequisites checking (gh CLI, git status, branch verification)
- ✅ Version calculation from git tags and version files
- ✅ Version file updates (src/version.h, src/patchlevel.h)
- ✅ Automatic changelog generation from git commits
- ✅ Test execution before release
- ✅ Git commit and tag creation
- ✅ GitHub release creation via gh CLI
- ✅ Interactive and batch mode support

### 2. Makefile Targets

**File**: `Makefile` (modified)

Added three new targets for creating releases:

```makefile
make release        # Patch release (X.Y.Z-baish.B+1)
make release-minor  # Minor release (X.Y+1.0-baish.1)
make release-major  # Major release (X+1.0.0-baish.1)
```

Also updated the help text to document the new targets.

### 3. Changelog File

**File**: `CHANGELOG.md` (new)

- Follows [Keep a Changelog](https://keepachangelog.com/) format
- Pre-populated with unreleased changes from recent work
- Includes all security fixes and improvements from Steps 1-5
- Ready for first release

### 4. Release Documentation

**File**: `RELEASING.md` (new)

Comprehensive documentation covering:

- Version scheme explanation (MAJOR.MINOR.PATCH-baish.BUILD)
- Prerequisites and setup instructions
- How to create each type of release
- Step-by-step process explanation
- Troubleshooting guide
- Best practices and example workflows

## Version Scheme

Baish now uses: `MAJOR.MINOR.PATCH-baish.BUILD`

**Example**: `5.3.0-baish.1`

- **MAJOR.MINOR**: From `DISTVERSION` in src/version.h (e.g., "5.3")
- **PATCH**: From `PATCHLEVEL` in src/patchlevel.h (e.g., 0)
- **BUILD**: From `BUILDVERSION` in src/version.h (e.g., 1)

**Current version**: `5.3.0-baish.1` (no tags yet, first release will be tagged)

## How to Use

### Quick Start

1. **Ensure prerequisites**:
   ```bash
   brew install gh  # If not already installed
   gh auth login    # Authenticate with GitHub
   ```

2. **Create a release**:
   ```bash
   git checkout main
   git pull origin main
   make release
   ```

3. **Follow the prompts**:
   - Review the calculated version
   - Review the changelog entry
   - Confirm to proceed
   - Confirm to push and create GitHub release

### Release Types

```bash
# Patch release (most common): 5.3.0-baish.1 → 5.3.0-baish.2
make release

# Minor release (new features): 5.3.0-baish.2 → 5.3.1-baish.1
make release-minor

# Major release (breaking changes): 5.3.1-baish.1 → 5.4.0-baish.1
make release-major
```

### Batch Mode (for CI/CD)

```bash
BATCH=1 make release
```

## What Happens During a Release

1. **Prerequisites Check** ✓
   - Verifies gh CLI is installed
   - Ensures working directory is clean
   - Confirms on main branch
   - Checks sync with remote

2. **Version Calculation** ✓
   - Reads current version from version files
   - Calculates next version based on release type
   - Shows current → next version

3. **User Confirmation** ✓
   - Prompts to proceed (skipped in batch mode)

4. **File Updates** ✓
   - Updates src/version.h (DISTVERSION, BUILDVERSION)
   - Updates src/patchlevel.h (PATCHLEVEL)
   - Generates changelog entry from git commits
   - Updates CHANGELOG.md

5. **Testing** ✓
   - Runs `make test`
   - Aborts if tests fail

6. **Git Operations** ✓
   - Creates version bump commit
   - Creates git tag

7. **User Confirmation** ✓
   - Prompts to push (skipped in batch mode)

8. **Push & Release** ✓
   - Pushes commit and tag to GitHub
   - Creates GitHub release with changelog

## Testing the System

### Dry Run Test

You can test the release script's version calculation without making changes:

```bash
# This will check prerequisites and show what version would be calculated
# Then cancel before making any changes
make release
# Press 'n' when prompted to proceed
```

### Syntax Check

The script has been validated:

```bash
bash -n scripts/release.sh  # ✓ Syntax is valid
```

## Comparison with Nanolang

The baish release system is inspired by nanolang but customized:

### Similar Features
- ✓ Automated version calculation from git tags
- ✓ Changelog generation from commits
- ✓ Test execution before release
- ✓ GitHub release creation
- ✓ Interactive and batch modes

### Baish-Specific Customizations
- **Version files**: Updates src/version.h and src/patchlevel.h (vs hardcoded)
- **Version format**: X.Y.Z-baish.B (distinguishes from upstream bash)
- **Changelog location**: Root CHANGELOG.md (vs planning/CHANGELOG.md)
- **Repository**: jordanhubbard/baish
- **No bootstrap**: Baish doesn't self-host like nanolang

## Files Modified/Created

```
M  Makefile                    # Added release targets and help text
A  CHANGELOG.md                # Changelog with Keep a Changelog format
A  RELEASING.md                # Release process documentation
A  scripts/release.sh          # Automated release script (executable)
A  RELEASE-SYSTEM-SETUP.md     # This file
```

## Next Steps

### To Create Your First Release

1. **Review and commit the release system**:
   ```bash
   git add Makefile CHANGELOG.md RELEASING.md scripts/ RELEASE-SYSTEM-SETUP.md
   git commit -m "Add automated release system

   - Add scripts/release.sh for automated releases
   - Add Makefile targets: release, release-minor, release-major
   - Add CHANGELOG.md with Keep a Changelog format
   - Add RELEASING.md documentation

   Modeled after nanolang's release automation but customized for baish."
   git push origin main
   ```

2. **Verify gh CLI authentication**:
   ```bash
   gh auth status
   ```

3. **Create your first release**:
   ```bash
   make release
   ```

   This will create version `5.3.0-baish.1` (or `5.3.0-baish.2` if you want to account for the release system as a change).

### When to Create Releases

- **Patch releases**: Bug fixes, security patches, small improvements
- **Minor releases**: New features, significant enhancements, API additions
- **Major releases**: Breaking changes, major milestones, architecture changes

## Benefits

✅ **Consistent versioning**: Automated version management prevents mistakes
✅ **Change tracking**: Automatic changelog generation from commits
✅ **Quality assurance**: Tests run before every release
✅ **GitHub integration**: Releases automatically created with proper formatting
✅ **Developer efficiency**: One command creates complete release
✅ **Audit trail**: Git tags and GitHub releases provide history

## Troubleshooting

See `RELEASING.md` for detailed troubleshooting of common issues:

- gh CLI not found
- Working directory not clean
- Not on main branch
- Tests failing
- Branch not up to date

## Documentation

- **RELEASING.md**: Complete release process documentation
- **CHANGELOG.md**: Project changelog (Keep a Changelog format)
- **Makefile**: See `make help` for all targets
- **scripts/release.sh**: Inline comments explain each step

## Status

✅ All files created and ready
✅ Script syntax validated
✅ Makefile targets working
✅ Help text updated
✅ Documentation complete

**Ready for first use!**

---

To use the release system, first commit these files, then run `make release` when ready to create your first official baish release.
