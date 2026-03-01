###############################################################################
#  DayZ Market Price Converter
#
#  FORMEL:  NeuerPreis = round( 0.976425 * AlterPreis ^ 0.551901 )
#
#  R^2 = 0.9974 (99.74% Genauigkeit)
###############################################################################

param(
    [double]$Price = 0,
    [string]$File = "",
    [string]$Folder = "",
    [double]$A = 0.976425,
    [double]$B = 0.551901,
    [switch]$DryRun,
    [switch]$NoBackup
)

function Convert-Price {
    param([double]$OldPrice, [double]$A, [double]$B)
    if ($OldPrice -le 0) { return 0 }
    if ($OldPrice -eq 1) { return 1 }
    $newPrice = [Math]::Round($A * [Math]::Pow($OldPrice, $B))
    if ($newPrice -lt 1) { $newPrice = 1 }
    return [int]$newPrice
}

# === Modus 1: Einzelner Preis ===
if ($Price -gt 0 -and $File -eq '' -and $Folder -eq '') {
    $result = Convert-Price -OldPrice $Price -A $A -B $B
    $reduction = if ($Price -gt 0) { [Math]::Round((1 - $result / $Price) * 100, 2) } else { 0 }
    Write-Host ''
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host '  PREIS-UMRECHNUNG' -ForegroundColor Cyan
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host "  Formel:       NeuerPreis = $A * AlterPreis ^ $B"
    Write-Host "  Alter Preis:  $Price" -ForegroundColor Yellow
    Write-Host "  Neuer Preis:  $result" -ForegroundColor Green
    Write-Host "  Reduktion:    $reduction %" -ForegroundColor Red
    Write-Host ''
    Write-Host '  Referenztabelle:' -ForegroundColor Cyan
    Write-Host '  -----------------------------------------'
    Write-Host ('  {0,-15} {1,-15} {2,-10}' -f 'ALTER PREIS', 'NEUER PREIS', 'REDUKTION')
    Write-Host '  -----------------------------------------'
    $examples = @(1, 5, 10, 50, 100, 500, 1000, 5000, 10000, 50000, 100000, 500000, 1000000, 5000000, 10000000, 50000000, 100000000, 500000000)
    foreach ($ex in $examples) {
        $conv = Convert-Price -OldPrice $ex -A $A -B $B
        $red = [Math]::Round((1 - $conv / $ex) * 100, 1)
        Write-Host ('  {0,-15:N0} {1,-15:N0} {2,-10}' -f $ex, $conv, "$red %")
    }
    Write-Host '  -----------------------------------------'
    exit 0
}

# === JSON-Datei konvertieren ===
function Convert-MarketFile {
    param([string]$FilePath, [double]$A, [double]$B, [bool]$DryRun, [bool]$NoBackup)
    if (-not (Test-Path $FilePath)) {
        Write-Host "  FEHLER: Datei nicht gefunden: $FilePath" -ForegroundColor Red
        return @{Changed=0; Total=0}
    }
    $fileName = Split-Path $FilePath -Leaf
    try {
        $content = Get-Content $FilePath -Raw -Encoding UTF8
        $json = $content | ConvertFrom-Json
    } catch {
        Write-Host "  FEHLER beim Lesen von $fileName : $_" -ForegroundColor Red
        return @{Changed=0; Total=0}
    }
    if (-not $json.Items) {
        Write-Host "  UEBERSPRUNGEN: $fileName (keine Items)" -ForegroundColor Gray
        return @{Changed=0; Total=0}
    }
    $changedCount = 0
    $totalItems = $json.Items.Count
    foreach ($item in $json.Items) {
        $itemChanged = $false
        if ($null -ne $item.MaxPriceThreshold -and $item.MaxPriceThreshold -gt 0) {
            $oldMax = $item.MaxPriceThreshold
            $newMax = Convert-Price -OldPrice $oldMax -A $A -B $B
            if ($oldMax -ne $newMax) {
                if ($DryRun) { Write-Host "    [DRY-RUN] $($item.ClassName): MaxPrice $oldMax -> $newMax" -ForegroundColor DarkYellow }
                $item.MaxPriceThreshold = $newMax
                $itemChanged = $true
            }
        }
        if ($null -ne $item.MinPriceThreshold -and $item.MinPriceThreshold -gt 0) {
            $oldMin = $item.MinPriceThreshold
            $newMin = Convert-Price -OldPrice $oldMin -A $A -B $B
            if ($oldMin -ne $newMin) {
                if ($DryRun) { Write-Host "    [DRY-RUN] $($item.ClassName): MinPrice $oldMin -> $newMin" -ForegroundColor DarkYellow }
                $item.MinPriceThreshold = $newMin
                $itemChanged = $true
            }
        }
        if ($itemChanged) { $changedCount++ }
    }
    if (-not $DryRun -and $changedCount -gt 0) {
        if (-not $NoBackup) {
            $backupDir = Join-Path (Split-Path $FilePath -Parent) 'BACKUP_BEFORE_CONVERT'
            if (-not (Test-Path $backupDir)) { New-Item -ItemType Directory -Path $backupDir -Force | Out-Null }
            Copy-Item $FilePath (Join-Path $backupDir $fileName) -Force
        }
        $json | ConvertTo-Json -Depth 10 | Out-File $FilePath -Encoding UTF8
    }
    $status = if ($DryRun) { '[DRY-RUN]' } else { '[OK]' }
    $color = if ($changedCount -gt 0) { 'Green' } else { 'Gray' }
    Write-Host "  $status $fileName - $changedCount / $totalItems Items geaendert" -ForegroundColor $color
    return @{Changed=$changedCount; Total=$totalItems}
}

# === Modus 2: Einzelne Datei ===
if ($File -ne '') {
    Write-Host ''
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host '  DATEI KONVERTIEREN' -ForegroundColor Cyan
    Write-Host "  Formel: NeuerPreis = $A * AlterPreis ^ $B" -ForegroundColor Cyan
    if ($DryRun) { Write-Host '  *** DRY-RUN MODUS ***' -ForegroundColor Yellow }
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host ''
    $result = Convert-MarketFile -FilePath $File -A $A -B $B -DryRun $DryRun -NoBackup $NoBackup
    Write-Host ''
    Write-Host "  Fertig! $($result.Changed) Items geaendert." -ForegroundColor Green
    exit 0
}

# === Modus 3: Ganzer Ordner ===
if ($Folder -ne '') {
    if (-not (Test-Path $Folder)) { Write-Host "FEHLER: Ordner nicht gefunden: $Folder" -ForegroundColor Red; exit 1 }
    $files = Get-ChildItem -Path $Folder -Filter '*.json' -File | Where-Object { $_.DirectoryName -eq $Folder }
    Write-Host ''
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host '  ORDNER KONVERTIEREN' -ForegroundColor Cyan
    Write-Host "  Formel: NeuerPreis = $A * AlterPreis ^ $B" -ForegroundColor Cyan
    Write-Host "  Ordner: $Folder" -ForegroundColor Cyan
    Write-Host "  Dateien: $($files.Count)" -ForegroundColor Cyan
    if ($DryRun) { Write-Host '  *** DRY-RUN MODUS ***' -ForegroundColor Yellow }
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host ''
    $totalChanged = 0; $totalItems = 0; $filesChanged = 0
    foreach ($f in $files) {
        $result = Convert-MarketFile -FilePath $f.FullName -A $A -B $B -DryRun $DryRun -NoBackup $NoBackup
        $totalChanged += $result.Changed
        $totalItems += $result.Total
        if ($result.Changed -gt 0) { $filesChanged++ }
    }
    Write-Host ''
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host '  ZUSAMMENFASSUNG' -ForegroundColor Cyan
    Write-Host '========================================' -ForegroundColor Cyan
    Write-Host "  Dateien verarbeitet:  $($files.Count)"
    Write-Host "  Dateien geaendert:    $filesChanged" -ForegroundColor Green
    Write-Host "  Items gesamt:         $totalItems"
    Write-Host "  Items geaendert:      $totalChanged" -ForegroundColor Green
    if (-not $DryRun -and -not $NoBackup -and $filesChanged -gt 0) {
        Write-Host ''
        Write-Host "  Backup in: $Folder\BACKUP_BEFORE_CONVERT\" -ForegroundColor Yellow
    }
    Write-Host '========================================' -ForegroundColor Cyan
    exit 0
}

# === Hilfe ===
Write-Host ''
Write-Host '  DayZ Market Price Converter' -ForegroundColor Cyan
Write-Host '  Formel: NeuerPreis = A * AlterPreis ^ B' -ForegroundColor Yellow
Write-Host '  Standard: A=0.976425, B=0.551901' -ForegroundColor Yellow
Write-Host ''
Write-Host '  Verwendung:' -ForegroundColor Cyan
Write-Host '    .\PriceConverter.ps1 -Price 1000000'
Write-Host '    .\PriceConverter.ps1 -File "Cars.json"'
Write-Host '    .\PriceConverter.ps1 -Folder "C:\path\Market"'
Write-Host '    .\PriceConverter.ps1 -Folder "C:\path" -DryRun'
Write-Host '    .\PriceConverter.ps1 -Folder "C:\path" -A 1.5 -B 0.45'
Write-Host ''
