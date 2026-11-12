Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
$p = Get-Process "SPDTool" -ErrorAction Stop | Select-Object -First 1
$root = [System.Windows.Automation.AutomationElement]::RootElement
$cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, $p.Id)
$wins = $root.FindAll([System.Windows.Automation.TreeScope]::Children, $cond)
$lines = @()
foreach ($w in $wins) { $lines += ("WINDOW | " + $w.Current.Name + " | " + $w.Current.ClassName) }
$lines -join "`n" | Out-File 'E:\user\docs\Trae-CN\temp_20261107_02\probe\dlg.txt' -Encoding UTF8
$path = $args[0]
$filename = $args[1]
foreach ($w in $wins) {
  $edits = $w.FindAll([System.Windows.Automation.TreeScope]::Descendants, (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Edit)))
  if ($edits.Count -gt 0) {
    $e = $edits[0]
    try { $vp = $e.GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern); $vp.SetValue($path); Write-Output "path set" } catch { Write-Output ("set failed " + $_.Exception.Message) }
    Start-Sleep -Milliseconds 400
    $btns = $w.FindAll([System.Windows.Automation.TreeScope]::Descendants, (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)))
    foreach ($b in $btns) {
      if ($b.Current.Name -match '保存|Save') {
        $ip = $b.GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern); $ip.Invoke(); Write-Output ("saved via " + $b.Current.Name); break
      }
    }
    break
  }
}
foreach ($w in $wins) { $lines += ("after | " + $w.Current.Name) }
$lines -join "`n" | Out-File 'E:\user\docs\Trae-CN\temp_20261107_02\probe\dlg.txt' -Encoding UTF8
