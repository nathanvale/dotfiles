#!/bin/bash
# monorepo-detect.sh - Smart monorepo detection and package discovery
# Supports: pnpm, lerna, nx, yarn, cargo, go workspaces

# Detect monorepo type by checking for config files
detect_monorepo_type() {
    local project_path="$1"

    [ -f "$project_path/pnpm-workspace.yaml" ] && echo "pnpm" && return 0
    [ -f "$project_path/lerna.json" ] && echo "lerna" && return 0
    [ -f "$project_path/nx.json" ] && echo "nx" && return 0
    [ -f "$project_path/Cargo.toml" ] && grep -q '^\[workspace\]' "$project_path/Cargo.toml" && echo "cargo" && return 0
    [ -f "$project_path/go.work" ] && echo "go" && return 0
    [ -f "$project_path/package.json" ] && grep -q '"workspaces"' "$project_path/package.json" && echo "yarn" && return 0

    return 1
}

# Get list of package directories for detected monorepo type
get_monorepo_packages() {
    local project_path="$1"
    local monorepo_type="$2"

    case "$monorepo_type" in
        "pnpm")
            # Extract from pnpm-workspace.yaml
            if [ -f "$project_path/pnpm-workspace.yaml" ]; then
                # Read workspace patterns and expand them
                grep -E "^\s+-\s+" "$project_path/pnpm-workspace.yaml" | \
                    sed "s/.*-\s*//" | \
                    sed "s/['\"]//g" | \
                    sed 's/^\s*//' | \
                    sed 's/\s*$//' | \
                    while read pattern; do
                        [ -z "$pattern" ] && continue
                        # Remove trailing /* if present
                        pattern="${pattern%/\*}"
                        # Find directories matching the pattern
                        if [ -d "$project_path/$pattern" ]; then
                            # If pattern is a directory, list its subdirectories
                            find "$project_path/$pattern" -maxdepth 1 -mindepth 1 -type d 2>/dev/null
                        else
                            # Try to match as a glob pattern
                            local parent_dir
                            parent_dir=$(dirname "$project_path/$pattern")
                            if [ -d "$parent_dir" ]; then
                                find "$parent_dir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null
                            fi
                        fi
                    done | sort -u
            fi
            ;;
        "lerna")
            # Extract from lerna.json packages array
            if [ -f "$project_path/lerna.json" ]; then
                jq -r '.packages[]?' "$project_path/lerna.json" 2>/dev/null | while read pattern; do
                    # Remove trailing * if present
                    pattern="${pattern%/\*}"
                    if [ -d "$project_path/$pattern" ]; then
                        find "$project_path/$pattern" -maxdepth 1 -mindepth 1 -type d 2>/dev/null
                    fi
                done | sort -u
            fi
            ;;
        "nx")
            # NX projects in apps/ libs/ or packages/
            {
                [ -d "$project_path/apps" ] && find "$project_path/apps" -maxdepth 1 -mindepth 1 -type d 2>/dev/null
                [ -d "$project_path/libs" ] && find "$project_path/libs" -maxdepth 1 -mindepth 1 -type d 2>/dev/null
                [ -d "$project_path/packages" ] && find "$project_path/packages" -maxdepth 1 -mindepth 1 -type d 2>/dev/null
            } | sort -u
            ;;
        "yarn")
            # Yarn workspaces - read from package.json
            if [ -f "$project_path/package.json" ]; then
                jq -r '.workspaces[]?' "$project_path/package.json" 2>/dev/null | while read pattern; do
                    # Remove trailing * if present
                    pattern="${pattern%/\*}"
                    if [ -d "$project_path/$pattern" ]; then
                        find "$project_path/$pattern" -maxdepth 1 -mindepth 1 -type d 2>/dev/null
                    fi
                done | sort -u
            else
                # Fallback to common patterns
                {
                    [ -d "$project_path/packages" ] && find "$project_path/packages" -maxdepth 1 -mindepth 1 -type d 2>/dev/null
                    [ -d "$project_path/apps" ] && find "$project_path/apps" -maxdepth 1 -mindepth 1 -type d 2>/dev/null
                } | sort -u
            fi
            ;;
        "cargo")
            # Rust workspace members
            if [ -f "$project_path/Cargo.toml" ]; then
                # Extract workspace members from Cargo.toml
                awk '/^\[workspace\]/,/^\[/ {print}' "$project_path/Cargo.toml" | \
                    grep -E 'members\s*=' | \
                    sed 's/.*\[\s*//' | \
                    sed 's/\s*\].*//' | \
                    tr ',' '\n' | \
                    sed 's/[" ]//g' | \
                    while read member; do
                        [ -n "$member" ] && [ -d "$project_path/$member" ] && echo "$project_path/$member"
                    done | sort -u
            fi
            ;;
        "go")
            # Go workspace directories (go.work format)
            if [ -f "$project_path/go.work" ]; then
                grep -E '^use\s+' "$project_path/go.work" | awk '{print $2}' | while read dir; do
                    [ -d "$project_path/$dir" ] && echo "$project_path/$dir"
                done | sort -u
            fi
            ;;
    esac
}

# Find docs folders in a package with smart filtering
find_package_docs() {
    local package_path="$1"

    # Look for docs in common locations
    find "$package_path" -type d \( -name "docs" -o -name "documentation" -o -name "wiki" \) \
        ! -path "*/node_modules/*" \
        ! -path "*/.git/*" \
        ! -path "*/dist/*" \
        ! -path "*/build/*" \
        ! -path "*/.next/*" \
        ! -path "*/coverage/*" \
        ! -path "*/test/*" \
        -maxdepth 2 \
        2>/dev/null | sort -u
}

# Find .agent-os or equivalent in package
find_package_agent_os() {
    local package_path="$1"

    [ -d "$package_path/.agent-os" ] && echo "$package_path/.agent-os" && return 0
    [ -d "$package_path/.aos" ] && echo "$package_path/.aos" && return 0

    return 1
}

# Get package name from package directory
get_package_name() {
    local package_path="$1"
    local monorepo_type="$2"

    case "$monorepo_type" in
        "pnpm"|"yarn"|"lerna"|"nx")
            # Try to read package.json name
            if [ -f "$package_path/package.json" ]; then
                local pkg_name
                pkg_name=$(jq -r '.name // empty' "$package_path/package.json" 2>/dev/null)
                if [ -n "$pkg_name" ]; then
                    echo "$pkg_name"
                    return 0
                fi
            fi
            ;;
        "cargo")
            # Try to read Cargo.toml name
            if [ -f "$package_path/Cargo.toml" ]; then
                local pkg_name
                pkg_name=$(grep -E '^\[package\]' -A 10 "$package_path/Cargo.toml" | grep '^name\s*=' | sed 's/.*=\s*"\(.*\)".*/\1/' | head -1)
                if [ -n "$pkg_name" ]; then
                    echo "$pkg_name"
                    return 0
                fi
            fi
            ;;
        "go")
            # Try to read go.mod module name
            if [ -f "$package_path/go.mod" ]; then
                local pkg_name
                pkg_name=$(grep '^module ' "$package_path/go.mod" | awk '{print $2}' | head -1)
                if [ -n "$pkg_name" ]; then
                    echo "$pkg_name"
                    return 0
                fi
            fi
            ;;
    esac

    # Fallback to directory name
    basename "$package_path"
}

# Check if package has vaultable content
package_has_vault_content() {
    local package_path="$1"

    # Check for .agent-os or docs
    [ -d "$package_path/.agent-os" ] && return 0
    [ -d "$package_path/.aos" ] && return 0
    [ -d "$package_path/docs" ] && return 0
    [ -d "$package_path/documentation" ] && return 0
    [ -d "$package_path/wiki" ] && return 0

    return 1
}

# Generate package display info for fzf
# Format: "[status] package-name (docs: X, agent-os: Y) - /path/to/package"
generate_package_display() {
    local package_path="$1"
    local package_name="$2"
    local is_registered="$3"
    local monorepo_type="${4:-}"

    local status="[ ]"
    [ "$is_registered" = "true" ] && status="[✓]"

    local has_docs="❌"
    local has_aos="❌"

    if [ -d "$package_path/docs" ] || [ -d "$package_path/documentation" ] || [ -d "$package_path/wiki" ]; then
        has_docs="✅"
    fi

    if [ -d "$package_path/.agent-os" ] || [ -d "$package_path/.aos" ]; then
        has_aos="✅"
    fi

    echo "${status} ${package_name}${CYAN}  (docs: ${has_docs}, agent-os: ${has_aos})${NC} - ${package_path}"
}
