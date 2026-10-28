# dotfiles

macOS setup: AeroSpace + SketchyBar + JankyBorders, Alacritty + tmux + zsh, LazyVim.

## Install

```sh
git clone https://github.com/rhosmans/dotfiles.git ~/Documents/dotfiles
cd ~/Documents/dotfiles && ./install.sh           # everything below
./install.sh --xcode                               # ...plus the App Store apps
```

`install.sh` is safe to re-run: every step checks first. Existing configs are moved to
`~/.dotfiles-backup-<timestamp>/` before being replaced with symlinks into this repo.
Some casks (Karabiner, Zulu, Docker) ask for your password.

## What gets installed

### Programs/Deps (Homebrew)
1. Homebrew: official installer, `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"` (also installs the Xcode Command Line Tools)
2. CLI (formulae): `neovim tmux fzf pipx gcc ripgrep fd curl lazygit jq go jenv starship bash superfile postgresql@17`
   - Superfile runs as `spf`
   - `bash` is there because SDKMAN's installer needs bash ≥ 4
3. Window manager and bar: `nikitabobko/tap/aerospace`, `felixkratz/formulae/sketchybar`, `felixkratz/formulae/borders`
4. Apps (casks): `obsidian zen visual-studio-code spotify mac-mouse-fix karabiner-elements zulu@17 docker-desktop`
   - **Docker:** `docker-desktop` also installs the `docker` CLI and `docker compose` in `/usr/local/bin`. Don't `brew install docker` as well; that formula's copy would shadow Desktop's.

### Fonts
- CaskaydiaMono Nerd Font: `font-caskaydia-mono-nerd-font`
- Sketchybar-app-font: `font-sketchybar-app-font`
- SF-Pro: `font-sf-pro`
- SF-Symbols: `sf-symbols`

### From App Store (only with `--xcode`)
Installed with [`mas`](https://github.com/mas-cli/mas). Sign in to the App Store app first. Xcode is a large download.
1. Xcode
2. DevCleaner for Xcode
3. Apple Developer

### Other
1. oh-my-zsh: keeps the linked `.zshrc`
2. tpm, plus the tmux plugins from `.tmux.conf`
3. CalCure: `pipx install calcure`
4. nvm with Node LTS (set as the default)
5. SDKMAN
6. jenv, with Zulu 17 registered (`JAVA_HOME` points at it)
7. LazyVim: the config is in this repo, and plugins are synced headless

### Manual
- **Alacritty:** its brew cask is disabled. Download the DMG from the [releases page](https://github.com/alacritty/alacritty/releases), then approve it in System Settings › Privacy & Security.
- **Raycast:** [raycast.com](https://www.raycast.com/) or `brew install --cask raycast`.

## Symlinks

| Repo | Linked to |
| --- | --- |
| `.zshrc` | `~/.zshrc` |
| `.aerospace.toml` | `~/.aerospace.toml` |
| `.config/{alacritty,borders,calcure,git,karabiner,nvim,sketchybar,tmux}` | `~/.config/…` |
| `.config/starship.toml` | `~/.config/starship.toml` |
| `.config/tmux/.tmux.conf` | `~/.tmux.conf` |

## Keybindings worth knowing
- **Moving between panes:** `Ctrl-h/j/k/l` moves between nvim splits and tmux panes ([vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)).
- **tmux prefix:** `Ctrl-a`.
- **Nvim cheatsheet:** `<leader>s?` or `:Cheatsheet` ([cheatsheet.nvim](https://github.com/sudormrfbin/cheatsheet.nvim)). Add your own entries with `:CheatsheetEdit`.
- **Alacritty:** `Cmd-←/→` jumps to the start or end of the line. `Option-←/→` jumps one word back or forward.

## Git identity
This repo is public. `install.sh` sets a repo-local `user.email` (`rhosmans@gmail.com`), so commits here never use the global work address.

## Machine-local config
`.zshrc` sources `~/.zshrc.local` at the end if it exists. Put work-specific config and secrets there; it isn't part of this repo.
