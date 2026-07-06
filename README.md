# shell-profiles

Personal cross-shell profile configs — bash and PowerShell — with a themed
prompt, smart directory jumping, git aliases, and assorted quality-of-life
functions kept in parity across both shells.

## Contents

| Path                  | Shell                  | Entry point                       |
| --------------------- | ---------------------- | --------------------------------- |
| `bash-profile/`       | bash (Debian/Ubuntu)   | `configs/ndbash-config.sh`        |
| `powershell-profile/` | PowerShell 5.1+ / pwsh | `configs/ndpowershell-config.ps1` |

Both configs auto-install their own dependencies on first load, set up a
themed prompt (starship / oh-my-posh), zoxide, readline/PSReadLine tweaks,
git aliases (`gs`, `gl`, `gp`, `gc`, `gco`, `ga`, `gd`, `gb`, `gbb`), repo
navigation (`repo`), npm helpers (`nr`, `npm-scripts`), and general utilities
(`mkcd`, `ll`, `la`, `c`, `history-search`, `code-here`).

## Bash install

One-line bootstrap (Debian/Ubuntu, requires `apt-get`):

```bash
curl -fsSL https://raw.githubusercontent.com/n3rddoom/shell-profiles/master/install.sh | bash
```

This (`install.sh`):

1. Clones/updates this repo into `~/.local/share/shell-profiles`.
2. Appends `source ".../bash-profile/configs/ndbash-config.sh"` to `~/.bashrc`
   (skipped if already present).
3. Sources the config once immediately to run first-time setup: installs
   `starship`, `zoxide`, `eza`, `fastfetch`, and the FiraCode Nerd Font.
4. Start a new shell, or run `source ~/.bashrc`, to pick it up.

Env overrides for the bootstrap:

- `SHPROF_INSTALL_DIR` — clone location (default `~/.local/share/shell-profiles`)
- `SHPROF_BRANCH` — branch/tag to install (default `master`)

Manual alternative (no curl-pipe):

```bash
git clone https://github.com/n3rddoom/shell-profiles.git ~/.local/share/shell-profiles
echo 'source "$HOME/.local/share/shell-profiles/bash-profile/configs/ndbash-config.sh"' >> ~/.bashrc
source ~/.bashrc
```

## PowerShell install

There's no bootstrap script for PowerShell yet — set it up manually:

1. Clone the repo somewhere, e.g.:

   ```powershell
   git clone https://github.com/n3rddoom/shell-profiles.git D:\Documents\Repos\shell-profiles
   ```

2. Dot-source the config from your `$PROFILE`:

   ```powershell
   . "D:\Documents\Repos\shell-profiles\powershell-profile\configs\ndpowershell-config.ps1"
   ```

3. Open a new PowerShell session. On first run it installs the `Terminal-Icons`
   and `PSReadLine` modules (via `Install-Module`) and the `oh-my-posh` and
   `zoxide` tools (via `winget`).
4. Install `fastfetch` yourself — unlike the bash side, the PowerShell config
   does not auto-install it:

   ```powershell
   winget install fastfetch
   ```

**Known quirk:** the script points its oh-my-posh theme (`$poshTheme`) at a
hardcoded, machine-specific path. If that path doesn't exist it falls back to
oh-my-posh's default theme instead of the bundled
`powershell-profile/configs/mbndposh.json`. Edit `$poshTheme` in
`ndpowershell-config.ps1` to point at the bundled theme if you want it applied.

## Uninstalling

Remove the `source`/dot-source line from `~/.bashrc` or `$PROFILE`, then
optionally delete the cloned directory (`~/.local/share/shell-profiles` for
bash, or wherever you cloned the PowerShell side).
