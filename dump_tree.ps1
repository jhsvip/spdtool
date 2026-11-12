Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
$p = Get-Process SPDTool -ErrorAction Stop | Select-Object -First 1
$win = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
$all = $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
$lines = @()
foreach ($e in $all) {
  $r = $e.Current.BoundingRectangle
  $lines += ("{0} | {1} | {2},{3},{4},{5}" -f $e.Current.ControlType.ProgrammaticName, $e.Current.Name, [int]$r.X, [int]$r.Y, [int]$r.Width, [int]$r.Height)
}
$lines -join "`n" | Out-File -FilePath 'E:\user\docs\Trae-CN\temp_20261107_02\probe\tree2.txt' -Encoding UTF8
Write-Output ("count " + $all.Count)
