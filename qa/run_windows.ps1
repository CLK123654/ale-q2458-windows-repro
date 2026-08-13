$ErrorActionPreference = 'Stop'

$workspace = Join-Path $env:RUNNER_TEMP 'q2458'
$inputRoot = Join-Path $workspace 'input'
$referenceRoot = Join-Path $workspace 'reference'
$actualRoot = Join-Path $workspace 'actual'
New-Item -ItemType Directory -Path $inputRoot,$referenceRoot,$actualRoot -Force | Out-Null
Expand-Archive -Path './task/输入数据包.zip' -DestinationPath $inputRoot -Force
Expand-Archive -Path './task/reference.zip' -DestinationPath $referenceRoot -Force

$matlabRoot = (Resolve-Path (Join-Path $referenceRoot 'output/matlab')).Path.Replace('\','/')
$inputPath = (Resolve-Path (Join-Path $inputRoot 'input_data')).Path.Replace('\','/')
$resultPath = (Join-Path $actualRoot 'results').Replace('\','/')
matlab -batch "addpath('$matlabRoot'); run_edge_degradation_audit('$inputPath','$resultPath');"

$expected = Join-Path $referenceRoot 'output/results'
$actualFiles = Get-ChildItem -Path $actualRoot -File -Recurse | ForEach-Object { $_.FullName.Substring($actualRoot.Length + 1) }
$expectedFiles = Get-ChildItem -Path $expected -File -Recurse | ForEach-Object { $_.FullName.Substring($expected.Length + 1) }
if (Compare-Object $expectedFiles $actualFiles) { throw '结果文件集合不一致' }
foreach ($relative in $expectedFiles) {
  $left = (Get-FileHash (Join-Path $expected $relative) -Algorithm SHA256).Hash
  $right = (Get-FileHash (Join-Path $actualRoot $relative) -Algorithm SHA256).Hash
  if ($left -ne $right) { throw "结果内容不一致: $relative" }
}
