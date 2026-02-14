Param(
  [string]$OpenScadExe = "C:\\Program Files\\OpenSCAD\\openscad.exe",
  [string]$FontDir,
  [Nullable[int]]$Fa,
  [Nullable[double]]$Fs
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

$QualityArgs = @()
if ($null -ne $Fa) {
  $QualityArgs += @('-D', "`$fa=$Fa")
}
if ($null -ne $Fs) {
  $QualityArgs += @('-D', "`$fs=$Fs")
}

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

function Export-One {
  param(
    [string]$OutFile,
    [string[]]$Args
  )

  & $OpenScadExe @FontArgs @QualityArgs -o (Join-Path $OutDir $OutFile) $Src @Args
}

# Canonical export preset (keep stable; do not rely on SCAD defaults)
$CommonArgs = @(
  '-D','holes_per_row=10',
  '-D','hole_spacing=3.0',
  '-D','plate_shape="trapezoid"',
  '-D','plate_thickness=5.0',
  '-D','text_size=4.0',
  '-D','top_text_scale=0.85',
  '-D','text_height=-1.5',
  '-D','left_margin=3.0',
  '-D','right_margin=3.0',
  '-D','top_margin=3.0',
  '-D','bottom_margin=3.0',
  '-D','label_padding=1.0',
  '-D','typeface_preset="liberation_sans_bold"',
  '-D','typeface_custom="Liberation Sans:style=Bold"'
)

Export-One -OutFile 'Test_Hole_Generator_Circle70to1095step05.stl' -Args @(
  $CommonArgs + @('-D','initial_hole_size=7','-D','final_hole_size=10.95','-D','hole_step_size=0.05','-D','hole_type="circle"')
)

Export-One -OutFile 'Test_Hole_Generator_Hex50to1095step05.stl' -Args @(
  $CommonArgs + @('-D','initial_hole_size=5','-D','final_hole_size=10.95','-D','hole_step_size=0.05','-D','hole_type="hexagon"')
)

Export-One -OutFile 'Test_Hole_Generator_Circle30to695step05.stl' -Args @(
  $CommonArgs + @('-D','initial_hole_size=3','-D','final_hole_size=6.95','-D','hole_step_size=0.05','-D','hole_type="circle"')
)

Write-Host "OK: exported STLs to $OutDir"
