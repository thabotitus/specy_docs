# shellcheck shell=bash
# Shared helpers for ensuring the GitHub CLI is available.
#
# Usage (from another script):
#   source "$ROOT/bin/lib/ensure_gh.sh"
#   ensure_gh

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Error: required command not found: $1" >&2
    exit 1
  }
}

ensure_gh() {
  if command -v gh >/dev/null 2>&1; then
    return 0
  fi

  echo "GitHub CLI (gh) is not installed. Installing..."

  case "$(uname -s)" in
    Darwin)
      require_cmd brew
      brew install gh
      ;;
    Linux)
      if command -v apt-get >/dev/null 2>&1; then
        (type -p wget >/dev/null || (sudo apt-get update && sudo apt-get install -y wget))
        sudo mkdir -p -m 755 /etc/apt/keyrings
        out="$(mktemp)"
        wget -nv -O"$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg
        cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
        sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
          | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
        sudo apt-get update
        sudo apt-get install -y gh
      elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y gh
      elif command -v yum >/dev/null 2>&1; then
        sudo yum install -y gh
      else
        echo "Error: cannot auto-install gh on this Linux distribution." >&2
        echo "Install manually: https://cli.github.com/" >&2
        exit 1
      fi
      ;;
    *)
      echo "Error: cannot auto-install gh on $(uname -s)." >&2
      echo "Install manually: https://cli.github.com/" >&2
      exit 1
      ;;
  esac

  if ! command -v gh >/dev/null 2>&1; then
    echo "Error: gh install finished but the binary is still not on PATH." >&2
    exit 1
  fi

  echo "Installed gh $(gh --version | head -n1)"
}
