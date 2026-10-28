#!/usr/bin/env bash
#
# Bootstrap a fresh Mac from this dotfiles repo.
#
#   git clone https://github.com/rhosmans/dotfiles.git ~/Documents/dotfiles
#   cd ~/Documents/dotfiles && ./install.sh [--xcode]
#
#   --xcode   also install Xcode, DevCleaner and Apple Developer from the
#             App Store via mas (sign in to the App Store app first)
#
# Safe to re-run: every step checks whether it's already done.
# Existing configs are backed up to ~/.dotfiles-backup-<timestamp>/ before
# being replaced with symlinks into this repo.

set -uo pipefail

# Resolve repo root from this script's location, so the clone path doesn't matter.
DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
ok()    { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn()  { printf '  \033[33m!\033[0m %s\n' "$*"; WARNINGS+=("$*"); }
step()  { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
WARNINGS=()

XCODE=false
for arg in "$@"; do
  case "$arg" in
    --xcode)   XCODE=true ;;
    -h|--help) echo "Usage: ./install.sh [--xcode]   (--xcode: also install Xcode, DevCleaner, Apple Developer via mas)"; exit 0 ;;
    *)         echo "Unknown option: $arg (see --help)" >&2; exit 2 ;;
  esac
done

# ---------------------------------------------------------------- Homebrew ---
step "Homebrew"
if [[ "$(uname -m)" == "arm64" ]]; then
  BREW_PREFIX=/opt/homebrew
else
  BREW_PREFIX=/usr/local
fi

if ! command -v brew &>/dev/null && [[ ! -x "$BREW_PREFIX/bin/brew" ]]; then
  bold "Installing Homebrew (this also installs the Xcode Command Line Tools)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
    warn "Homebrew install failed — cannot continue"; exit 1; }
fi
eval "$("$BREW_PREFIX/bin/brew" shellenv)"
ok "brew $(brew --version | head -1 | awk '{print $2}') at $BREW_PREFIX"

# -------------------------------------------------------------------- Taps ---
step "Taps"
brew tap | grep -q '^felixkratz/formulae$' || brew tap FelixKratz/formulae
brew tap | grep -q '^nikitabobko/tap$'     || brew tap nikitabobko/tap
# Newer Homebrew refuses formulae from third-party taps until trusted.
if brew trust --help &>/dev/null; then
  brew trust --formula felixkratz/formulae/sketchybar 2>/dev/null || true
  brew trust --formula felixkratz/formulae/borders    2>/dev/null || true
fi
ok "felixkratz/formulae, nikitabobko/tap"

# ---------------------------------------------------------------- Formulae ---
step "CLI tools (brew formulae)"
FORMULAE=(
  bash        # SDKMAN's installer needs bash >= 4; macOS ships 3.2
  starship tmux neovim ripgrep fd lazygit jq pipx go jenv
  fzf gcc curl
  superfile   # run as `spf`
  postgresql@17
  felixkratz/formulae/sketchybar
  felixkratz/formulae/borders
)
missing=()
for f in "${FORMULAE[@]}"; do
  brew list --formula "${f##*/}" &>/dev/null || missing+=("$f")
done
if ((${#missing[@]})); then
  brew install "${missing[@]}" || warn "some formulae failed: ${missing[*]}"
fi
ok "${#FORMULAE[@]} formulae present"

# ------------------------------------------------------------------- Casks ---
step "Apps & fonts (brew casks — may prompt for your password)"
CASKS=(
  # fonts
  font-caskaydia-mono-nerd-font
  font-sketchybar-app-font
  font-sf-pro
  sf-symbols
  # apps
  nikitabobko/tap/aerospace
  karabiner-elements  # sudo
  zulu@17             # sudo; JAVA_HOME in .zshrc points at this JDK
  obsidian
  zen                 # Zen Browser
  visual-studio-code
  spotify
  mac-mouse-fix
  docker-desktop      # bundles the docker CLI + compose; the 'docker' formula would only shadow it
)
for c in "${CASKS[@]}"; do
  name="${c##*/}"; name="${name%@*}"
  if brew list --cask 2>/dev/null | grep -q "^${c##*/}$"; then
    ok "${c##*/} already installed"
  else
    brew install --cask "$c" || warn "cask '$c' failed — re-run in an interactive terminal if it needed sudo"
  fi
done

# ---------------------------------------------- App Store (--xcode only) ---
if $XCODE; then
  step "App Store apps via mas (Xcode is a large download)"
  brew list --formula mas &>/dev/null || brew install mas || warn "mas install failed"
  MAS_APPS=(
    "497799835:Xcode"
    "1388020431:DevCleaner for Xcode"
    "640199958:Apple Developer"
  )
  if command -v mas &>/dev/null; then
    have="$(mas list 2>/dev/null)"
    for app in "${MAS_APPS[@]}"; do
      id="${app%%:*}"; name="${app#*:}"
      if grep -qw "$id" <<<"$have"; then
        ok "$name already installed"
      else
        # `get` (not `install`) also covers free apps this Apple Account never downloaded.
        mas get "$id" && ok "$name installed" \
          || warn "App Store install of $name ($id) failed — sign in to the App Store app, then re-run with --xcode"
      fi
    done
  fi
fi

# Alacritty's cask is disabled (Gatekeeper check, 2026-09) — install manually.
if [[ -d /Applications/Alacritty.app || -d "$HOME/Applications/Alacritty.app" ]]; then
  ok "Alacritty present"
else
  warn "Alacritty not installed — its brew cask is disabled. Download the DMG from https://github.com/alacritty/alacritty/releases and approve it in System Settings > Privacy & Security"
fi

# --------------------------------------------------------------- oh-my-zsh ---
step "oh-my-zsh"
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  ok "already installed"
else
  # RUNZSH=no: don't drop into a new shell; KEEP_ZSHRC=yes: don't touch .zshrc
  RUNZSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
    || warn "oh-my-zsh install failed"
fi

# ---------------------------------------------------------------- Symlinks ---
step "Symlinks (existing files backed up to $BACKUP)"
mkdir -p "$HOME/.config"

link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
    ok "$(basename "$dst") already linked"
    return
  fi
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    mkdir -p "$BACKUP"
    mv "$dst" "$BACKUP/"
    ok "backed up old $(basename "$dst")"
  fi
  ln -s "$src" "$dst"
  ok "$(basename "$dst") -> ${src/#$HOME/~}"
}

link "$DOTFILES/.zshrc"          "$HOME/.zshrc"
link "$DOTFILES/.aerospace.toml" "$HOME/.aerospace.toml"
for d in alacritty borders calcure git karabiner nvim sketchybar tmux; do
  link "$DOTFILES/.config/$d" "$HOME/.config/$d"
done
link "$DOTFILES/.config/starship.toml"    "$HOME/.config/starship.toml"
# tmux config lives at .config/tmux/.tmux.conf in the repo; tmux's classic
# lookup path is ~/.tmux.conf, so link that too.
link "$DOTFILES/.config/tmux/.tmux.conf"  "$HOME/.tmux.conf"

chmod +x "$DOTFILES/.config/sketchybar/sketchybarrc" \
         "$DOTFILES/.config/sketchybar/plugins/"*.sh \
         "$DOTFILES/.config/borders/bordersrc" 2>/dev/null || true

# ------------------------------------------------------------ Git identity ---
step "Git identity for this repo"
# This repo is public: commit with the personal address regardless of the
# global user.email. Repo-local config always wins over ~/.gitconfig.
git -C "$DOTFILES" config user.email rhosmans@gmail.com \
  && ok "dotfiles commits use rhosmans@gmail.com" || warn "could not set user.email for $DOTFILES"

# --------------------------------------------------- tmux plugin manager ---
step "tmux plugin manager (tpm)"
if [[ -d "$HOME/.tmux/plugins/tpm" ]]; then
  ok "already installed"
else
  git clone --depth 1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm" \
    && ok "cloned" || warn "tpm clone failed"
fi
# Install the plugins listed in .tmux.conf non-interactively.
"$HOME/.tmux/plugins/tpm/bin/install_plugins" &>/dev/null \
  && ok "tmux plugins installed" || warn "tmux plugin install failed (run prefix+I inside tmux)"

# ----------------------------------------------------------------- calcure ---
step "calcure (via pipx)"
if command -v calcure &>/dev/null || [[ -x "$HOME/.local/bin/calcure" ]]; then
  ok "already installed"
else
  pipx install calcure && pipx ensurepath >/dev/null || warn "calcure install failed"
fi

# --------------------------------------------------------------------- nvm ---
step "nvm"
if [[ -s "$HOME/.nvm/nvm.sh" ]]; then
  ok "already installed"
else
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash \
    || warn "nvm install failed"
fi

# ----------------------------------------------------------- Node.js (nvm) ---
step "Node.js (LTS via nvm)"
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  set +u  # nvm.sh is not `set -u`-clean
  . "$NVM_DIR/nvm.sh"
  if command -v node &>/dev/null; then
    ok "node $(node --version) already installed"
  else
    if nvm install --lts && nvm alias default 'lts/*'; then
      ok "node $(node --version) (LTS) installed, set as default"
    else
      warn "node install via nvm failed"
    fi
  fi
  set -u
else
  warn "nvm not available — skipping Node.js"
fi

# ------------------------------------------------------------------ SDKMAN ---
step "SDKMAN"
if [[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]]; then
  ok "already installed"
else
  # rcupdate=false: .zshrc already contains the SDKMAN init lines.
  # Run with brew's bash — the installer requires bash >= 4.
  curl -s "https://get.sdkman.io?rcupdate=false" | "$BREW_PREFIX/bin/bash" \
    || warn "SDKMAN install failed"
fi

# -------------------------------------------------------------------- jenv ---
step "jenv"
ZULU=/Library/Java/JavaVirtualMachines/zulu-17.jdk/Contents/Home
if [[ -d "$ZULU" ]]; then
  export PATH="$HOME/.jenv/bin:$PATH"
  eval "$(jenv init -)" 2>/dev/null || true
  jenv add "$ZULU" &>/dev/null && ok "zulu-17 registered with jenv" || ok "zulu-17 already registered"
else
  warn "zulu-17 JDK not found — skipping jenv registration (re-run after the zulu@17 cask installs)"
fi

# ---------------------------------------------------------- neovim plugins ---
step "Neovim plugins (LazyVim bootstrap)"
if nvim --headless "+Lazy! sync" +qa &>/dev/null; then
  ok "lazy.nvim plugins synced"
else
  warn "headless plugin sync failed — plugins will install on first nvim launch"
fi

# ---------------------------------------------------------------- Services ---
step "Services"
brew services start sketchybar &>/dev/null && ok "sketchybar service started" || ok "sketchybar service already running"
brew services start borders    &>/dev/null && ok "borders service started"    || ok "borders service already running"
if [[ -d /Applications/AeroSpace.app ]]; then
  pgrep -xq AeroSpace || open -a AeroSpace
  ok "AeroSpace running (grants: allow Accessibility permission if macOS prompts)"
fi

# ----------------------------------------------------------------- Summary ---
echo
bold "Done."
if ((${#WARNINGS[@]})); then
  echo
  bold "Needs attention:"
  for w in "${WARNINGS[@]}"; do printf '  \033[33m!\033[0m %s\n' "$w"; done
fi
echo
echo "Open a new terminal (or run: exec zsh) to load the new shell config."
