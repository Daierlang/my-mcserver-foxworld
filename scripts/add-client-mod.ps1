# add-client-mod.ps1 — 登记一个新客户端 mod 到 client/client-mods-manifest.txt
# 用法:  powershell -File scripts\add-client-mod.ps1 -Jar <jar 路径>   (PowerShell 5.1+ 或 pwsh)
# 流程:
#   1. 对 jar 计算 SHA1
#   2. curl.exe 调 Modrinth version_file API 按 SHA1 反查来源 slug
#      - 命中: manifest 追加一行「文件名 | SHA1 | Modrinth: <slug>」
#      - 未命中: jar 复制到 client\manual-mods\，manifest 追加「文件名 | SHA1 | 手动下载」
#        （manual-mods 目录随 Git 仓库分发，pack-client.ps1 打包时会从这里复制）
#   3. manifest 中已有同名文件则提示并退出，不写任何内容
# 本机 PowerShell 的 Invoke-WebRequest/TLS 可能损坏，所有网络请求一律走 curl.exe。
# 本脚本只改 manifest 和 manual-mods\，git add/commit/push 由维护者自己做。
param(
    [Parameter(Mandatory = $true)]
    [string]$Jar
)
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$repoRoot = Split-Path -Parent $PSScriptRoot   # E:\酒狐Server
$clientDir = Join-Path $repoRoot 'client'
$manifest = Join-Path $clientDir 'client-mods-manifest.txt'
$manualDir = Join-Path $clientDir 'manual-mods'

if (-not (Test-Path -LiteralPath $Jar)) { throw "找不到 jar: $Jar" }
if (-not (Test-Path $manifest)) { throw "找不到清单: $manifest" }

$jarItem = Get-Item -LiteralPath $Jar
$name = $jarItem.Name

# ---------- manifest 已有同名文件则退出 ----------
$existingLines = Get-Content -LiteralPath $manifest
foreach ($line in $existingLines) {
    if ($line -match '\S' -and $line -notmatch '^\s*#') {
        $parts = $line -split '\s*\|\s*'
        if ($parts.Count -ge 1 -and $parts[0].Trim() -eq $name) {
            Write-Host "清单中已存在同名条目: $name"
            Write-Host "如需替换版本，请先手动删除 manifest 中的旧行，再重新运行本脚本。"
            exit 1
        }
    }
}

# ---------- SHA1 ----------
$sha1 = (Get-FileHash -LiteralPath $jarItem.FullName -Algorithm SHA1).Hash.ToLower()
"SHA1: $sha1"

# ---------- Modrinth 反查 ----------
$slug = $null
$tmpJson = Join-Path $env:TEMP "mr_lookup_$sha1.json"
curl.exe -s -m 60 -o $tmpJson "https://api.modrinth.com/v2/version_file/$sha1`?algorithm=sha1"
if ((Test-Path -LiteralPath $tmpJson) -and ((Get-Item -LiteralPath $tmpJson).Length -gt 2)) {
    try {
        $hit = [IO.File]::ReadAllText($tmpJson) | ConvertFrom-Json
        if ($hit -and $hit.files) {
            $slug = $hit.project_id   # version_file API 不直接给 slug，先取 project_id
        }
    } catch { }
    Remove-Item -LiteralPath $tmpJson -Force -ErrorAction SilentlyContinue
}

if ($slug) {
    # project_id -> slug（项目接口）
    $tmpProj = Join-Path $env:TEMP "mr_proj_$slug.json"
    curl.exe -s -m 60 -o $tmpProj "https://api.modrinth.com/v2/project/$slug"
    if ((Test-Path -LiteralPath $tmpProj) -and ((Get-Item -LiteralPath $tmpProj).Length -gt 2)) {
        try {
            $proj = [IO.File]::ReadAllText($tmpProj) | ConvertFrom-Json
            if ($proj -and $proj.slug) { $slug = $proj.slug }
        } catch { }
        Remove-Item -LiteralPath $tmpProj -Force -ErrorAction SilentlyContinue
    }
    $source = "Modrinth: $slug"
    Write-Host "命中 Modrinth: $slug"
} else {
    # ---------- 未命中: 复制到 manual-mods ----------
    New-Item -ItemType Directory -Force -Path $manualDir | Out-Null
    Copy-Item -LiteralPath $jarItem.FullName -Destination (Join-Path $manualDir $name) -Force
    $source = '手动下载'
    Write-Host "Modrinth 未命中，jar 已复制到 client\manual-mods\$name（随仓库分发）"
}

# ---------- 追加 manifest ----------
Add-Content -LiteralPath $manifest -Value "$name | $sha1 | $source" -Encoding UTF8
Write-Host "已追加到 manifest: $name | $sha1 | $source"

# ---------- 下一步提示 ----------
Write-Host ""
Write-Host "下一步（git 操作请自己执行）:"
$extra = ''
if ($source -eq '手动下载') { $extra = " client/manual-mods/$name" }
Write-Host "  git add client/client-mods-manifest.txt$extra"
Write-Host "  git commit -m `"add client mod: $name`""
Write-Host "  git push"
Write-Host "其他人 git pull 后运行 scripts\pack-client.ps1 即可得到含该 mod 的最新客户端包。"
