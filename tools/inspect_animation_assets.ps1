# Run from the repository root in PowerShell.
# Optional: .\tools\inspect_animation_assets.ps1 -GodotExe "C:\path\to\Godot_v4.7.2-stable_win64_console.exe"

param(
    [string]$GodotExe = "C:\AI\Parkour\Godot_v4.7.2-stable_win64_console.exe"
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ProjectFile = Join-Path $ProjectRoot "project.godot"

if (-not (Test-Path -LiteralPath $ProjectFile)) {
    throw "project.godot not found at '$ProjectFile'. Run this script from a checked-out Parkour repository."
}

if (-not (Test-Path -LiteralPath $GodotExe)) {
    $candidate = Get-Command godot -ErrorAction SilentlyContinue
    if ($candidate) {
        $GodotExe = $candidate.Source
    } else {
        throw "Godot executable not found at '$GodotExe'. Pass -GodotExe with the full path to Godot 4.7.2."
    }
}

Write-Host "Step 1/2: Importing project resources with Godot..."
& $GodotExe --headless --editor --path $ProjectRoot --import
if ($LASTEXITCODE -ne 0) {
    throw "Godot import failed with exit code $LASTEXITCODE."
}

Write-Host "Step 2/2: Inspecting GLB skeletons and animation clips..."
& $GodotExe --headless --path $ProjectRoot --script "res://tools/inspect_animation_assets.gd"
if ($LASTEXITCODE -ne 0) {
    throw "Godot diagnostic failed with exit code $LASTEXITCODE."
}

Write-Host ""
Write-Host "Copy the text between ANIMATION_ASSET_DIAGNOSTIC_BEGIN and ANIMATION_ASSET_DIAGNOSTIC_END to the project chat."
