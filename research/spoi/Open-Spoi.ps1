param([switch]$NoBrowser)
$ErrorActionPreference = 'Stop'
$spoiRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$spoiAddress = 'http://127.0.0.1:8875/'
$spoiOutput = Join-Path $spoiRoot 'previews\spoi'
if (-not (Test-Path -LiteralPath (Join-Path $spoiOutput 'index.html'))) { throw 'Build the poster first: Rscript research/spoi/build.R' }
try { $spoiResponse = Invoke-WebRequest -Uri $spoiAddress -UseBasicParsing -TimeoutSec 2; $spoiReady = $spoiResponse.Content.Contains('HIDEF MAPS') } catch { $spoiReady = $false }
if (-not $spoiReady) {
    $spoiPython = Get-Command py -ErrorAction Stop
    $spoiLogFolder = Join-Path $spoiRoot 'review-data\runtime'
    New-Item -ItemType Directory -Force $spoiLogFolder | Out-Null
    $spoiArguments = @('-3', '-m', 'http.server', '8875', '--bind', '127.0.0.1', '--directory', ('"' + $spoiOutput + '"'))
    $spoiProcess = Start-Process -FilePath $spoiPython.Source -ArgumentList $spoiArguments -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $spoiLogFolder 'spoi.stdout.log') -RedirectStandardError (Join-Path $spoiLogFolder 'spoi.stderr.log')
    foreach ($spoiAttempt in 1..12) {
        try { $spoiResponse = Invoke-WebRequest -Uri $spoiAddress -UseBasicParsing -TimeoutSec 1; if ($spoiResponse.Content.Contains('HIDEF MAPS')) { $spoiReady = $true; break } } catch {}
        if ($spoiProcess.HasExited) { break }
        Start-Sleep -Milliseconds 250
    }
    if (-not $spoiReady) { throw 'Could not start the poster on port 8875. No existing process was stopped.' }
}
if (-not $NoBrowser) { Start-Process $spoiAddress }
Write-Output "Spói poster is ready at $spoiAddress"
