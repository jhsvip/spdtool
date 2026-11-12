param([int]$Index = 1)
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
$p = Get-Process SPDTool -ErrorAction Stop | Select-Object -First 1
$win = [System.Windows.Automation.AutomationElement]::FromHandle($p.MainWindowHandle)
$cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)
$buttons = $win.FindAll([System.Windows.Automation.TreeScope]::Descendants, $cond)
$pat = $buttons[$Index].GetCurrentPattern([System.Windows.Automation.InvokePattern]::Pattern)
$pat.Invoke()
Write-Output ("invoked " + $Index + " = " + $buttons[$Index].Current.Name)
