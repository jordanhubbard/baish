#!/usr/bin/env bash
# Automated release script for baish
# Adapted from nanolang's release automation
# Usage: ./scripts/release.sh [patch|minor|major]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
REPO="jordanhubbard/baish"
MAIN_BRANCH="main"
VERSION_H="src/version.h"
PATCHLEVEL_H="src/patchlevel.h"
CHANGELOG="CHANGELOG.md"

# Check if running in batch mode
BATCH_MODE="${BATCH:-0}"

# Helper functions
error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}Warning: $1${NC}" >&2
}

info() {
    echo -e "${GREEN}$1${NC}"
}

confirm() {
    if [ "$BATCH_MODE" = "1" ]; then
        return 0
    fi

    local prompt="$1"
    local response
    read -p "$prompt [y/N] " response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Check prerequisites
check_prerequisites() {
    info "Checking prerequisites..."

    # Check for gh CLI
    if ! command -v gh &> /dev/null; then
        error "GitHub CLI (gh) is not installed. Install it from https://cli.github.com/"
    fi

    # Check for git
    if ! command -v git &> /dev/null; then
        error "git is not installed"
    fi

    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        error "Not in a git repository"
    fi

    # Check if working directory is clean
    if ! git diff-index --quiet HEAD --; then
        error "Working directory is not clean. Commit or stash your changes first."
    fi

    # Check if we're on the main branch
    current_branch=$(git branch --show-current)
    if [ "$current_branch" != "$MAIN_BRANCH" ]; then
        error "Not on $MAIN_BRANCH branch (current: $current_branch)"
    fi

    # Check if we're up to date with remote
    git fetch origin
    local_commit=$(git rev-parse HEAD)
    remote_commit=$(git rev-parse origin/$MAIN_BRANCH)
    if [ "$local_commit" != "$remote_commit" ]; then
        error "Local branch is not up to date with origin/$MAIN_BRANCH. Pull or push first."
    fi

    info "✓ All prerequisites met"
}

# Get current version from version files
get_current_version() {
    local distversion=$(grep '#define DISTVERSION' "$VERSION_H" | awk '{print $3}' | tr -d '"')
    local patchlevel=$(grep '#define PATCHLEVEL' "$PATCHLEVEL_H" | awk '{print $3}')
    local buildversion=$(grep '#define BUILDVERSION' "$VERSION_H" | awk '{print $3}')

    echo "${distversion}.${patchlevel}-baish.${buildversion}"
}

# Get the latest git tag
get_latest_tag() {
    git tag -l | grep -E '^[0-9]+\.[0-9]+\.[0-9]+-baish\.[0-9]+$' | sort -V | tail -n1
}

# Calculate next version based on release type
calculate_next_version() {
    local release_type="$1"
    local latest_tag=$(get_latest_tag)

    if [ -z "$latest_tag" ]; then
        # No tags yet, start from current version
        latest_tag=$(get_current_version)
    fi

    # Parse version: X.Y.Z-baish.B
    local version_regex='^([0-9]+)\.([0-9]+)\.([0-9]+)-baish\.([0-9]+)$'
    if [[ $latest_tag =~ $version_regex ]]; then
        local major="${BASH_REMATCH[1]}"
        local minor="${BASH_REMATCH[2]}"
        local patch="${BASH_REMATCH[3]}"
        local build="${BASH_REMATCH[4]}"
    else
        error "Cannot parse version from tag: $latest_tag"
    fi

    case "$release_type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            build=1
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            build=1
            ;;
        patch)
            build=$((build + 1))
            ;;
        *)
            error "Invalid release type: $release_type (must be major, minor, or patch)"
            ;;
    esac

    echo "${major}.${minor}.${patch}-baish.${build}"
}

# Update version files
update_version_files() {
    local version="$1"

    # Parse version: X.Y.Z-baish.B
    local version_regex='^([0-9]+)\.([0-9]+)\.([0-9]+)-baish\.([0-9]+)$'
    if [[ $version =~ $version_regex ]]; then
        local major="${BASH_REMATCH[1]}"
        local minor="${BASH_REMATCH[2]}"
        local patch="${BASH_REMATCH[3]}"
        local build="${BASH_REMATCH[4]}"
    else
        error "Cannot parse version: $version"
    fi

    local distversion="${major}.${minor}"

    info "Updating version files..."
    info "  DISTVERSION: $distversion"
    info "  PATCHLEVEL: $patch"
    info "  BUILDVERSION: $build"

    # Update src/version.h
    sed -i.bak "s/#define DISTVERSION \".*\"/#define DISTVERSION \"$distversion\"/" "$VERSION_H"
    sed -i.bak "s/#define BUILDVERSION [0-9]*/#define BUILDVERSION $build/" "$VERSION_H"
    rm -f "${VERSION_H}.bak"

    # Update src/patchlevel.h
    sed -i.bak "s/#define PATCHLEVEL [0-9]*/#define PATCHLEVEL $patch/" "$PATCHLEVEL_H"
    rm -f "${PATCHLEVEL_H}.bak"

    info "✓ Version files updated"
}

# Generate changelog entry from git commits
generate_changelog_entry() {
    local version="$1"
    local previous_tag="$2"
    local date=$(date +%Y-%m-%d)

    local entry="## [$version] - $date\n\n"

    # Get commits since last tag
    local commits
    if [ -n "$previous_tag" ]; then
        commits=$(git log --pretty=format:"- %s" "${previous_tag}..HEAD")
    else
        commits=$(git log --pretty=format:"- %s")
    fi

    if [ -n "$commits" ]; then
        entry="${entry}### Changes\n\n${commits}\n"
    else
        entry="${entry}### Changes\n\n- Initial release\n"
    fi

    echo -e "$entry"
}

# Update CHANGELOG.md
update_changelog() {
    local version="$1"
    local previous_tag=$(get_latest_tag)

    info "Generating changelog entry..."

    # Create CHANGELOG.md if it doesn't exist
    if [ ! -f "$CHANGELOG" ]; then
        cat > "$CHANGELOG" << 'EOF'
# Changelog

All notable changes to baish will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project uses a version scheme of MAJOR.MINOR.PATCH-baish.BUILD.

EOF
    fi

    # Generate new entry
    local new_entry=$(generate_changelog_entry "$version" "$previous_tag")

    # Insert new entry after the header
    local temp_file=$(mktemp)
    awk -v entry="$new_entry" '
        /^# Changelog/ { print; getline; print; print entry; next }
        { print }
    ' "$CHANGELOG" > "$temp_file"

    mv "$temp_file" "$CHANGELOG"

    info "✓ Changelog updated"
}

# Run tests
run_tests() {
    info "Running tests..."

    if ! make test; then
        error "Tests failed. Fix the issues before releasing."
    fi

    info "✓ Tests passed"
}

# Create git commit for version bump
create_version_commit() {
    local version="$1"

    info "Creating version bump commit..."

    git add "$VERSION_H" "$PATCHLEVEL_H" "$CHANGELOG"
    git commit -m "Bump version to $version

- Update DISTVERSION, PATCHLEVEL, and BUILDVERSION
- Update CHANGELOG.md

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

    info "✓ Version bump committed"
}

# Create git tag
create_git_tag() {
    local version="$1"

    info "Creating git tag $version..."

    git tag -a "$version" -m "Release $version"

    info "✓ Git tag created"
}

# Push changes to remote
push_changes() {
    local version="$1"

    info "Pushing changes to remote..."

    git push origin "$MAIN_BRANCH"
    git push origin "$version"

    info "✓ Changes pushed to remote"
}

# Create GitHub release
create_github_release() {
    local version="$1"

    info "Creating GitHub release..."

    # Extract changelog entry for this version
    local release_notes=$(awk -v ver="$version" '
        /^## \[/ {
            if (found) exit
            if ($0 ~ ver) found=1
            next
        }
        found { print }
    ' "$CHANGELOG")

    # Create release with gh CLI
    echo "$release_notes" | gh release create "$version" \
        --title "Release $version" \
        --notes-file - \
        --repo "$REPO"

    info "✓ GitHub release created"
}

# Main release flow
main() {
    local release_type="${1:-patch}"

    echo "====================================="
    echo "  Baish Release Automation"
    echo "====================================="
    echo

    # Validate release type
    if [[ ! "$release_type" =~ ^(major|minor|patch)$ ]]; then
        error "Usage: $0 [major|minor|patch]"
    fi

    # Check prerequisites
    check_prerequisites

    # Calculate next version
    local current_version=$(get_current_version)
    local next_version=$(calculate_next_version "$release_type")

    echo
    info "Release type: $release_type"
    info "Current version: $current_version"
    info "Next version: $next_version"
    echo

    # Confirm with user (unless in batch mode)
    if ! confirm "Proceed with release $next_version?"; then
        info "Release cancelled"
        exit 0
    fi

    echo

    # Update version files
    update_version_files "$next_version"

    # Update changelog
    update_changelog "$next_version"

    # Run tests
    run_tests

    # Create version commit
    create_version_commit "$next_version"

    # Create git tag
    create_git_tag "$next_version"

    # Confirm push (unless in batch mode)
    echo
    if ! confirm "Push changes and create GitHub release?"; then
        warning "Changes committed and tagged locally but not pushed"
        info "To push manually: git push origin $MAIN_BRANCH && git push origin $next_version"
        exit 0
    fi

    # Push changes
    push_changes "$next_version"

    # Create GitHub release
    create_github_release "$next_version"

    echo
    echo "====================================="
    info "✓ Release $next_version complete!"
    echo "====================================="
    echo
    info "View release at: https://github.com/$REPO/releases/tag/$next_version"
    echo
}

# Run main function
main "$@"
