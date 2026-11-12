Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
$p = Get-Process "Thaiphoon" -ErrorAction Stop | Select-Object -First 1
$root = [System.Windows.Automation.AutomationElement]::RootElement
$cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, $p.Id)
$wins = $root.FindAll([System.Windows.Automation.TreeScope]::Children, $cond)
$lines = @()
function Walk($e, $depth) {
  $script:lines += (" " * $depth + $e.Current.ControlType.ProgrammaticName + " | " + $e.Current.Name)
  $c = $e.FindAll([System.Windows.Automation.TreeScope]::Children, [System.Windows.Automation.Condition]::TrueCondition)
  foreach ($x in $c) { Walk $x ($depth + 1) }
}
foreach ($w in $wins) { Walk $w 0 }
$lines -join "`n" | Out-File -FilePath 'E:\user\docs\Trae-CN\temp_20261107_02\probe\thp_tree.txt' -Encoding UTF8
Write-Output ($lines.Count)
