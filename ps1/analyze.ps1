$data = @()
$lines = Get-Content "c:\Users\Administrator\Desktop\Market\price_comparison_results.txt"
foreach ($line in $lines) {
    if ($line -match '\| (MaxPriceThreshold|MinPriceThreshold): (\d+) -> (\d+)') {
        $old = [double]$Matches[2]
        $new = [double]$Matches[3]
        if ($old -gt 0 -and $new -gt 0) {
            $data += [PSCustomObject]@{Old=$old; New=$new}
        }
    }
}

$unique = $data | Sort-Object Old | Select-Object Old, New -Unique

$output = @()
$output += "Old`tNew`tln_Old`tln_New`tsqrt_Old`tNew/sqrt(Old)"
foreach ($p in $unique) {
    $logOld = [Math]::Log($p.Old)
    $logNew = [Math]::Log($p.New)
    $sqrtOld = [Math]::Sqrt($p.Old)
    $ratio = $p.New / $sqrtOld
    $output += ("{0}`t{1}`t{2:F4}`t{3:F4}`t{4:F2}`t{5:F4}" -f $p.Old, $p.New, $logOld, $logNew, $sqrtOld, $ratio)
}
$output | Out-File "c:\Users\Administrator\Desktop\Market\formula_data.txt" -Encoding UTF8

Write-Host "Total unique pairs: $($unique.Count)"
Write-Host "First 20 pairs:"
$unique | Select-Object -First 20 | ForEach-Object { Write-Host "$($_.Old) -> $($_.New)" }
Write-Host ""
Write-Host "Last 20 pairs:"
$unique | Select-Object -Last 20 | ForEach-Object { Write-Host "$($_.Old) -> $($_.New)" }
