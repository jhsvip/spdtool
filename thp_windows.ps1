Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W3 {
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
}
"@
[W3]::SetProcessDPIAware() | Out-Null
$p = Get-Process "Thaiphoon" -ErrorAction Stop | Select-Object -First 1
$root = [System.Windows.Automation.AutomationElement]::RootElement
$cond = New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ProcessIdProperty, $p.Id)
$wins = $root.FindAll([System.Windows.Automation.TreeScope]::Children, $cond)
$lines = @()
foreach ($w in $wins) {
  $r = $w.Current.BoundingRectangle
  $lines += ("WINDOW {0} | {1}| {2},{3},{4},{5}" -f $w.Current.ControlType.ProgrammaticName, $w.Current.Name, [int]$r.X, [int]$r.Y, [int]$r.Width, [int]$r.Height)
  $btns = $w.FindAll([System.Windows.Automation.TreeScope]::Descendants, (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::Button)))
  foreach ($b in $btns) {
    $br = $b.Current.BoundingRectangle
    $lines += ("  BUTTON {0} | {1},{2},{3},{4}" -f $b.Current.Name, [int]$br.X, [int]$br.Y, [int]$br.Width, [int]$br.Height)
  }
}
$lines -join "`n" | Out-File -FilePath 'E:\user\docs\Trae-CN\temp_20261107_02\probe\thp_windows.txt' -Encoding UTF8
$lines -join "`n"
