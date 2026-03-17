# Run this script once to set up the shared debug keystore for Google Sign-In
# Usage: Right-click > Run with PowerShell  OR  powershell -ExecutionPolicy Bypass -File setup_debug_keystore.ps1

$source = Join-Path $PSScriptRoot "debug.keystore"
$dest   = "$env:USERPROFILE\.android\debug.keystore"

if (!(Test-Path "$env:USERPROFILE\.android")) {
    New-Item -ItemType Directory -Path "$env:USERPROFILE\.android" | Out-Null
}

if (Test-Path $dest) {
    $backup = "$env:USERPROFILE\.android\debug.keystore.backup"
    Copy-Item $dest $backup -Force
    Write-Host "Old keystore backed up to: $backup"
}

Copy-Item $source $dest -Force
Write-Host "Done! debug.keystore copied to: $dest"
Write-Host "You can now run the app and Google Sign-In will work."
