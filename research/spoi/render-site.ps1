param([switch]$Serve)
$ErrorActionPreference = 'Stop'
$repoForSpoi = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
Push-Location $repoForSpoi
try {
    $siteDestination = Join-Path $repoForSpoi '_site\research\spoi'
    New-Item -ItemType Directory -Path $siteDestination -Force | Out-Null
    $galleryDestination = Join-Path $repoForSpoi '_site\previews\spoi'
    New-Item -ItemType Directory -Path $galleryDestination -Force | Out-Null
    foreach ($image in @('poster.png','poster-is.png','poster-background.png','build-01-map.png','build-02-trajectories.png','build-03-direction.png','build-03-smoothing.png','build-04-anchors.png','build-05-density.png','poster-lanes.png')) {
        Copy-Item -LiteralPath (Join-Path 'previews/spoi' $image) -Destination $siteDestination
        Copy-Item -LiteralPath (Join-Path 'previews/spoi' $image) -Destination $galleryDestination
    }
    # The explicit local profile includes the draft story and its atlas card.
    & quarto render --profile spoi-preview --no-clean
    if ($LASTEXITCODE -ne 0) { throw 'The local story preview did not render.' }
    if ($Serve) {
        $previewForSpoi = 'http://127.0.0.1:8876/research/spoi/site.html'
        $runningForSpoi = $false
        try { $runningForSpoi = (Invoke-WebRequest -Uri $previewForSpoi -UseBasicParsing -TimeoutSec 2).StatusCode -eq 200 } catch {}
        if (-not $runningForSpoi) {
            $previewProcessForSpoi = Start-Process -FilePath (Get-Command py -ErrorAction Stop).Source -ArgumentList @('-3','-m','http.server','8876','--bind','127.0.0.1','--directory',('"' + (Join-Path $repoForSpoi '_site') + '"')) -WindowStyle Hidden -PassThru
            foreach ($attemptForSpoi in 1..20) {
                try { $runningForSpoi = (Invoke-WebRequest -Uri $previewForSpoi -UseBasicParsing -TimeoutSec 1).StatusCode -eq 200 } catch {}
                if ($runningForSpoi -or $previewProcessForSpoi.HasExited) { break }
                Start-Sleep -Milliseconds 250
            }
            if (-not $runningForSpoi) { throw 'The story server did not become ready on port 8876. Check whether that port is occupied; no existing process was stopped.' }
        }
        Write-Output "Local story preview: $previewForSpoi"
    }
} finally { Pop-Location }
