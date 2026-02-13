Param(
  [string]$OpenScadExe = "C:\\Program Files\\OpenSCAD\\openscad.exe",
  [string]$FontDir
)

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
$Src = Join-Path $Root 'src\test-hole-generator-v2.scad'
$OutDir = Join-Path $Root 'exports\stl'

if (-not $FontDir) {
  $FontDir = Join-Path $Root 'fonts'
}

$FontArgs = @()
if (Test-Path -LiteralPath $FontDir) {
  $FontArgs = @('--fontdir', $FontDir)
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Export-One {
  param(
    [string]$OutFile,
    [string[]]$Args
  )

  & $OpenScadExe @FontArgs -o (Join-Path $OutDir $OutFile) $Src @Args
}

Export-One -OutFile 'Test_Hole_Generator_Circle50to1095step05.stl' -Args @(
  '-D','initial_hole_size=5','-D','final_hole_size=10.95','-D','hole_step_size=0.05','-D','hole_type="circle"'
)

Export-One -OutFile 'Test_Hole_Generator_Hex50to1095step05.stl' -Args @(
  '-D','initial_hole_size=5','-D','final_hole_size=10.95','-D','hole_step_size=0.05','-D','hole_type="hexagon"'
)

Export-One -OutFile 'Test_Hole_Generator_Circle30to995step05.stl' -Args @(
  '-D','initial_hole_size=3','-D','final_hole_size=9.95','-D','hole_step_size=0.05','-D','hole_type="circle"'
)

Write-Host "OK: exported STLs to $OutDir"
