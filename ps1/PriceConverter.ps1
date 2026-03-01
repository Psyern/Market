###############################################################################
#  DayZ Market Price Converter  -  Drag & Drop Edition
#
#  VERWENDUNG:
#    1. PowerShell oeffnen
#    2. Diese .ps1 Datei in die PowerShell ziehen
#    3. Leertaste druecken
#    4. Eine .json Datei ODER einen Ordner mit .json Dateien reinziehen
#    5. Enter druecken
#
#  Die konvertierten Dateien landen im Unterordner "NewMarket" neben der
#  Originaldatei. Originale werden NICHT veraendert.
#
#  FORMEL:  NeuerPreis = round( 0.976425 * AlterPreis ^ 0.551901 )
#
#  OPTIONALE PARAMETER (nach dem Pfad):
#    -A 0.976425       Koeffizient anpassen
#    -B 0.551901       Exponent anpassen (kleiner = aggressiver)
#    -DryRun           Nur anzeigen, nichts schreiben
#
#  BEISPIELE:
#    .\PriceConverter.ps1 "C:\Market\Cars.json"
#    .\PriceConverter.ps1 "C:\Market"
#    .\PriceConverter.ps1 "C:\Market" -B 0.65
#    .\PriceConverter.ps1 "C:\Market\Cars.json" -DryRun
###############################################################################

param(
    [Parameter(Position=0)]
    [string]$Path = '',
    [double]$A = 0.976425,
    [double]$B = 0.551901,
    [switch]$DryRun
)

# --- Anfuehrungszeichen entfernen (Drag & Drop fuegt manchmal welche hinzu) ---
$Path = $Path.Trim('"').Trim("'").Trim()

# ============================================================================
#  Formel
# ============================================================================
function Convert-Price {
    param([double]$OldPrice, [double]$A, [double]$B)
    if ($OldPrice -le 0) { return 0 }
    if ($OldPrice -eq 1) { return 1 }
    $newPrice = [Math]::Round($A * [Math]::Pow($OldPrice, $B))
    if ($newPrice -lt 1) { $newPrice = 1 }
    return [int]$newPrice
}

# ============================================================================
#  Eine JSON-Datei konvertieren -> in OutputDir speichern
# ============================================================================
function Convert-MarketFile {
    param(
        [string]$FilePath,
        [string]$OutputDir,
        [double]$A,
        [double]$B,
        [bool]$DryRun
    )

    $fileName = Split-Path $FilePath -Leaf

    if (-not (Test-Path $FilePath)) {
        Write-Host "  FEHLER: Nicht gefunden: $fileName" -ForegroundColor Red
        return @{Changed=0; Total=0; Skipped=$true}
    }

    try {
        $content = Get-Content $FilePath -Raw -Encoding UTF8
        $json = $content | ConvertFrom-Json
    } catch {
        Write-Host "  FEHLER: $fileName kann nicht gelesen werden" -ForegroundColor Red
        return @{Changed=0; Total=0; Skipped=$true}
    }

    if (-not $json.Items) {
        Write-Host "  SKIP  $fileName (keine Items)" -ForegroundColor DarkGray
        # Datei trotzdem kopieren
        if (-not $DryRun) {
            Copy-Item $FilePath (Join-Path $OutputDir $fileName) -Force
        }
        return @{Changed=0; Total=0; Skipped=$false}
    }

    $changedCount = 0
    $totalItems = $json.Items.Count

    foreach ($item in $json.Items) {
        $itemChanged = $false

        if ($null -ne $item.MaxPriceThreshold -and $item.MaxPriceThreshold -gt 1) {
            $oldVal = $item.MaxPriceThreshold
            $newVal = Convert-Price -OldPrice $oldVal -A $A -B $B
            if ($oldVal -ne $newVal) {
                $item.MaxPriceThreshold = $newVal
                $itemChanged = $true
            }
        }

        if ($null -ne $item.MinPriceThreshold -and $item.MinPriceThreshold -gt 1) {
            $oldVal = $item.MinPriceThreshold
            $newVal = Convert-Price -OldPrice $oldVal -A $A -B $B
            if ($oldVal -ne $newVal) {
                $item.MinPriceThreshold = $newVal
                $itemChanged = $true
            }
        }

        if ($itemChanged) { $changedCount++ }
    }

    # Speichern in NewMarket Ordner
    if (-not $DryRun) {
        $outPath = Join-Path $OutputDir $fileName
        $json | ConvertTo-Json -Depth 10 | Out-File $outPath -Encoding UTF8
    }

    $icon = if ($changedCount -gt 0) { 'OK' } else { '--' }
    $color = if ($changedCount -gt 0) { 'Green' } else { 'Gray' }
    if ($DryRun) { $icon = 'DRY' }
    Write-Host "  [$icon]  $fileName  ($changedCount / $totalItems Items)" -ForegroundColor $color

    return @{Changed=$changedCount; Total=$totalItems; Skipped=$false}
}

# ============================================================================
#  Kein Pfad? -> Hilfe anzeigen
# ============================================================================
if ($Path -eq '') {
    Write-Host ''
    Write-Host '  ============================================' -ForegroundColor Cyan
    Write-Host '   DayZ Market Price Converter' -ForegroundColor Cyan
    Write-Host '   Drag and Drop Edition' -ForegroundColor Cyan
    Write-Host '  ============================================' -ForegroundColor Cyan
    Write-Host ''
    Write-Host '  SO GEHTS:' -ForegroundColor Yellow
    Write-Host '    1. PowerShell oeffnen'
    Write-Host '    2. Diese .ps1 Datei reinziehen'
    Write-Host '    3. Leertaste druecken'
    Write-Host '    4. JSON-Datei oder Market-Ordner reinziehen'
    Write-Host '    5. Enter druecken'
    Write-Host ''
    Write-Host '  ERGEBNIS:' -ForegroundColor Yellow
    Write-Host '    Konvertierte Dateien landen im Unterordner'
    Write-Host '    "NewMarket" neben den Originalen.'
    Write-Host '    Originale bleiben unberuehrt!'
    Write-Host ''
    Write-Host '  FORMEL:' -ForegroundColor Yellow
    Write-Host "    NeuerPreis = $A * AlterPreis ^ $B"
    Write-Host ''
    Write-Host '  OPTIONEN (nach dem Pfad):' -ForegroundColor Yellow
    Write-Host '    -B 0.65       Weniger aggressiv'
    Write-Host '    -B 0.45       Aggressiver'
    Write-Host '    -DryRun       Nur Vorschau'
    Write-Host ''
    Write-Host '  REFERENZTABELLE:' -ForegroundColor Yellow
    Write-Host '  -----------------------------------------'
    Write-Host ('  {0,-15} {1,-15} {2,-10}' -f 'ALTER PREIS', 'NEUER PREIS', 'REDUKTION')
    Write-Host '  -----------------------------------------'
    $examples = @(10, 100, 1000, 10000, 100000, 1000000, 10000000, 100000000)
    foreach ($ex in $examples) {
        $conv = Convert-Price -OldPrice $ex -A $A -B $B
        $red = [Math]::Round((1 - $conv / $ex) * 100, 1)
        Write-Host ('  {0,-15:N0} {1,-15:N0} {2,-10}' -f $ex, $conv, "$red %")
    }
    Write-Host '  -----------------------------------------'
    Write-Host ''
    exit 0
}

# ============================================================================
#  Pruefen ob Datei oder Ordner
# ============================================================================
if (-not (Test-Path $Path)) {
    Write-Host ''
    Write-Host "  FEHLER: Pfad nicht gefunden!" -ForegroundColor Red
    Write-Host "  $Path" -ForegroundColor Red
    Write-Host ''
    exit 1
}

$isFile = (Test-Path $Path -PathType Leaf)
$isFolder = (Test-Path $Path -PathType Container)

# ============================================================================
#  Einzelne Datei
# ============================================================================
if ($isFile) {
    $sourceDir = Split-Path $Path -Parent
    $outputDir = Join-Path $sourceDir 'NewMarket'
    $fileName  = Split-Path $Path -Leaf

    if (-not $DryRun) {
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
    }

    Write-Host ''
    Write-Host '  ============================================' -ForegroundColor Cyan
    Write-Host '   DayZ Market Price Converter' -ForegroundColor Cyan
    Write-Host '  ============================================' -ForegroundColor Cyan
    Write-Host "  Datei:   $fileName" -ForegroundColor White
    Write-Host "  Formel:  NeuerPreis = $A * AlterPreis ^ $B" -ForegroundColor White
    Write-Host "  Ausgabe: $outputDir" -ForegroundColor White
    if ($DryRun) { Write-Host '  *** DRY-RUN ***' -ForegroundColor Yellow }
    Write-Host '  ============================================' -ForegroundColor Cyan
    Write-Host ''

    $r = Convert-MarketFile -FilePath $Path -OutputDir $outputDir -A $A -B $B -DryRun $DryRun

    Write-Host ''
    if ($r.Changed -gt 0) {
        Write-Host "  Fertig! $($r.Changed) Items konvertiert." -ForegroundColor Green
    } else {
        Write-Host '  Keine Preise geaendert.' -ForegroundColor Yellow
    }
    if (-not $DryRun) {
        Write-Host "  Ergebnis: $outputDir\$fileName" -ForegroundColor Cyan
    }
    Write-Host ''
    exit 0
}

# ============================================================================
#  Ganzer Ordner
# ============================================================================
if ($isFolder) {
    $outputDir = Join-Path $Path 'NewMarket'
    $files = Get-ChildItem -Path $Path -Filter '*.json' -File | Where-Object { $_.DirectoryName -eq $Path }

    if ($files.Count -eq 0) {
        Write-Host ''
        Write-Host "  FEHLER: Keine .json Dateien gefunden in:" -ForegroundColor Red
        Write-Host "  $Path" -ForegroundColor Red
        Write-Host ''
        exit 1
    }

    if (-not $DryRun) {
        if (-not (Test-Path $outputDir)) {
            New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
        }
    }

    Write-Host ''
    Write-Host '  ============================================' -ForegroundColor Cyan
    Write-Host '   DayZ Market Price Converter' -ForegroundColor Cyan
    Write-Host '  ============================================' -ForegroundColor Cyan
    Write-Host "  Ordner:   $Path" -ForegroundColor White
    Write-Host "  Dateien:  $($files.Count)" -ForegroundColor White
    Write-Host "  Formel:   NeuerPreis = $A * AlterPreis ^ $B" -ForegroundColor White
    Write-Host "  Ausgabe:  $outputDir" -ForegroundColor White
    if ($DryRun) { Write-Host '  *** DRY-RUN ***' -ForegroundColor Yellow }
    Write-Host '  ============================================' -ForegroundColor Cyan
    Write-Host ''

    $totalChanged = 0
    $totalItems = 0
    $filesChanged = 0

    foreach ($f in $files) {
        $r = Convert-MarketFile -FilePath $f.FullName -OutputDir $outputDir -A $A -B $B -DryRun $DryRun
        $totalChanged += $r.Changed
        $totalItems += $r.Total
        if ($r.Changed -gt 0) { $filesChanged++ }
    }

    Write-Host ''
    Write-Host '  ============================================' -ForegroundColor Cyan
    Write-Host '   ZUSAMMENFASSUNG' -ForegroundColor Cyan
    Write-Host '  ============================================' -ForegroundColor Cyan
    Write-Host "  Dateien verarbeitet:  $($files.Count)"
    Write-Host "  Dateien geaendert:    $filesChanged" -ForegroundColor Green
    Write-Host "  Items gesamt:         $totalItems"
    Write-Host "  Items geaendert:      $totalChanged" -ForegroundColor Green
    if (-not $DryRun) {
        Write-Host ''
        Write-Host "  Ergebnis in: $outputDir" -ForegroundColor Cyan
    }
    Write-Host '  ============================================' -ForegroundColor Cyan
    Write-Host ''
    exit 0
}
