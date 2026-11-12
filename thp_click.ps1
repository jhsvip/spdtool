Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
$p = Get-Process "Thaiphoon" -ErrorAction Stop | Select-Object -First 1
$root = [System.Windows.Automation.AutomationElement]::RootElement
$cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, $p.Id)
$wins = $root.FindAll([System.Windows.Automation.TreeScope]::Children, $cond)
$lines = @()
foreach ($w in $wins) {
  $lines += ("WINDOW | " + $w.Current.Name)
  $btns = $w.FindAll([System.Windows.Automation.TreeScope]::Descendants, (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)))
  foreach ($b in $btns) { $lines += ("  BUTTON | " + $b.Current.Name) }
}
$lines -join "`n" | Out-File -FilePath 'E:\user\docs\Trae-CN\temp_20261107_02\probe\thp_ui.txt' -Encoding UTF8
$target = $args[0]
foreach ($w in $wins) {
  $btns = $w.FindAll([System.Windows.Automation.TreeScope]::Descendants, (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)))
  foreach ($b in $btns) {
    if ($b.Current.Name -eq $target) {
      $pat = $b.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
      $pat.Invoke()
      Write-Output ("invoked " + $target)
      return
    }
  }
}
Write-Output ("not found " + $target)
