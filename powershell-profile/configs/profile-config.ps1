# PowerShell Profile Configuration
# Enhanced with git, node, zoxide, and developer utilities
# Can be updated via: irm https://your-repo/raw/profile-config.ps1 | iex

# ============================================================================
# Dependencies - Auto-install if missing
# ============================================================================

$requiredModules = @("Terminal-Icons", "PSReadLine")
$requiredTools = @("oh-my-posh", "zoxide")

foreach ($module in $requiredModules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing $module..." -ForegroundColor Yellow
        Install-Module -Name $module -Repository PSGallery -Force -Scope CurrentUser
    }
}

foreach ($tool in $requiredTools) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Host "Installing $tool..." -ForegroundColor Yellow
        winget.exe install $tool -y
    }
}

# ============================================================================
# Module Imports
# ============================================================================
Import-Module -Name Terminal-Icons
Import-Module -Name PSReadLine

# ============================================================================
# Prompt & Display
# ============================================================================

# Initialize Oh My Posh with custom theme
$poshTheme = "G:\My Drive\Hobbies\Tech\Coding\Repos\Personal Scripts\Configs\mbndposh.json"
if (Test-Path $poshTheme) {
    oh-my-posh init pwsh --config $poshTheme | Invoke-Expression
} else {
    oh-my-posh init pwsh | Invoke-Expression
}

# Initialize Zoxide for smart directory jumping
Invoke-Expression (& {
    $hook = if ($PSVersionTable.PSVersion.Major -lt 6) { 'prompt' } else { 'pwd' }
    (zoxide init --hook $hook powershell | Out-String)
})

# Display system info on startup
fastfetch.exe

# ============================================================================
# PSReadLine Configuration
# ============================================================================
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
Set-PSReadLineOption -HistorySearchCursorMovementStyle LineStart
Set-PSReadLineKeyHandler -Key Ctrl+D -Function DeleteCharOrExit

# ============================================================================
# Git Aliases & Functions
# ============================================================================
function g { git $args }
Set-Alias gs 'git status' -Force
Set-Alias gl 'git log' -Force
Set-Alias gp 'git push' -Force
Set-Alias gpl 'git pull' -Force
Set-Alias gc 'git commit' -Force
Set-Alias gco 'git checkout' -Force
Set-Alias ga 'git add' -Force
Set-Alias gd 'git diff' -Force
Set-Alias gb 'git branch' -Force

# Git branch switcher with filtering
function Get-GitBranch {
    param($pattern = "")
    $branches = git branch --list "*$pattern*" | ForEach-Object { $_.Trim() }
    if ($branches.Count -eq 1) {
        git checkout $branches[0]
    } elseif ($branches.Count -gt 1) {
        $selected = $branches | Out-GridView -Title "Select Branch" -OutputMode Single
        if ($selected) { git checkout $selected }
    } else {
        Write-Host "No branches found matching: $pattern" -ForegroundColor Yellow
    }
}
Set-Alias gbb Get-GitBranch

# ============================================================================
# Directory Navigation
# ============================================================================
Set-Alias which whichCommand -Force
function whichCommand { (Get-Command $args[0]).Path }

Set-Alias .. Set-Location..
function ... { Set-Location ../.. }
function .... { Set-Location ../../.. }

# Quick repo navigation
function Set-RepoLocation {
    param($name)
    $repoBase = "D:\Documents\Repos"
    if ($name) {
        $path = "$repoBase\$name"
        if (Test-Path $path) { Set-Location $path }
        else { Write-Host "Repo not found: $name" -ForegroundColor Red }
    } else {
        Set-Location $repoBase
        Get-ChildItem -Directory | Select-Object Name
    }
}
Set-Alias repo Set-RepoLocation

# ============================================================================
# Node.js & npm Utilities
# ============================================================================

# Display npm scripts from package.json
function Get-NpmScripts {
    if (Test-Path package.json) {
        $pkg = Get-Content package.json | ConvertFrom-Json
        $pkg.scripts | Format-Table -AutoSize
    } else {
        Write-Host "No package.json found" -ForegroundColor Yellow
    }
}
Set-Alias npm-scripts Get-NpmScripts

# Quick npm install & run
function Invoke-NpmRun {
    param($script)
    if ($script) { npm run $script }
    else { npm run }
}
Set-Alias nr Invoke-NpmRun

# ============================================================================
# General Utilities
# ============================================================================
Set-Alias ll { Get-ChildItem -Force }
Set-Alias la { Get-ChildItem -Force -Hidden }
Set-Alias -Name c -Value Clear-Host

# Create and enter new directory
function New-DirectoryAndEnter {
    param($path)
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    Set-Location $path
}
Set-Alias mkcd New-DirectoryAndEnter

# Filestamp command (Unix-like)
function Set-FileTimestamp {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (Test-Path -Path $Path) {
        (Get-Item -Path $Path).LastWriteTime = Get-Date
    } else {
        New-Item -ItemType File -Path $Path
    }
}
Set-Alias filestamp Set-FileTimestamp

# Search command history
function Find-CommandHistory {
    param($query)
    Get-History | Where-Object { $_.CommandLine -like "*$query*" } | Select-Object -Last 20
}
Set-Alias history-search Find-CommandHistory

# Open current directory in VS Code
function Invoke-VsCode { code . }
Set-Alias code-here Invoke-VsCode

Write-Host "✓ Profile loaded successfully" -ForegroundColor Green
