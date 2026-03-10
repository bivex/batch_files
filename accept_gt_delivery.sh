@ -0,0 +1,63 @@
#!/usr/bin/env bash

set -euo pipefail

GT_REPO_DEFAULT="$HOME/gt/loreSystem/crew/password9090"
MAIN_REPO_DEFAULT="/Volumes/External/Code/loreSystem"

GT_REPO="${1:-$GT_REPO_DEFAULT}"
MAIN_REPO="${2:-$MAIN_REPO_DEFAULT}"

usage() {
    echo "Usage: $0 [gt_repo_path] [main_repo_path]"
    echo
    echo "Default GT repo:   $GT_REPO_DEFAULT"
    echo "Default main repo: $MAIN_REPO_DEFAULT"
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
fi

require_git_repo() {
    local repo_path="$1"
    if [[ ! -d "$repo_path" ]]; then
        echo "❌ Directory not found: $repo_path" >&2
        exit 1
    fi
    if ! git -C "$repo_path" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "❌ Not a git repo: $repo_path" >&2
        exit 1
    fi
}

show_repo_state() {
    local label="$1"
    local repo_path="$2"
    echo "== $label =="
    echo "path: $repo_path"
    git -C "$repo_path" status -sb
    echo
}

require_git_repo "$GT_REPO"
require_git_repo "$MAIN_REPO"

echo "=== Accept GT Delivery ==="
echo
show_repo_state "GT repo before push" "$GT_REPO"

echo ">>> git push ($GT_REPO)"
git -C "$GT_REPO" push
echo

show_repo_state "Main repo before pull" "$MAIN_REPO"

echo ">>> git pull --ff-only ($MAIN_REPO)"
git -C "$MAIN_REPO" pull --ff-only
echo

echo "=== Done ==="
echo "GT repo HEAD:   $(git -C "$GT_REPO" rev-parse --short HEAD)"
echo "Main repo HEAD: $(git -C "$MAIN_REPO" rev-parse --short HEAD)"
