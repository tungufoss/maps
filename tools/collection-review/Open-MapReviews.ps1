param([switch]$NoBrowser)
$ErrorActionPreference = 'Stop'
$reviewAddress = 'http://127.0.0.1:8874/'
$reviewDirectory = $PSScriptRoot

function Test-ReviewServer {
    try {
        $response = Invoke-WebRequest -Uri $reviewAddress -UseBasicParsing -TimeoutSec 2
        return $response.Content.Contains('Map inspiration · Private review') -or $response.Content.Contains('Find your kind of map.')
    } catch { return $false }
}

if (-not (Test-ReviewServer)) {
    $pythonLauncher = Get-Command py -ErrorAction SilentlyContinue
    if ($pythonLauncher) {
        $pythonForReviews = $pythonLauncher.Source
        $reviewArguments = @('-3', '-m', 'http.server')
    } else {
        $pythonForReviews = (Get-Command python -ErrorAction Stop).Source
        $reviewArguments = @('-m', 'http.server')
    }
    $reviewArguments += @('8874', '--bind', '127.0.0.1', '--directory', ('"' + $reviewDirectory + '"'))
    $reviewLogDirectory = Join-Path (Split-Path (Split-Path $reviewDirectory -Parent) -Parent) 'review-data\runtime'
    New-Item -ItemType Directory -Path $reviewLogDirectory -Force | Out-Null
    $reviewProcess = Start-Process -FilePath $pythonForReviews -ArgumentList $reviewArguments -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $reviewLogDirectory 'server.stdout.log') -RedirectStandardError (Join-Path $reviewLogDirectory 'server.stderr.log')
    $reviewReady = $false
    foreach ($reviewAttempt in 1..12) {
        if (Test-ReviewServer) { $reviewReady = $true; break }
        if ($reviewProcess.HasExited) { break }
        Start-Sleep -Milliseconds 250
    }
    if (-not $reviewReady) {
        throw 'The map review tool could not start on port 8874. Another app may be using it. No existing app was stopped.'
    }
}
if (-not $NoBrowser) { Start-Process $reviewAddress }
Write-Output "Map reviews are ready at $reviewAddress"
