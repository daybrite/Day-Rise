#!/usr/bin/env bash
# Day-Rise is a REFERENCE COPY of `day new` output. This script regenerates that output with the
# same parameters this checkout was created with, and reports every place the two disagree.
#
#   scripts/scaffold-drift.sh                    # check, using $DAY_BIN or `day` from PATH
#   scripts/scaffold-drift.sh --local            # build day-cli from ../day and use that
#   scripts/scaffold-drift.sh --local ~/src/day  # ...from somewhere else
#   scripts/scaffold-drift.sh --day-cli ./day    # use one specific binary
#   scripts/scaffold-drift.sh --merge            # rewrite this checkout to match the scaffold
#
# `--local` is the loop for working ON the template: edit
# `day/crates/day-cli/templates/app/`, rerun with `--local`, and see what a fresh scaffold would
# now produce — no `cargo install`, and nothing published. The template is EMBEDDED in the CLI at
# compile time, so the build this does is what makes an edit visible at all.
#
# The CI job in .github/workflows/ci.yml calls this script, so what runs there and what runs here
# are the same code; a green run locally means a green run there.

set -euo pipefail

# ---------------------------------------------------------------------------------------------
# Paths that are never compared.
#
#   .git/       not source.
#   .github/    `day new` scaffolds no workflow, so the CI file would report itself forever.
#   scripts/    this script, likewise: `day new` does not produce it.
#   Cargo.lock  `day new` emits no lock at all, and this repository does not commit one either
#               (it tracks day's main, so the preflight resolves the lock itself — see ci.yml).
#               A local `day patch --local` build still WRITES one, pointing at the developer's
#               own day checkout, so it turns up here untracked and must not read as drift. The
#               repo root's exactly — the scaffold is a single cargo workspace, so a lock
#               elsewhere would be real drift.
# ---------------------------------------------------------------------------------------------
is_excluded() {
  case "$1" in
    .git/* | .github/* | scripts/* | Cargo.lock) return 0 ;;
    *) return 1 ;;
  esac
}

usage() {
  sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

MERGE=0
FORCE=0
DAY_CLI=""
LOCAL_REPO=""
USE_LOCAL=0

while [ $# -gt 0 ]; do
  case "$1" in
    --merge) MERGE=1; shift ;;
    --force) FORCE=1; shift ;;
    --day-cli)
      [ $# -ge 2 ] || { echo "error: --day-cli needs a path" >&2; exit 2; }
      DAY_CLI="$2"; shift 2 ;;
    --local)
      USE_LOCAL=1
      # Optional argument: a following token that is not another flag is the day checkout.
      if [ $# -ge 2 ] && case "$2" in -*) false ;; *) true ;; esac; then
        LOCAL_REPO="$2"; shift 2
      else
        shift
      fi ;;
    -h | --help) usage 0 ;;
    *) echo "error: unknown argument: $1" >&2; usage 2 ;;
  esac
done

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

command -v python3 >/dev/null 2>&1 || {
  echo "error: python3 is required (it reads Day.toml/Cargo.toml)" >&2
  exit 1
}

# ---------------------------------------------------------------------------------------------
# The scaffold parameters, read back out of the manifests rather than written here. A literal
# would be a second source of truth, and the first time someone retitled the app the check would
# report drift that is really just a different invocation.
# ---------------------------------------------------------------------------------------------
#
# Written to a file and sourced rather than `eval "$(python3 <<PY …)"`: a here-document whose body
# contains `"` and `)` — this one is full of both — is mis-parsed inside a double-quoted command
# substitution, and the symptom is not a clean error but python running several times and its
# output word-split into nonsense.
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

python3 - > "$WORK/meta.sh" <<'PY'
import pathlib, re, shlex

def scalar(path, section, key):
    text = pathlib.Path(path).read_text()
    m = re.search(r"^\[" + re.escape(section) + r"\]\s*$(.*?)(?=^\[|\Z)", text, re.M | re.S)
    body = m.group(1) if m else text
    m = re.search(r'^\s*' + re.escape(key) + r'\s*=\s*"([^"]*)"', body, re.M)
    return m.group(1) if m else ""

toml = pathlib.Path("Day.toml").read_text()
m = re.search(r"^targets\s*=\s*\[(.*?)\]", toml, re.S | re.M)
targets = ",".join(re.findall(r'"([^"]+)"', m.group(1))) if m else ""

print(f"APP_NAME={shlex.quote(scalar('Cargo.toml', 'package', 'name'))}")
print(f"APP_TITLE={shlex.quote(scalar('Day.toml', 'app', 'title'))}")
print(f"APP_ID={shlex.quote(scalar('Day.toml', 'app', 'id'))}")
print(f"TARGETS={shlex.quote(targets)}")
PY

# shellcheck source=/dev/null
. "$WORK/meta.sh"

for v in APP_NAME APP_TITLE APP_ID TARGETS; do
  eval "val=\${$v}"
  [ -n "$val" ] || { echo "error: could not read $v from Day.toml/Cargo.toml" >&2; exit 1; }
done

# ---------------------------------------------------------------------------------------------
# Which day CLI. Explicit beats built-from-source beats the environment beats PATH.
# ---------------------------------------------------------------------------------------------
if [ -n "$DAY_CLI" ]; then
  [ -x "$DAY_CLI" ] || { echo "error: $DAY_CLI is not executable" >&2; exit 1; }
  DAY_CLI="$(cd "$(dirname "$DAY_CLI")" && pwd)/$(basename "$DAY_CLI")"
elif [ "$USE_LOCAL" -eq 1 ]; then
  REPO="${LOCAL_REPO:-$ROOT/../day}"
  [ -f "$REPO/crates/day-cli/Cargo.toml" ] || {
    echo "error: no day checkout at $REPO (expected crates/day-cli/Cargo.toml)" >&2
    exit 1
  }
  REPO="$(cd "$REPO" && pwd)"
  command -v cargo >/dev/null 2>&1 || { echo "error: cargo is not on PATH" >&2; exit 1; }
  echo "> building day-cli from $REPO"
  # Unconditional: "if needed" is cargo's call, and a stale binary would compare this checkout
  # against a template edit that is not in it yet — the exact question --local exists to answer.
  # Run from the day repo so cargo reads THAT workspace's config, not this project's.
  (cd "$REPO" && cargo build -q -p day-cli)
  DAY_CLI="${CARGO_TARGET_DIR:-$REPO/target}/debug/day"
  [ -x "$DAY_CLI" ] || {
    echo "error: cargo reported success but $DAY_CLI is missing" >&2
    echo "       (CARGO_TARGET_DIR, or a build.target-dir config pointing elsewhere?)" >&2
    exit 1
  }
elif [ -n "${DAY_BIN:-}" ]; then
  DAY_CLI="$DAY_BIN"
else
  command -v day >/dev/null 2>&1 || {
    echo "error: no day CLI — pass --day-cli PATH, use --local, or install one" >&2
    exit 1
  }
  DAY_CLI="day"
fi
echo "> day CLI: $DAY_CLI ($("$DAY_CLI" --version 2>/dev/null | head -1))"

# `--merge` rewrites and deletes files. Requiring a clean tree is what makes every one of those
# edits reviewable with `git diff` and undoable with `git checkout .` afterwards.
if [ "$MERGE" -eq 1 ] && [ "$FORCE" -eq 0 ] && git rev-parse --git-dir >/dev/null 2>&1; then
  if [ -n "$(git status --porcelain)" ]; then
    echo "error: --merge wants a clean git tree, so its edits are reviewable and revertible." >&2
    echo "       Commit or stash first, or pass --force to merge anyway." >&2
    exit 1
  fi
fi

# ---------------------------------------------------------------------------------------------
# Scaffold a fresh copy with those parameters.
# ---------------------------------------------------------------------------------------------
FRESH="$WORK/fresh"
mkdir -p "$FRESH"
echo "> scaffolding $APP_NAME (title=$APP_TITLE id=$APP_ID)"
echo "  targets: $TARGETS"
# --appid is what gives website/site.toml this repo's real Pages host; without it the scaffold
# writes the `example.github.io` placeholder and every run reports that as drift.
( cd "$FRESH" && "$DAY_CLI" new app "$APP_NAME" --title "$APP_TITLE" --no-input \
    --appid "$APP_ID" --toolkit "$TARGETS" ) >/dev/null
SCAFFOLD="$FRESH/$APP_NAME"
[ -d "$SCAFFOLD" ] || { echo "error: day new produced no $APP_NAME/ directory" >&2; exit 1; }

# ---------------------------------------------------------------------------------------------
# Compare. Both directions, because a file this checkout DROPPED is drift just as much as one it
# added — and neither shows up if you only walk one tree.
# ---------------------------------------------------------------------------------------------
# Tracked files PLUS untracked ones that are not ignored. Plain `git ls-files` lists only the
# index, which on a freshly scaffolded repo with no commits is nearly empty — and an empty list
# makes this whole check pass without comparing anything.
if git rev-parse --git-dir >/dev/null 2>&1; then
  git ls-files --cached --others --exclude-standard > "$FRESH/files.txt"
else
  ( cd "$ROOT" && find . -type f -not -path "./.git/*" | sed 's|^\./||' ) > "$FRESH/files.txt"
fi

COUNT=$(grep -c . < "$FRESH/files.txt" || true)
if [ "${COUNT:-0}" -lt 20 ]; then
  echo "error: only $COUNT files to compare, which cannot be a Day scaffold (a real one is ~80)." >&2
  echo "       The checkout is incomplete, so a PASS would mean nothing." >&2
  exit 1
fi
echo "> comparing $COUNT files"

ADDED=(); CHANGED=(); MISSING=()

while IFS= read -r f; do
  [ -n "$f" ] || continue
  is_excluded "$f" && continue
  if [ ! -e "$SCAFFOLD/$f" ]; then
    ADDED+=("$f")
  elif ! cmp -s "$f" "$SCAFFOLD/$f"; then
    CHANGED+=("$f")
  fi
done < "$FRESH/files.txt"

while IFS= read -r abs; do
  rel="${abs#"$SCAFFOLD"/}"
  is_excluded "$rel" && continue
  [ -e "$rel" ] || MISSING+=("$rel")
done < <(find "$SCAFFOLD" -type f -not -path "*/.git/*")

TOTAL=$(( ${#ADDED[@]} + ${#CHANGED[@]} + ${#MISSING[@]} ))

if [ "$TOTAL" -eq 0 ]; then
  echo "No drift: this checkout is exactly what \`day new\` produces."
  exit 0
fi

# ---------------------------------------------------------------------------------------------
# --merge: make the checkout match. Day-Rise is generated, so the scaffold wins every conflict.
# ---------------------------------------------------------------------------------------------
if [ "$MERGE" -eq 1 ]; then
  for f in "${CHANGED[@]:-}" "${MISSING[@]:-}"; do
    [ -n "$f" ] || continue
    mkdir -p "$(dirname "$f")"
    cp "$SCAFFOLD/$f" "$f"
    echo "  updated  $f"
  done
  for f in "${ADDED[@]:-}"; do
    [ -n "$f" ] || continue
    rm -f "$f"
    echo "  removed  $f"
  done
  echo
  echo "Merged $TOTAL change(s) from \`day new\`. Review with \`git diff\`, then re-run this"
  echo "script with no flags to confirm the checkout is clean."
  exit 0
fi

# ---------------------------------------------------------------------------------------------
# Report.
# ---------------------------------------------------------------------------------------------
report() {
  echo "## Scaffold drift"
  echo
  echo "$APP_NAME is a reference copy of \`day new\` output and no longer matches it:"
  echo
  echo '```'
  for f in "${ADDED[@]:-}";   do [ -n "$f" ] && echo "  + $f  (in this repo, NOT produced by \`day new\`)"; done
  for f in "${CHANGED[@]:-}"; do [ -n "$f" ] && echo "  ~ $f  (contents differ from \`day new\`)"; done
  for f in "${MISSING[@]:-}"; do [ -n "$f" ] && echo "  - $f  (produced by \`day new\`, MISSING here)"; done
  echo '```'
  echo
  echo "\`+\` only here · \`~\` contents differ · \`-\` only in a fresh scaffold"
  echo
  echo "### Fixing it"
  echo
  echo "Do **not** hand-edit $APP_NAME. It is generated, and an edit is lost on the next"
  echo "regeneration. Change the template instead — \`day/crates/day-cli/templates/app/\` — then"
  echo "bring this checkout back in line:"
  echo
  echo '```sh'
  echo "scripts/scaffold-drift.sh --local ../day --merge   # against a local template edit"
  echo "scripts/scaffold-drift.sh --merge                  # against the installed day CLI"
  echo '```'
  echo
  echo "Two things commonly show up here that are not template changes at all: a CLI older than"
  echo "the one that generated this checkout (compare \`day --version\`), and a tree that was"
  echo "scaffolded once and edited since. \`--merge\` settles both."
}

report | tee -a "${GITHUB_STEP_SUMMARY:-/dev/null}"
exit 1
