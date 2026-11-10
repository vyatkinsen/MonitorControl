#Requires -Version 7.0
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$version = '1.7.3'
$expectedHash = '4d93016570f982326eebdfc9068e924ff21f6448534ea32672bb4c1d52a8193b'
$downloadUrl = "https://github.com/ramensoftware/windhawk/releases/download/v$version/windhawk_setup_offline.exe"
$workspaceRoot = [IO.Path]::GetFullPath($PSScriptRoot)
$runtime = Join-Path $workspaceRoot 'tools\Windhawk'
$downloads = Join-Path $workspaceRoot 'tools\downloads'
$installer = Join-Path $downloads "windhawk_setup_offline-$version.exe"

function Test-PreparedRuntime {
    $required = @(
        'windhawk.exe', 'windhawk-x64-helper.exe', 'windhawk.ini',
        'Compiler\bin\clang++.exe', 'Compiler\include\windhawk_api.h',
        "Engine\$version\64\windhawk.dll", "Engine\$version\64\windhawk.lib",
        "Engine\$version\engine.ini"
    )
    foreach ($relativePath in $required) {
        if (-not (Test-Path -LiteralPath (Join-Path $runtime $relativePath) -PathType Leaf)) { return $false }
    }
    if ((Get-Item -LiteralPath (Join-Path $runtime 'windhawk.exe')).VersionInfo.ProductVersion -ne $version) { return $false }
    $storage = Get-Content -LiteralPath (Join-Path $runtime 'windhawk.ini') -Raw
    $engineStorage = Get-Content -LiteralPath (Join-Path $runtime "Engine\$version\engine.ini") -Raw
    return $storage -match '(?m)^Portable=1\s*$' -and
        $storage -match '(?m)^CompilerPath=Compiler\s*$' -and
        $storage -match "(?m)^EnginePath=Engine\\$([regex]::Escape($version))\s*$" -and
        $storage -match '(?m)^AppDataPath=AppData\s*$' -and
        $engineStorage -match '(?m)^Portable=1\s*$'
}

if (Test-PreparedRuntime) {
    Write-Host "Windhawk $version и компилятор уже подготовлены: $runtime"
    Write-Host 'Существующая установка и запущенные процессы не изменены.'
    return
}
if (Test-Path -LiteralPath $runtime) {
    if (-not (Test-Path -LiteralPath $runtime -PathType Container) -or
        @(Get-ChildItem -LiteralPath $runtime -Force).Count -gt 0) {
        throw "Папка $runtime уже существует, но не содержит ожидаемую переносимую версию $version. Скрипт не перезаписывает её. Сохраните эту папку и подготовьте зависимость в чистой копии проекта."
    }
}

$null = New-Item -ItemType Directory -Path $downloads -Force
if (-not (Test-Path -LiteralPath $installer -PathType Leaf)) {
    Write-Host "Загрузка официального Windhawk $version..."
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installer -TimeoutSec 180
}
if ((Get-FileHash -LiteralPath $installer -Algorithm SHA256).Hash -ne $expectedHash) {
    throw "Контрольная сумма установщика не совпадает. Файл не запущен: $installer"
}
$signature = Get-AuthenticodeSignature -LiteralPath $installer
if ($signature.Status -ne 'Valid' -or $null -eq $signature.SignerCertificate -or
    $signature.SignerCertificate.GetNameInfo([Security.Cryptography.X509Certificates.X509NameType]::SimpleName, $false) -ne 'Open Source Developer, Michael Maltsev') {
    throw "Подпись установщика или его издатель не подтверждены. Файл не запущен: $installer"
}

$appData = Join-Path $runtime 'AppData'
$engineData = Join-Path $appData 'Engine'
$null = New-Item -ItemType Directory -Path $engineData -Force
$appSettings = "[Settings]`r`nLanguage=ru`r`nHideTrayIcon=1`r`nDisableUpdateCheck=1`r`nSafeMode=1`r`n"
$engineSettings = "[Settings]`r`nInclude=ShellHost.exe`r`nExclude=*`r`nInjectIntoCriticalProcesses=0`r`nInjectIntoIncompatiblePrograms=0`r`nInjectIntoGames=0`r`n"
[IO.File]::WriteAllText((Join-Path $appData 'settings.ini'), $appSettings, [Text.Encoding]::Unicode)
[IO.File]::WriteAllText((Join-Path $engineData 'settings.ini'), $engineSettings, [Text.Encoding]::Unicode)

# NSIS requires /D to be the final argument; its path is not wrapped in quotes.
# Portable extraction uses the current user's folder and does not request elevation.
Write-Host 'Подготовка переносимой среды и компилятора...'
$process = Start-Process -FilePath $installer -ArgumentList ("/portable /S /D=" + $runtime) -WindowStyle Hidden -PassThru
if (-not $process.WaitForExit(60000)) {
    throw "Установщик ещё работает (PID $($process.Id)). Не запускайте второй экземпляр. После его завершения повторите проверку; скрипт не останавливает процессы."
}
if ($process.ExitCode -ne 0) { throw "Установщик завершился с кодом $($process.ExitCode). Папка сохранена: $runtime" }
if (-not (Test-PreparedRuntime)) { throw "Проверка переносимой установки не пройдена. Папка сохранена: $runtime" }

# Keep this newly prepared runtime inactive until Install-Native.ps1 configures it.
[IO.File]::WriteAllText((Join-Path $appData 'settings.ini'), $appSettings, [Text.Encoding]::Unicode)
[IO.File]::WriteAllText((Join-Path $engineData 'settings.ini'), $engineSettings, [Text.Encoding]::Unicode)
Write-Host "Готово: Windhawk $version и компилятор в $runtime"
Write-Host 'Windhawk не запущен скриптом; автозапуск не добавлен. Далее: Build.ps1 и Install-Native.ps1.'
