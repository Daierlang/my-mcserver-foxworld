# Download mods from Modrinth API to E:\酒狐Server\mods
$ErrorActionPreference = 'Continue'
$modsDir = $args[0]
$slugs = @(
    'touhou-little-maid',      # TLM
    'geckolib',                # GeckoLib
    'touhou-little-maid-spell',# 万法皆通
    'spice-of-life-maid',      # 酒狐萝贝
    'touhoulittlemaid-feast-wine-all-gone', # 亿宴酊蒸
    'kaleidoscopetavern',      # 森罗酒馆
    'kaleidoscope-cookery',    # 森罗厨房
    'kaleidoscope-world-liquor', # 世界名酒
    'fox-trot-brew',           # 狐步酿香
    'maid-tavern',             # 女仆酒馆
    'farmers-delight',         # Farmer's Delight
    'brewin-and-chewin',       # Brewin And Chewin
    'lets-do-vinery',          # Vinery
    'lightmans-currency',      # LC
    'open-parties-and-claims', # OPAC
    'waystones',               # Waystones
    'terralith',               # Terralith
    'better-village',          # Better Villages
    'dungeons-and-taverns',    # DnT
    'chunky',                  # Chunky
    'chunkyborder',            # Chunky Border
    'advanced-backups',        # Advanced Backups
    'spark',                   # spark
    'ferrite-core',            # FerriteCore
    'modernfix',               # ModernFix
    'jei',                     # JEI
    'jade',                    # Jade
    'appleskin',               # AppleSkin
    'tameable-foxes'           # Tameable Foxes
)
$results = @()
foreach ($slug in $slugs) {
    $ok = $false
    for ($try = 1; $try -le 2 -and -not $ok; $try++) {
        try {
            $u = "https://api.modrinth.com/v2/project/$slug/version?game_versions=%5B%221.21.1%22%5D&loaders=%5B%22neoforge%22%5D"
            $r = Invoke-WebRequest -UseBasicParsing -Uri $u -TimeoutSec 60
            $vs = $r.Content | ConvertFrom-Json
            if (-not $vs -or $vs.Count -eq 0) { $results += "SKIP  $slug  no 1.21.1+neoforge version"; break }
            $v = $vs[0]
            $f = $v.files | Where-Object { $_.primary } | Select-Object -First 1
            if (-not $f) { $f = $v.files | Select-Object -First 1 }
            $fn = [uri]::UnescapeDataString(([uri]$f.url).Segments[-1])
            $dest = Join-Path $modsDir $fn
            if (-not (Test-Path $dest)) {
                Invoke-WebRequest -UseBasicParsing -Uri $f.url -OutFile $dest -TimeoutSec 300
            }
            $results += "OK    $slug  $($v.version_number)  $fn"
            $ok = $true
        } catch {
            if ($try -eq 2) { $results += "FAIL  $slug  $($_.Exception.Message)" }
            Start-Sleep -Seconds 3
        }
    }
}
$results

