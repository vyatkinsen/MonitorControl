[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$workspaceRoot = [IO.Path]::GetFullPath($PSScriptRoot)
$runtime = Join-Path $workspaceRoot 'tools\Windhawk'
$destination = Join-Path $workspaceRoot 'dist\MonitorControl-Native'
$archive = Join-Path $workspaceRoot 'dist\MonitorControl-Native-win-x64.zip'
if (Test-Path -LiteralPath $destination) { throw 'Папка пакета уже существует. Используйте новую папку или сохраните предыдущую версию.' }
$packageRuntime = Join-Path $destination 'Windhawk'
$null = New-Item -ItemType Directory -Path $packageRuntime -Force
foreach ($name in @('windhawk.exe','windhawk-x64-helper.exe','windhawk.ini','command-line.txt','Engine','UI')) {
    Copy-Item -LiteralPath (Join-Path $runtime $name) -Destination $packageRuntime -Recurse
}
$packageAppData = Join-Path $packageRuntime 'AppData'
$packageEngineData = Join-Path $packageAppData 'Engine'
$null = New-Item -ItemType Directory -Path $packageEngineData -Force
Copy-Item -LiteralPath (Join-Path $runtime 'AppData\settings.ini') -Destination $packageAppData
Copy-Item -LiteralPath (Join-Path $runtime 'AppData\ModsSource') -Destination $packageAppData -Recurse
Copy-Item -LiteralPath (Join-Path $runtime 'AppData\Engine\settings.ini') -Destination $packageEngineData
Copy-Item -LiteralPath (Join-Path $runtime 'AppData\Engine\Mods') -Destination $packageEngineData -Recurse
Copy-Item -LiteralPath (Join-Path $workspaceRoot 'native') -Destination $destination -Recurse
[IO.File]::WriteAllText((Join-Path $destination 'Запустить.cmd'), "@echo off`r`nstart `"`" `"%~dp0Windhawk\windhawk.exe`" -tray-only`r`n", [Text.Encoding]::ASCII)
[IO.File]::WriteAllText((Join-Path $destination 'Остановить.cmd'), "@echo off`r`n`"%~dp0Windhawk\windhawk.exe`" -exit -wait -timeout 10000`r`n", [Text.Encoding]::ASCII)
$readme = @'
# Яркость в системной панели Windows

1. Распакуйте всю папку в постоянное место.
2. Если уже работает другая переносимая копия Windhawk, сначала завершите её.
3. Запустите «Запустить.cmd».
4. Откройте быстрые настройки Windows возле часов или через Win+A. Яркость находится над громкостью, внутри системной панели.
5. «Остановить.cmd» убирает расширение. Последняя яркость сохраняется.

Отдельной иконки в трее нет. Автозапуск не добавляется. Администратор и драйвер не нужны.

Проверено пользователем: AQW34H3, NVIDIA RTX 5070, Windows 11 26H2 26300.9711 — ползунок появился и меняет яркость монитора. Поддержка других экранов зависит от DDC/CI либо WMI. Нужен ShellHost.exe; обновления Windows могут потребовать обновления модуля.

При первом запуске Windhawk может загрузить от Microsoft отладочные символы соответствующей сборки Windows. Движок настроен только на ShellHost.exe. Изменение яркости при запуске не выполняется.

Модуль Monitor Control 2.1.1 основан на Per-monitor brightness in Quick Settings 2.1 (bardelyne), GPL v3. Исходники, лицензия и атрибуция находятся в native. Переносимая среда Windhawk 1.7.3: https://github.com/ramensoftware/windhawk/releases/tag/v1.7.3 . Компилятор не входит в этот пакет; для пересборки модуля используйте полную поставку Windhawk.
'@
[IO.File]::WriteAllText((Join-Path $destination 'README.md'), $readme, [Text.UTF8Encoding]::new($false))
$originalHash = (Get-FileHash -LiteralPath (Join-Path $workspaceRoot 'artifacts\native\monitor-control-native.dll')).Hash
$packagedHash = (Get-FileHash -LiteralPath (Join-Path $packageEngineData 'Mods\64\monitor-control-native.dll')).Hash
if ($originalHash -ne $packagedHash) { throw 'Пакет содержит другую версию модуля.' }
Compress-Archive -LiteralPath $destination -DestinationPath $archive -CompressionLevel Optimal
Get-Item -LiteralPath $archive | Select-Object FullName, Length
