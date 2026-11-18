param([Parameter(Mandatory=$true)][string]$Repository)
$ErrorActionPreference='Stop'
$root=(Resolve-Path -LiteralPath $Repository).Path
$audit=Join-Path ([IO.Path]::GetTempPath()) ('tq-git-audit-'+[guid]::NewGuid().ToString('N'))
try{
 & git init --bare --quiet $audit
 if($LASTEXITCODE -ne 0){throw 'Cannot initialize isolated ignore audit.'}
 $probes=@('.env','.env.local','.env.example','data/verification.json','WTF/Account/example.lua','SavedVariables/Tranquility.lua','dist/example.zip','share/release.zip','image.png','image.jpg','secret.json','notes.txt','program.exe','node_modules/package/index.js','private.key')
 $ignored=@(& git -C $root --git-dir=$audit --work-tree=$root check-ignore --no-index -- $probes)
 foreach($probe in $probes){if($probe -notin $ignored){throw "Ignore rule missing for: $probe"}}
 $visible=@(& git -C $root --git-dir=$audit --work-tree=$root ls-files --others --exclude-standard)
 if($visible.Count -lt 10){throw 'Source tracking appears incomplete.'}
 $secret='(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,}|[A-Za-z0-9_-]{20,30}\.[A-Za-z0-9_-]{6}\.[A-Za-z0-9_-]{25,}|-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----)'
 foreach($name in $visible){
  if($name -notmatch '(?:\.(?:lua|toc|md|ps1|cjs|cmd|bat)$|(?:^|/)(?:LICENSE|\.gitignore|\.gitattributes|\.editorconfig)$)'){throw "Unexpected source file type: $name"}
  $file=Join-Path $root $name;if([IO.File]::ReadAllText($file) -match $secret){throw "Potential credential material in $name (value suppressed)."}
 }
 Write-Output "PASS: $($probes.Count) private/generated ignore probes; $($visible.Count) source/Markdown/build metadata files; no credential signatures."
}finally{
 $resolved=[IO.Path]::GetFullPath($audit);$temp=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
 if($resolved.StartsWith($temp,[StringComparison]::OrdinalIgnoreCase) -and [IO.Path]::GetFileName($resolved).StartsWith('tq-git-audit-') -and (Test-Path -LiteralPath $resolved)){Remove-Item -LiteralPath $resolved -Recurse -Force}
}
