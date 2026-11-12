Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class UT {
 [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
}
"@
[UT]::SetProcessDPIAware() | Out-Null
$pidTarget = [int]$args[0]
$tabName = $args[1]
$out = $args[2]
$p = Get-Process -Id $pidTarget
$h = $p.MainWindowHandle
[UT]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 400
$root = [System.Windows.Automation.AutomationElement]::FromHandle($h)
$cond = New-Object System.Windows.Automation.AndCondition(
    (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::NameProperty, $tabName)),
    (New-Object System.Windows.Automation.PropertyCondition([System.Windows.Automation.AutomationElement]::ControlTypeProperty, [System.Windows.Automation.ControlType]::TabItem)))
$item = $root.FindFirst([System.Windows.Automation.TreeScope]::Descendants, $cond)
if ($item -eq $null) { Write-Output "tab not found: $tabName"; exit 1 }
$pat = $item.GetCurrentPattern([System.Windows.Automation.SelectionItemPattern]::Pattern)
$pat.Select()
Start-Sleep -Milliseconds 900
$r = New-Object UT+RECT
[UT]::GetWindowRect($h, [ref]$r) | Out-Null
$bmp = New-Object System.Drawing.Bitmap(($r.R - $r.L), ($r.B - $r.T))
$g = [System.Drawing.Graphics]::FromImage($bmp)
$hdc = $g.GetHdc()
[UT]::PrintWindow($h, $hdc, 2) | Out-Null
$g.ReleaseHdc($hdc); $g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output ("selected $tabName saved $out")
