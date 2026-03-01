$currentDir = "c:\Users\Administrator\Desktop\Market"
$backupDir  = "c:\Users\Administrator\Desktop\Market\BACKUP"

$priceFields = @("MaxPriceThreshold","MinPriceThreshold","SellPricePercent")

$allDiffs    = [System.Collections.ArrayList]::new()
$filesWithChanges = 0
$totalChanges     = 0
$filesCompared    = 0
$filesSkipped     = [System.Collections.ArrayList]::new()

$backupFiles = Get-ChildItem -Path $backupDir -File | Where-Object { $_.Extension -ieq ".json" } | Sort-Object Name -Unique

foreach ($bf in $backupFiles) {
    $fname = $bf.Name
    $currentFile = Get-ChildItem -Path $currentDir -File | Where-Object { $_.Name -ieq $fname } | Select-Object -First 1
    if (-not $currentFile) {
        [void]$filesSkipped.Add("$fname (no current version found)")
        continue
    }
    
    $filesCompared++
    $fileDiffs = [System.Collections.ArrayList]::new()
    
    try {
        $backupJson  = Get-Content -Raw -LiteralPath $bf.FullName  | ConvertFrom-Json
        $currentJson = Get-Content -Raw -LiteralPath $currentFile.FullName | ConvertFrom-Json
    } catch {
        [void]$filesSkipped.Add("$fname (JSON parse error)")
        continue
    }
    
    if ($null -eq $backupJson.Items -or $null -eq $currentJson.Items) {
        [void]$filesSkipped.Add("$fname (no Items array)")
        continue
    }
    
    # Build lookup by ClassName from current
    $currentLookup = @{}
    foreach ($item in $currentJson.Items) {
        $currentLookup[$item.ClassName] = $item
    }
    
    foreach ($bItem in $backupJson.Items) {
        $cn = $bItem.ClassName
        if ($currentLookup.ContainsKey($cn)) {
            $cItem = $currentLookup[$cn]
            foreach ($field in $priceFields) {
                $bVal = $bItem.$field
                $cVal = $cItem.$field
                if ($null -ne $bVal -and $null -ne $cVal -and $bVal -ne $cVal) {
                    $diff = [PSCustomObject]@{
                        File      = $fname
                        ClassName = $cn
                        Field     = $field
                        Backup    = $bVal
                        Current   = $cVal
                    }
                    [void]$fileDiffs.Add($diff)
                    [void]$allDiffs.Add($diff)
                    $totalChanges++
                }
            }
        }
    }
    
    if ($fileDiffs.Count -gt 0) {
        $filesWithChanges++
    }
}

Write-Output "=== COMPARISON COMPLETE ==="
Write-Output "Files compared: $filesCompared"
Write-Output "Files with changes: $filesWithChanges"
Write-Output "Total price field changes: $totalChanges"
Write-Output "Files skipped: $($filesSkipped.Count)"
if ($filesSkipped.Count -gt 0) {
    foreach ($s in $filesSkipped) { Write-Output "  SKIPPED: $s" }
}
Write-Output ""
Write-Output "=== ALL PRICE DIFFERENCES ==="
Write-Output ""

$grouped = $allDiffs | Sort-Object File, ClassName, Field | Group-Object File
foreach ($grp in $grouped) {
    Write-Output "--- $($grp.Name) ---"
    foreach ($d in $grp.Group) {
        $changeDir = ""
        if ($d.Backup -match '^\d+(\.\d+)?$' -and $d.Current -match '^\d+(\.\d+)?$') {
            $bNum = [double]$d.Backup
            $cNum = [double]$d.Current
            if ($cNum -gt $bNum) { $changeDir = " [INCREASED]" }
            elseif ($cNum -lt $bNum) { $changeDir = " [DECREASED]" }
        }
        Write-Output "  Item: $($d.ClassName) | $($d.Field): $($d.Backup) -> $($d.Current)$changeDir"
    }
    Write-Output ""
}

# Summary stats
$increases = 0
$decreases = 0
foreach ($d in $allDiffs) {
    $bStr = "$($d.Backup)"
    $cStr = "$($d.Current)"
    if ($bStr -match '^\-?\d+(\.\d+)?$' -and $cStr -match '^\-?\d+(\.\d+)?$') {
        $bNum = [double]$bStr
        $cNum = [double]$cStr
        if ($cNum -gt $bNum) { $increases++ }
        elseif ($cNum -lt $bNum) { $decreases++ }
    }
}
Write-Output "=== TREND SUMMARY ==="
Write-Output "Price increases: $increases"
Write-Output "Price decreases: $decreases"
Write-Output "Total changes: $totalChanges"
