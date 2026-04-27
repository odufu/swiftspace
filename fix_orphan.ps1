$f = 'lib\features\property\presentation\pages\property_details_screen.dart'
$lines = Get-Content $f
$newLines = $lines[0..1517] + $lines[2451..($lines.Length-1)]
Set-Content $f $newLines -Encoding UTF8
Write-Host "Done: was $($lines.Length), now $($newLines.Length)"
