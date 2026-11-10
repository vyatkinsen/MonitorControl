[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$workspaceRoot = [IO.Path]::GetFullPath($PSScriptRoot)
$runtime = Join-Path $workspaceRoot 'tools\Windhawk'
$executable = Join-Path $runtime 'windhawk.exe'
$dll = Join-Path $workspaceRoot 'artifacts\native\monitor-control-native.dll'
if (-not (Test-Path -LiteralPath $dll)) { throw 'Сначала выполните Build-Native.ps1.' }
if (Get-Process windhawk -ErrorAction SilentlyContinue | Where-Object { $_.Path -eq $executable }) {
    throw 'Сначала остановите этот экземпляр: tools\Windhawk\windhawk.exe -exit -wait'
}
$mods = Join-Path $runtime 'AppData\Engine\Mods'
$binary = Join-Path $mods '64'
$sourceFolder = Join-Path $runtime 'AppData\ModsSource'
$null = New-Item -ItemType Directory -Path $binary,$sourceFolder -Force
Copy-Item -LiteralPath $dll -Destination (Join-Path $binary 'monitor-control-native.dll') -Force
Copy-Item -LiteralPath (Join-Path $runtime 'Compiler\x86_64-w64-mingw32\bin\libc++.dll') -Destination (Join-Path $binary 'libc++.whl') -Force
Copy-Item -LiteralPath (Join-Path $runtime 'Compiler\x86_64-w64-mingw32\bin\libunwind.dll') -Destination (Join-Path $binary 'libunwind.whl') -Force
Copy-Item -LiteralPath (Join-Path $runtime 'Compiler\x86_64-w64-mingw32\bin\windhawk-mod-shim.dll') -Destination $binary -Force
Copy-Item -LiteralPath (Join-Path $workspaceRoot 'native\monitor-control-native.wh.cpp') -Destination $sourceFolder -Force
$modConfig = @'
[Mod]
LibraryFileName=monitor-control-native.dll
Disabled=0
LoggingEnabled=1
DebugLoggingEnabled=0
Include=ShellHost.exe
Exclude=
IncludeCustom=
ExcludeCustom=
IncludeExcludeCustomOnly=0
PatternsMatchCriticalSystemProcesses=0
Architecture=x86-64
Version=2.1.1

[Settings]
hideStockBrightness=1
panelPosition=aboveSliders
hideUnsupported=0
followInternalBrightness=off
'@
$engineConfig = @'
[Settings]
Include=ShellHost.exe
Exclude=*
LoggingVerbosity=0
InjectIntoCriticalProcesses=0
InjectIntoIncompatiblePrograms=0
InjectIntoGames=0
'@
$appConfig = @'
[Settings]
Language=ru
HideTrayIcon=1
DisableUpdateCheck=1
SafeMode=0
LoggingVerbosity=0
'@
[IO.File]::WriteAllText((Join-Path $mods 'monitor-control-native.ini'), $modConfig, [Text.Encoding]::Unicode)
[IO.File]::WriteAllText((Join-Path $runtime 'AppData\Engine\settings.ini'), $engineConfig, [Text.Encoding]::Unicode)
[IO.File]::WriteAllText((Join-Path $runtime 'AppData\settings.ini'), $appConfig, [Text.Encoding]::Unicode)
$shell = New-Object -ComObject WScript.Shell
foreach ($item in @(@{Name='Включить яркость в панели Windows'; Args='-tray-only'}, @{Name='Отключить яркость в панели Windows'; Args='-exit -wait -timeout 10000'})) {
    $shortcut = $shell.CreateShortcut((Join-Path $workspaceRoot ($item.Name + '.lnk')))
    $shortcut.TargetPath = $executable
    $shortcut.Arguments = $item.Args
    $shortcut.WorkingDirectory = $runtime
    $shortcut.Save()
}
Write-Host 'Модуль подготовлен. Запуск: tools\Windhawk\windhawk.exe -tray-only'
