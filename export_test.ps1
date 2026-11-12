param()
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -ReferencedAssemblies 'WindowsBase' @"
using System;
using System.Runtime.InteropServices;
public class C5 {
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
 public static void Click(System.Windows.Rect r) {
   SetCursorPos((int)(r.X + r.Width/2), (int)(r.Y + r.Height/2));
   System.Threading.Thread.Sleep(120);
   mouse_event(0x0002, 0, 0, 0, UIntPtr.Zero);
   mouse_event(0x0004, 0, 0, 0, UIntPtr.Zero);
 }
}
"@
[C5]::SetProcessDPIAware() | Out-Null
Add-Type -AssemblyName System.Windows.Forms
$AE = [System.Windows.Automation.AutomationElement]
$TS = [System.Windows.Automation.TreeScope]
$base = 'E:\user\docs\Trae-CN\temp_20261107_02\probe'
Get-Process SPDTool -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 800
$p = Start-Process -FilePath (Join-Path $base 'run\SPDTool.exe') -PassThru
$cond = New-Object System.Windows.Automation.PropertyCondition($AE::ProcessIdProperty, $p.Id)
$win = $null
for ($i = 0; $i -lt 120 -and $win -eq $null; $i++) {
  Start-Sleep -Milliseconds 250
  $wins = @($AE::RootElement.FindAll($TS::Children, $cond) | Where-Object { $_.Current.BoundingRectangle.Width -gt 900 -and $_.Current.Name -ne '' })
  if ($wins.Count -gt 0) { $win = $wins[0] }
}
if ($win -eq $null) { Write-Output 'no window'; exit 1 }
$h = [IntPtr]$win.Current.NativeWindowHandle
[C5]::ShowWindow($h, 9) | Out-Null
[C5]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Seconds 32
$panes = @($win.FindAll($TS::Descendants, [System.Windows.Automation.Condition]::TrueCondition) | Where-Object { $_.Current.ControlType.ProgrammaticName -eq 'ControlType.Pane' -and $_.Current.Name -ne '' -and $_.Current.BoundingRectangle.Y -lt ($win.Current.BoundingRectangle.Y + 150) -and $_.Current.BoundingRectangle.Width -lt 200 } | Sort-Object { $_.Current.BoundingRectangle.X })
Write-Output ("top panes=" + $panes.Count + " names=" + ($panes | ForEach-Object { $_.Current.Name }) -join ',')
$export = $panes[0]
[C5]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 300
[C5]::Click($export.Current.BoundingRectangle)
Start-Sleep -Milliseconds 1200
[System.Windows.Forms.SendKeys]::SendWait('{DOWN}{ENTER}')
Start-Sleep -Milliseconds 2000
$out = Join-Path $base 'out_report_ui.txt'
if (Test-Path $out) { Remove-Item $out -Force }
[System.Windows.Forms.SendKeys]::SendWait('E:\user\docs\Trae-CN\temp_20261107_02\probe\out_report_ui.txt')
Start-Sleep -Milliseconds 700
[System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
Start-Sleep -Milliseconds 2000
if (Test-Path $out) { Write-Output ('UI export ok size=' + (Get-Item $out).Length) } else { Write-Output 'UI export NOT created' }
