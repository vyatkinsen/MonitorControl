[CmdletBinding()]
param([switch] $Disable)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$valueName = 'MonitorControlNative'
$registryPath = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$executable = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot 'tools\Windhawk\windhawk.exe'))
if ($Disable) {
    if (Test-Path -LiteralPath $registryPath) {
        Remove-ItemProperty -LiteralPath $registryPath -Name $valueName -ErrorAction SilentlyContinue
    }
    Write-Host 'Автозапуск выключен. Работающий ползунок остаётся доступен до выхода из приложения.'
    return
}
if (-not (Test-Path -LiteralPath $executable -PathType Leaf)) { throw 'Сначала установите переносимый Windhawk через Setup-Windhawk.ps1.' }
$command = '"' + $executable + '" -tray-only'
$null = New-Item -Path $registryPath -Force
$null = New-ItemProperty -LiteralPath $registryPath -Name $valueName -Value $command -PropertyType String -Force
$saved = Get-ItemPropertyValue -LiteralPath $registryPath -Name $valueName
if ($saved -ne $command) { throw 'Не удалось проверить сохранённую настройку автозапуска.' }
Write-Host 'Автозапуск включён для текущей учётной записи. Расширение запустится после входа в Windows.'
