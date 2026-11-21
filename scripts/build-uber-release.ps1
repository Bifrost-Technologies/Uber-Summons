param([string]$LuaRunner)
$ErrorActionPreference='Stop'
$repo=Split-Path -Parent $PSScriptRoot
Push-Location -LiteralPath $repo
try {
    if (-not $LuaRunner) {
        $command=Get-Command lua,luajit,fengari -ErrorAction SilentlyContinue | Select-Object -First 1
        if($command){$LuaRunner=$command.Source}
        else {
            $roots=@((Join-Path $env:LOCALAPPDATA 'npm-cache\_npx'),(Join-Path $env:USERPROFILE 'AppData\Local\npm-cache\_npx')) | Select-Object -Unique
            $cached=foreach($cacheRoot in $roots){Get-ChildItem -Path (Join-Path $cacheRoot '*\node_modules\.bin\fengari.cmd') -Force -ErrorAction SilentlyContinue}
            $cached=$cached | Select-Object -First 1;if($cached){$LuaRunner=$cached.FullName}
        }
    }
    if(-not $LuaRunner){throw 'Install Lua 5.1+ or pass -LuaRunner.'}
    $result=@(& $LuaRunner tests/uber.lua 2>&1)
    $result | ForEach-Object { Write-Host $_ }
    if ($LASTEXITCODE -ne 0 -or [string]$result[-1] -notmatch '^PASS: \d+ Uber ') { throw 'Uber tests failed' }
    $integration=@(& $LuaRunner tests/uber-integration.lua 2>&1)
    $integration | ForEach-Object { Write-Host $_ }
    if($LASTEXITCODE -ne 0 -or [string]$integration[-1] -notmatch '^PASS: \d+ Uber multi-client integration assertions$'){throw 'Uber multi-client tests failed'}
    $services=@(& $LuaRunner tests/uber-services.lua 2>&1)
    $services | ForEach-Object {Write-Host $_}
    if($LASTEXITCODE -ne 0 -or [string]$services[-1] -notmatch '^PASS: \d+ Uber services assertions$'){throw 'Uber pricing/presence tests failed'}
    $adminTests=@(& $LuaRunner tests/uber-admin.lua 2>&1)
    $adminTests | ForEach-Object {Write-Host $_}
    if($LASTEXITCODE -ne 0 -or [string]$adminTests[-1] -notmatch '^PASS: \d+ Uber administration and delivery assertions$'){throw 'Uber administration/delivery tests failed'}
    $notifications=@(& $LuaRunner tests/uber-notifications.lua 2>&1)
    $notifications | ForEach-Object {Write-Host $_}
    if($LASTEXITCODE -ne 0 -or [string]$notifications[-1] -notmatch '^PASS: \d+ Uber notification assertions$'){throw 'Uber notification tests failed'}
    New-Item -ItemType Directory -Path dist -Force | Out-Null
    $manifest=Get-Content Uber/Uber.toc -Raw
    if($manifest -ne (Get-Content Uber/Uber_Camelot.toc -Raw)){throw 'Manifests differ'}
    $version=[regex]::Match($manifest,'(?m)^## Version: (.+)\r?$').Groups[1].Value.Trim()
    if($version -notmatch '^\d+\.\d+\.\d+(?:-beta\.\d+)?$'){throw 'Invalid version'}
    $declared=@($manifest -split '\r?\n' | Where-Object {$_ -and -not $_.StartsWith('#')})
    $allowed=@('Uber.toc','Uber_Camelot.toc','README.md','ADMIN-AND-DELIVERY.md','LICENSE','CHANGELOG.md','UberIcon.tga','UberSplash.tga')+$declared
    $sourceOnly=@('.pkgmeta')
    foreach($file in Get-ChildItem Uber -File){
        if($file.Name -notin ($allowed+$sourceOnly)){throw "Unexpected runtime file: $($file.Name)"}
        if($file.Extension -eq '.lua' -and [IO.File]::ReadAllText($file.FullName) -match '\b(?:SendInput|RunMacroText|loadstring|GuildInvite|ReloadUI)\b|TitansRecruit|D:\\Titans'){throw 'Public source audit failed'}
    }
    foreach($file in $declared){if(-not(Test-Path -LiteralPath (Join-Path Uber $file))){throw "Missing file $file"}}
    $zip="dist/Uber-$version.zip"
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    Add-Type -AssemblyName System.IO.Compression
    # Compress-Archive can emit Windows backslashes in ZIP entry headers.
    # Some readers normalize them, masking paths rejected by server validators.
    $zipStream=[IO.File]::Open((Join-Path $repo $zip),[IO.FileMode]::Create)
    $writer=[IO.Compression.ZipArchive]::new($zipStream,[IO.Compression.ZipArchiveMode]::Create,$false)
    try {
        foreach($name in ($allowed | Sort-Object -Unique)) {
            $entry=$writer.CreateEntry('Uber/'+$name,[IO.Compression.CompressionLevel]::Optimal)
            $inputStream=[IO.File]::OpenRead((Join-Path $repo ('Uber/'+$name)))
            $outputStream=$entry.Open()
            try {$inputStream.CopyTo($outputStream)} finally {$inputStream.Dispose();$outputStream.Dispose()}
        }
    } finally {$writer.Dispose();$zipStream.Dispose()}
    & node scripts/verify-uber-zip.cjs $zip
    if($LASTEXITCODE -ne 0){throw 'Raw ZIP header/CRC verification failed'}
    $archive=[IO.Compression.ZipFile]::OpenRead((Join-Path $repo $zip))
    try {
        $expected=@($allowed | ForEach-Object {'Uber/'+$_})
        $actual=@($archive.Entries | ForEach-Object {$_.FullName.Replace('\','/')})
        if(Compare-Object ($expected | Sort-Object -Unique) ($actual | Sort-Object -Unique)){throw 'ZIP file list does not match declared release files'}
        foreach($entry in $archive.Entries){
            $relative=$entry.FullName.Replace('\','/')
            if($relative -notmatch '^Uber/[A-Za-z_][A-Za-z_0-9.\-]*$'){throw 'Unexpected ZIP path'}
            $entryStream=$entry.Open();$sha=[Security.Cryptography.SHA256]::Create()
            try{$entryHash=[BitConverter]::ToString($sha.ComputeHash($entryStream)).Replace('-','')}finally{$entryStream.Dispose();$sha.Dispose()}
            $sourceHash=(Get-FileHash -LiteralPath (Join-Path $repo $relative) -Algorithm SHA256).Hash
            if($entryHash -ne $sourceHash){throw "ZIP content mismatch: $relative"}
        }
    }finally{$archive.Dispose()}
    $hash=(Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash
    Set-Content -LiteralPath ($zip+'.sha256') -Value $hash -Encoding ascii
    $handoff='share/Uber-submission'
    New-Item -ItemType Directory -Path $handoff -Force | Out-Null
    Copy-Item -LiteralPath $zip,($zip+'.sha256') -Destination $handoff -Force
    Copy-Item -Path 'docs/uber/*' -Destination $handoff -Recurse -Force
    Copy-Item -LiteralPath 'Uber/LICENSE','Uber/CHANGELOG.md' -Destination $handoff -Force
    Set-Content -LiteralPath (Join-Path $handoff 'PREFLIGHT.txt') -Value @($result[-1],$integration[-1],$services[-1],$adminTests[-1],$notifications[-1],"SHA256 $hash",'PASS: raw ZIP paths, local headers, decompression and CRC checks','PASS: manifest declarations, public source audit, ZIP file list and per-file hash verification','PENDING: live mailbox/multiplayer tests, screenshots, client/name validation and commission policy review; corrected archive not uploaded by agent') -Encoding utf8
    # Keep a single-version handoff so old ZIPs cannot be mistaken for this candidate.
    $current=Join-Path $handoff ('release-'+$version)
    New-Item -ItemType Directory -Path $current -Force | Out-Null
    Copy-Item -LiteralPath $zip,($zip+'.sha256'),'Uber/README.md','Uber/LICENSE','Uber/CHANGELOG.md' -Destination $current -Force
    foreach($doc in @('DESCRIPTION.md','DISCORD.md','FORM-ENTRIES.md','submission.md','ADMIN-AND-DELIVERY.md','ARCHIVE-REPAIR.md','TESTING.md','uber-logo-400.png','PREFLIGHT.txt')){
        if($doc -eq 'uber-logo-400.png' -and -not(Test-Path -LiteralPath (Join-Path $handoff $doc))){continue}
        Copy-Item -LiteralPath (Join-Path $handoff $doc) -Destination $current -Force
    }
    Set-Content -LiteralPath (Join-Path $current 'UPLOAD-THIS-FILE.txt') -Value @("Upload only Uber-$version.zip to the existing project.",'Do not zip/upload this entire folder. The other files are listing, license, logo and test materials.','No file has been uploaded automatically. Record live tests and supply real screenshots before publication.') -Encoding utf8
    Write-Output (Join-Path $repo $zip)
} finally { Pop-Location }
