# Tuxie — Windows Folder Setup Script
# Run this from inside your tuxie\ project folder in PowerShell
# Usage: .\setup_folders.ps1

Write-Host "Setting up Tuxie folder structure..." -ForegroundColor Cyan

$folders = @(
    "assets\images",
    "assets\animations",
    "lib\core\theme",
    "lib\core\router",
    "lib\core\supabase",
    "lib\features\auth\screens",
    "lib\features\auth\widgets",
    "lib\features\shell\screens",
    "lib\features\home\screens",
    "lib\features\calendar\screens",
    "lib\features\brain\screens",
    "lib\features\finance\screens",
    "lib\features\more\screens",
    "lib\features\goals\screens",
    "lib\features\health\screens",
    "lib\features\inventory\screens",
    "lib\features\ai\screens"
)

foreach ($folder in $folders) {
    if (-Not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder | Out-Null
        Write-Host "  Created: $folder" -ForegroundColor Green
    } else {
        Write-Host "  Exists:  $folder" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Done! All folders created." -ForegroundColor Cyan
Write-Host "Now copy your .dart files into the correct locations." -ForegroundColor White
Write-Host "Then run: flutter pub get" -ForegroundColor White
