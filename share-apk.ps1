# share-apk.ps1
# Silent APK upload to catbox.moe (anonymous, no browser needed)
#
# Usage:
#   .\share-apk.ps1                           # upload default arm64 APK
#   .\share-apk.ps1 -Path "path\to\file.apk"  # upload custom file
#   .\share-apk.ps1 -Supabase                 # upload to Supabase (permanent)

param(
    [string]$Path,
    [switch]$Supabase
)

$ErrorActionPreference = "Stop"

# --- Default APK path ---
if (-not $Path) {
    $Path = "C:\Users\HP\Documents\code_repo\durus\src\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk"
}
if (-not (Test-Path $Path)) {
    Write-Error "File not found: $Path"
    exit 1
}

$fileName = [IO.Path]::GetFileName($Path)
$fileMB   = [Math]::Round((Get-Item $Path).Length / 1MB, 1)
Write-Host "Uploading $fileName ($fileMB MB)..." -ForegroundColor Cyan

# --- Supabase Storage (permanent, fast) ---
if ($Supabase) {
    $credFile = "C:\Users\HP\Documents\code_repo\durus-keys\CREDENTIALS.txt"
    $env:SUPABASE_URL = (Get-Content $credFile | Select-String 'SUPABASE_URL').Line -replace '.*:\s*',''
    $env:SUPABASE_KEY = (Get-Content $credFile | Select-String 'SUPABASE_SERVICE_ROLE_KEY').Line -replace '.*:\s*',''
    $bucket = "durus-apk"
    $url    = "$env:SUPABASE_URL/storage/v1/object/$bucket/$fileName"

    Write-Host "Target: Supabase Storage ($bucket)" -ForegroundColor DarkGray
    $code = curl.exe -s -o NUL -w "%{http_code}" `
        -X POST "$url?upsert=true" `
        -H "Authorization: Bearer $env:SUPABASE_KEY" `
        -H "Content-Type: application/vnd.android.package-archive" `
        --data-binary "@$Path"

    if ($code -match '20[01]') {
        $public = "$env:SUPABASE_URL/storage/v1/object/public/$bucket/$fileName"
        Write-Host ""
        Write-Host "DONE (Supabase Permanent)" -ForegroundColor Green
        Write-Host "Link: $public"
    } else {
        Write-Error "Supabase upload failed (HTTP $code)"
        exit 1
    }
    exit 0
}

# --- Catbox.moe (anonymous, silent, no account needed) ---
Write-Host "Target: catbox.moe (anonymous)" -ForegroundColor DarkGray

$resp = curl.exe -s --max-time 300 `
    -F "reqtype=fileupload" `
    -F "fileToUpload=@$Path" `
    https://catbox.moe/user/api.php

if ($resp -match '^https?://') {
    Write-Host ""
    Write-Host "DONE (Catbox permanent)" -ForegroundColor Green
    Write-Host "Link: $resp"
} else {
    Write-Host ""
    Write-Host "Upload failed:" -ForegroundColor Red
    Write-Host $resp
    exit 1
}
