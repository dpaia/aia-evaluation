# aia-evaluation

Lightweight bootstrap installer for running the AIA agentic evaluation
pipelines.

This repo contains only **one** file:

- **`install.sh`** — downloads the launcher from its canonical upstream
  location and installs it into `~/.local/bin/` as the `aia-evaluation`
  command.

The launcher itself, plus the per-platform `.pyz` files it fetches, live
upstream. There is no duplication or sync.

---

## Prerequisites

1. **Python 3.12** on `PATH` — `brew install python@3.12` or `uv python install 3.12`.
2. **GitHub authentication for the JetBrains org** — either an active
   `gh auth login` session **or** `GH_TOKEN` exported in your shell. Any PAT
   that grants you access to the JetBrains GitHub organization works; no
   special per-repo permissions are needed.

   Required both at install time (to pull the launcher script) and at runtime
   (to pull the `.pyz`).

---

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/dpaia/aia-evaluation/main/install.sh | bash
```

---

## Usage

CLI flags are forwarded directly to the upstream agentic pipeline:

```bash
aia-evaluation --lang java --runner JUNIE_ACP --debug
aia-evaluation --lang python --runner CLAUDE_CODE --debug-n-instances 1
aia-evaluation --lang csharp --runner GOLDEN --debug
```

Required flags (the launcher errors out fast otherwise):

- `--lang java|kotlin|python|go|csharp` — must target a specific language; `all` is rejected.
- `--runner <NAME>` — see `aia-evaluation --help` for the supported list.

If you don't pass `--dataset-tag`, the launcher injects `--dataset-tag default_agent`
automatically. Any value you pass is respected as-is.

---

## What happens on first run

1. Verifies `python3.12` is on `PATH`.
2. Verifies your GitHub auth (`gh auth status` or `GH_TOKEN`).
3. Detects your platform via `uname -sm` and composes
   `aia-evaluation-<os>-<arch>.pyz`.
4. Downloads the matching `.pyz` (with progress bar) and a tiny `VERSION` file
   into `~/.cache/aia-evaluation/`.
5. Executes the `.pyz`, which:
   - Validates `--lang` / injects `--dataset-tag default_agent` if needed.
   - Self-heals ZenML state (runs `zenml login jcp-prod` /
     `zenml project set ai-assistant` / `zenml stack set …` for you, using
     the bundled `zenml` CLI inside the `.pyz`).
   - Runs the actual agentic pipeline.

## What happens on subsequent runs

Only the small `VERSION` file (~40 bytes) is fetched. If it matches the cached
copy, the cached `.pyz` is reused — no re-download. If a newer build is
available upstream, the launcher refreshes the `.pyz` transparently and shows
a progress bar.

---

## Supported platforms

Pre-built `.pyz` files exist for:

| `uname -sm`            | Asset                                |
|------------------------|--------------------------------------|
| `Linux x86_64`         | `aia-evaluation-linux-x86_64.pyz`    |
| `Darwin arm64`         | `aia-evaluation-darwin-arm64.pyz`    |

Other host platforms (Intel Mac, Linux ARM, Windows) aren't built. Running
`aia-evaluation` on those produces a clear "release does not contain asset
…" error. If you need another target, file a request upstream.

---

## Updating

Re-run the install command — `install.sh` overwrites the launcher with the
latest copy from the upstream default branch. The `.pyz` itself is
auto-updated on every invocation when upstream publishes a new build (the
launcher compares the cached `VERSION` against the release's `VERSION`).

## Uninstalling

```bash
rm ~/.local/bin/aia-evaluation
rm -rf ~/.cache/aia-evaluation
```

---

## Install options

### Verifying the install

The installer drops `aia-evaluation` into `~/.local/bin/`. If that directory
isn't on your `PATH`, the script prints exactly what to add to your
`~/.zshrc` / `~/.bashrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

After sourcing your shell config (or opening a fresh terminal), confirm:

```bash
which aia-evaluation
# → /Users/<you>/.local/bin/aia-evaluation
```

### Installing to a different directory

```bash
AIA_PREFIX=/usr/local/bin curl -fsSL https://raw.githubusercontent.com/dpaia/aia-evaluation/main/install.sh | bash
```

### Pinning to a specific branch (for testing)

The default branch (`launcher` for now) can be overridden:

```bash
AIA_BRANCH=main curl -fsSL https://raw.githubusercontent.com/dpaia/aia-evaluation/main/install.sh | bash
```

---

## Why a JetBrains-only upstream and a public installer?

The pipeline code lives in a JetBrains-internal repo, which is why anything
that touches it (the launcher source, the `.pyz`) needs GitHub auth against
the JetBrains org. This installer repo (`dpaia/aia-evaluation`) is intentionally
public so that anyone can fetch the bootstrap `install.sh` anonymously — past
the bootstrap step the same `GH_TOKEN` / `gh` session powers both install and
runtime.
