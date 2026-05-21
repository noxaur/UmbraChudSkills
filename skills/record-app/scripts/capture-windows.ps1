# capture-windows.ps1 — Windows native app screen capture
# Usage: ./capture-windows.ps1 <config.json>

param(
    [Parameter(Mandatory=$true)]
    [string]$ConfigFile
)

$ErrorActionPreference = "Stop"

# Check ffmpeg
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
    Write-Error "ffmpeg not found. Install: choco install ffmpeg"
    exit 1
}

# Parse config
$config = Get-Content $ConfigFile | ConvertFrom-Json
$outputFile = if ($config.output) { $config.output } else { "docs/media/demo-windows.webm" }
$outputDir = Split-Path $outputFile -Parent
$tmpDir = Join-Path $outputDir ".raw-captures"

if (-not (Test-Path $outputDir)) { New-Item -ItemType Directory -Path $outputDir -Force | Out-Null }
if (-not (Test-Path $tmpDir)) { New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null }

# Launch app if path provided
if ($config.appPath) {
    Write-Host "Launching app: $($config.appPath)"
    Start-Process $config.appPath
    Start-Sleep -Seconds 3
}

# Capture each scene
$clipPaths = @()
foreach ($scene in $config.scenes) {
    $name = $scene.name
    Write-Host "Capturing: $name"

    $screenshotPath = Join-Path $tmpDir "${name}-windows.png"

    # Use PowerShell screenshot via .NET
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.SendKeys]::SendWait('{PRTSC}')
    Start-Sleep -Milliseconds 200

    # Fallback: use screencapture via ffmpeg gdigrab (single frame)
    ffmpeg -y -f gdigrab -i desktop -frames:v 1 "$screenshotPath" 2>$null

    $clipPaths += $screenshotPath
    Write-Host "  Captured: $screenshotPath"
}

# Stitch into final video
Write-Host "`nStitching final video..."

if ($clipPaths.Count -eq 0) {
    Write-Error "No captures to stitch"
    exit 1
}

if ($clipPaths.Count -eq 1) {
    $first = $clipPaths[0]
    ffmpeg -y -loop 1 -i $first `
        -vf "zoompan=z='min(zoom+0.0015,1.5)':d=125:x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':s=1280x720:fps=25" `
        -t 5 -c:v libvpx-vp9 -pix_fmt yuv420p $outputFile
} else {
    $inputs = ""
    $filter = ""
    for ($i = 0; $i -lt $clipPaths.Count; $i++) {
        $inputs += "-loop 1 -t 3 -i `"$($clipPaths[$i])`" "
        $filter += "[$($i):v]scale=1280:720,setsar=1,fps=25[v$($i)];"
    }

    $filter += "[v0][v1]xfade=transition=fade:duration=0.5:offset=2.5[t1];"
    for ($i = 2; $i -lt $clipPaths.Count; $i++) {
        $prev = "t$($i-1)"
        $offset = (($i - 1) * 2500) / 1000
        $filter += "[$prev][v$($i)]xfade=transition=fade:duration=0.5:offset=$($offset)[t$($i)];"
    }
    $filter += "[t$($clipPaths.Count - 1)]null[outv]"

    ffmpeg -y $inputs -filter_complex $filter -map "[outv]" -c:v libvpx-vp9 -pix_fmt yuv420p $outputFile
}

# Clean up
Remove-Item -Recurse -Force $tmpDir

Write-Host "`nDone: $outputFile"
