#Requires -Version 7.3
[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$workspaceRoot = [IO.Path]::GetFullPath($PSScriptRoot)
$windhawkRoot = Join-Path $workspaceRoot 'tools\Windhawk'
$compilerRoot = Join-Path $windhawkRoot 'Compiler'
$compiler = Join-Path $compilerRoot 'bin\clang++.exe'
$source = Join-Path $workspaceRoot 'native\monitor-control-native.wh.cpp'
$outputFolder = Join-Path $workspaceRoot 'artifacts\native'
$output = Join-Path $outputFolder 'monitor-control-native.dll'
if (-not (Test-Path -LiteralPath $compiler)) { throw 'Нужен переносимый Windhawk в tools\Windhawk.' }
$null = New-Item -ItemType Directory -Path $outputFolder -Force
$arguments = @(
    '-std=c++23', '-O2', '-shared', '-DUNICODE', '-D_UNICODE',
    '-DWINVER=0x0A00', '-D_WIN32_WINNT=0x0A00', '-D_WIN32_IE=0x0A00',
    '-DNTDDI_VERSION=0x0A000008', '-D__USE_MINGW_ANSI_STDIO=0', '-DWH_MOD',
    '-DWH_MOD_ID=L"monitor-control-native"', '-DWH_MOD_VERSION=L"2.1.1"',
    (Join-Path $windhawkRoot 'Engine\1.7.3\64\windhawk.lib'),
    '-x', 'c++', $source, '-include', 'windhawk_api.h',
    '-target', 'x86_64-w64-mingw32', '-Wl,--export-all-symbols',
    '-ldxva2', '-lole32', '-loleaut32', '-lwbemuuid', '-luuid', '-lruntimeobject',
    '-o', $output
)
Push-Location -LiteralPath $compilerRoot
try {
    & $compiler @arguments
    if ($LASTEXITCODE -ne 0) { throw 'Не удалось собрать модуль панели Windows.' }
} finally { Pop-Location }
Get-Item -LiteralPath $output | Select-Object FullName, Length
