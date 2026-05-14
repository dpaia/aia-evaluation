#!/usr/bin/env bash
# Installer for the aia-evaluation launcher.
#
# Fetches `aia-evaluation.sh` from the canonical location
# (`JetBrains/ai-assistant-pipelines` private GitHub repo) and installs it as
# `~/.local/bin/aia-evaluation` so users can invoke it directly:
#
#   curl -fsSL <SPACE_RAW_URL_TO_THIS_FILE> | bash
#   aia-evaluation --lang java --runner JUNIE_ACP --debug
#
# Configuration (env):
#   AIA_PREFIX   installation directory               (default: $HOME/.local/bin)
#   AIA_BRANCH   branch to pull aia-evaluation.sh from (default: local-run)
#   AIA_REPO     upstream repo                         (default: JetBrains/ai-assistant-pipelines)
#   GH_TOKEN     GitHub token (PAT or `gh auth token`); required.

set -euo pipefail

REPO="${AIA_REPO:-JetBrains/ai-assistant-pipelines}"
BRANCH="${AIA_BRANCH:-local-run}"
LAUNCHER_PATH_IN_REPO="executable/aia-evaluation.sh"
PREFIX="${AIA_PREFIX:-$HOME/.local/bin}"
TARGET="$PREFIX/aia-evaluation"

die() {
    echo "✗ $*" >&2
    exit 1
}

# 1. GitHub auth — same logic the launcher itself uses, so install and runtime
# share the same credential expectation.
AUTH_TOKEN=""
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    AUTH_TOKEN="$(gh auth token)"
elif [[ -n "${GH_TOKEN:-}" ]]; then
    if ! curl -fsS -H "Authorization: Bearer $GH_TOKEN" https://api.github.com/user >/dev/null; then
        die "GH_TOKEN is set but invalid or expired. Refresh it or run 'gh auth login'."
    fi
    AUTH_TOKEN="$GH_TOKEN"
else
    die "GitHub authentication missing. Run 'gh auth login' or 'export GH_TOKEN=<your_pat>' and re-run."
fi

# 2. Fetch the launcher source from the private repo.
mkdir -p "$PREFIX"
SOURCE_URL="https://api.github.com/repos/$REPO/contents/$LAUNCHER_PATH_IN_REPO?ref=$BRANCH"
echo "Downloading aia-evaluation launcher from $REPO@$BRANCH..."
curl -fsSL \
    -H "Authorization: Bearer $AUTH_TOKEN" \
    -H "Accept: application/vnd.github.raw" \
    -o "$TARGET" \
    "$SOURCE_URL" \
    || die "Failed to fetch $LAUNCHER_PATH_IN_REPO from $REPO ($BRANCH). Confirm the path, branch, and your access."
chmod +x "$TARGET"

echo "✓ Installed: $TARGET"

# 3. PATH sanity check — don't try to mutate the user's shell config; just hint.
case ":$PATH:" in
    *":$PREFIX:"*)
        echo "✓ $PREFIX is on your PATH"
        ;;
    *)
        echo ""
        echo "⚠ $PREFIX is not on your PATH."
        echo "  Add this line to your shell rc (~/.zshrc / ~/.bashrc):"
        echo ""
        echo "    export PATH=\"$PREFIX:\$PATH\""
        echo ""
        ;;
esac

echo ""
echo "Next step — run it:"
echo "    aia-evaluation --lang java --runner JUNIE_ACP --debug --debug-n-instances 1"
