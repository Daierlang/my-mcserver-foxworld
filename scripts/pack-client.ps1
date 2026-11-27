# pack-client.ps1 — 酒狐客户端整合包一键打包脚本
# 用法:  powershell -File scripts\pack-client.ps1 [-Version 2026-11-27]   (PowerShell 5.1+ 或 pwsh)
#        -Version 默认当天日期（yyyy-MM-dd），输出 dist\酒狐客户端_<Version>.zip
#
# 前提:
#   1. Java 21 在 PATH 中（本地启动游戏用；打包本身不需要）
#   2. 本机 PowerShell 的 Invoke-WebRequest/TLS 可能损坏（SEC_E_NO_CREDENTIALS），
#      脚本全部使用 curl.exe（Windows 10+ 自带）下载，不依赖 PowerShell 网络栈。
#   3. 打包来源:
#      - mods: 优先从 PCL 版本目录复制现成 jar；缺失项按 client/client-mods-manifest.txt
#        中的 Modrinth slug 经 API 按 SHA1 下载对应文件；来源为「手动下载」的 jar 从
#        client\manual-mods\（随仓库分发）复制
#      - 其余: 直接打包 client\ 下的 config / resourcepacks / shaderpacks / options.txt.template
#
# 产物结构（zip 内）: mods\ config\ resourcepacks\ shaderpacks\ options.txt
# 使用: 解压覆盖到 PCL 对应版本目录 foxworld_1.21.1-NeoForge_21.1.267\ 下即可。
param(
    [string]$Version = (Get-Date -Format 'yyyy-MM-dd')
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$repoRoot = Split-Path -Parent $PSScriptRoot   # E:\酒狐Server
$clientDir = Join-Path $repoRoot 'client'
$distDir = Join-Path $repoRoot 'dist'
$manifest = Join-Path $clientDir 'client-mods-manifest.txt'
$zipPath = Join-Path $distDir "酒狐客户端_$Version.zip"

if (-not (Test-Path $manifest)) { throw "找不到清单: $manifest" }
New-Item -ItemType Directory -Force -Path $distDir | Out-Null

# PCL 版本目录（现成 jar 来源）。可用 -ClientVersionDir 覆盖后另行指定。
$verDir = 'E:\BaiduNetdiskDownload\pcl\.minecraft\versions\foxworld_1.21.1-NeoForge_21.1.267'
if (-not (Test-Path $verDir)) { $verDir = $null }

$staging = Join-Path $env:TEMP ("pack-client-" + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force -Path "$staging\mods" | Out-Null
try {
    # ---------- mods ----------
    $entries = Get-Content -LiteralPath $manifest | Where-Object { $_ -match '\S' -and $_ -notmatch '^\s*#' }
    $dl = 0; $copy = 0; $fail = 0
    foreach ($line in $entries) {
        $parts = $line -split '\s*\|\s*'
        if ($parts.Count -lt 3) { continue }
        $name = $parts[0]; $sha1 = $parts[1]; $source = $parts[2]
        $dest = Join-Path "$staging\mods" $name
        # 1) 版本目录已有现成 jar
        $existing = $null
        if ($verDir) {
            $p = Join-Path "$verDir\mods" $name
            if (Test-Path -LiteralPath $p) { $existing = $p }
        }
        if ($existing) {
            Copy-Item -LiteralPath $existing -Destination $dest -Force
            $copy++
        }
        # 2) client\manual-mods\（随仓库分发的手动下载 jar）
        elseif (Test-Path -LiteralPath (Join-Path $clientDir 'manual-mods' $name)) {
            Copy-Item -LiteralPath (Join-Path $clientDir 'manual-mods' $name) -Destination $dest -Force
            $copy++
        }
        # 3) Modrinth: 按 SHA1 反查版本文件并下载
        elseif ($source -match '^Modrinth:\s*(\S+)') {
            $tmpJson = Join-Path $env:TEMP "mr_lookup_$sha1.json"
            curl.exe -s -m 60 -o $tmpJson "https://api.modrinth.com/v2/version_file/$sha1?algorithm=sha1"
            $ok = $false
            if ((Test-Path $tmpJson) -and ((Get-Item $tmpJson).Length -gt 2)) {
                try {
                    $hit = [IO.File]::ReadAllText($tmpJson) | ConvertFrom-Json
                    if ($hit -and $hit.files) {
                        $f = $hit.files | Where-Object { $_.primary } | Select-Object -First 1
                        if (-not $f) { $f = $hit.files | Select-Object -First 1 }
                        curl.exe -s -L -m 600 -o $dest $($f.url)
                        if ((Test-Path $dest) -and ((Get-Item $dest).Length -gt 1000)) {
                            # 校验 SHA1
                            $got = (Get-FileHash -LiteralPath $dest -Algorithm SHA1).Hash.ToLower()
                            if ($got -eq $sha1) { $ok = $true } else { Remove-Item -LiteralPath $dest -Force }
                        }
                    }
                } catch { }
                Remove-Item -LiteralPath $tmpJson -Force -ErrorAction SilentlyContinue
            }
            if ($ok) { $dl++ } else { Write-Warning "下载失败: $name ($sha1)"; $fail++ }
        }
        else {
            Write-Warning "跳过（手动下载且本地缺失）: $name"; $fail++
        }
    }
    "mods: 复制 $copy 个现成 jar, 下载 $dl 个, 失败/跳过 $fail 个"

    # ---------- 其余四件套 ----------
    foreach ($d in 'config','resourcepacks','shaderpacks') {
        if (Test-Path (Join-Path $clientDir $d)) {
            Copy-Item -LiteralPath (Join-Path $clientDir $d) -Destination $staging -Recurse -Force
        }
    }
    Copy-Item -LiteralPath (Join-Path $clientDir 'options.txt.template') -Destination "$staging\options.txt" -Force

    # ---------- zip ----------
    if (Test-Path $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
    Compress-Archive -Path "$staging\*" -DestinationPath $zipPath -CompressionLevel Optimal
    $sz = [math]::Round((Get-Item -LiteralPath $zipPath).Length / 1MB, 1)
    "完成: $zipPath ($sz MB)"
} finally {
    Remove-Item -LiteralPath $staging -Recurse -Force -ErrorAction SilentlyContinue
}
