Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
$p = Get-Process SPDTool -ErrorAction Stop | Select-Object -First 1
$win = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
$all = $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, [System.Windows.Automation.Condition]::TrueCondition)
$sb = New-Object System.Text.StringBuilder
for ($i = 0; $i -lt $all.Count; $i++) {
  $e = $all[$i]
  $r = $e.Current.BoundingRectangle
  [void]$sb.AppendLine(($e.Current.ControlType.ProgrammaticName + ' | ' + $e.Current.Name + ' | ' + $r.X + ',' + $r.Y + ',' + $r.Width + ',' + $r.Height))
}
[IO.File]::WriteAllText('E:\user\docs\Trae-CN\temp_20261107_02\probe\tree.txt', $sb.ToString(), (New-Object System.Text.UTF8Encoding($false)))
Write-Output ("count=" + $all.Count)
