Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
$p = Get-Process SPDTool -ErrorAction Stop | Select-Object -First 1
$win = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
$cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)
$buttons = $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
$names = @()
for ($i = 0; $i -lt $buttons.Count; $i++) { $names += ($i.ToString() + '=' + $buttons[$i].Current.Name) }
$names -join "`n" | Out-File -FilePath 'E:\user\docs\Trae-CN\temp_20261107_02\probe\buttons.txt' -Encoding UTF8
$target = $args[0]
for ($i = 0; $i -lt $buttons.Count; $i++) {
  if ($buttons[$i].Current.Name -eq $target) {
    $pat = $buttons[$i].GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
    $pat.Invoke()
    Write-Output ("invoked " + $target)
    break
  }
}
