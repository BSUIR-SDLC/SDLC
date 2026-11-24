param([string]$Only = '')
# Рисует HTML-страницы в PNG через Edge без окна: src\имя.html -> img\имя.png, размер берётся из <svg width/height> или data-size
$ErrorActionPreference = 'Stop'
$dir = $PSScriptRoot
$outDir = Split-Path $dir
$edge = 'C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe'
foreach ($f in Get-ChildItem $dir -Filter *.html) {
    if ($Only -and $f.BaseName -notlike $Only) { continue }
    $html = [IO.File]::ReadAllText($f.FullName)
    $m = [regex]::Match($html, 'data-size="(\d+)x(\d+)"')
    if (-not $m.Success) { $m = [regex]::Match($html, '<svg width="(\d+)" height="(\d+)"') }
    if (-not $m.Success) { continue }
    $w = $m.Groups[1].Value; $h = $m.Groups[2].Value
    $out = "$outDir\$($f.BaseName).png"
    $url = 'file:///' + ($f.FullName -replace '\\', '/')
    $p = Start-Process $edge -ArgumentList "--headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1.5 --virtual-time-budget=4000 --window-size=$w,$h --screenshot=`"$out`" `"$url`"" -PassThru -WindowStyle Hidden
    if (-not $p.WaitForExit(60000)) { $p.Kill() }
    "{0}: {1}" -f $f.BaseName, (Test-Path $out)
}
