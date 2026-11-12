param()
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type -ReferencedAssemblies 'System.Drawing','WindowsBase' @"
using System;
using System.Runtime.InteropServices;
public class P4 {
 [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int c);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
 public static void ClickRect(System.Windows.Rect r) {
   SetCursorPos((int)(r.X + r.Width/2), (int)(r.Y + r.Height/2));
   System.Threading.Thread.Sleep(100);
   mouse_event(0x0002, 0, 0, 0, UIntPtr.Zero);
   mouse_event(0x0004, 0, 0, 0, UIntPtr.Zero);
 }
 public static void Capture(IntPtr h, string path) {
   RECT r; GetWindowRect(h, out r);
   var bmp = new System.Drawing.Bitmap(r.R - r.L, r.B - r.T);
   using (var g = System.Drawing.Graphics.FromImage(bmp)) {
     IntPtr hdc = g.GetHdc(); PrintWindow(h, hdc, 2); g.ReleaseHdc(hdc);
   }
   bmp.Save(path, System.Drawing.Imaging.ImageFormat.Png); bmp.Dispose();
 }
}
"@
[P4]::SetProcessDPIAware() | Out-Null
$AE = [System.Windows.Automation.AutomationElement]
$TS = [System.Windows.Automation.TreeScope]
$CT = [System.Windows.Automation.ControlType]
$base = 'E:\user\docs\Trae-CN\temp_20261107_02\probe'
Get-Process SPDTool -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 800
$p = Start-Process -FilePath (Join-Path $base 'run\SPDTool.exe') -PassThru
$pid2 = $p.Id
function PidCond { New-Object System.Windows.Automation.PropertyCondition($AE::ProcessIdProperty, $pid2) }
function TypeCond($t) { New-Object System.Windows.Automation.PropertyCondition($AE::ControlTypeProperty, $t) }
function And($a, $b) { New-Object System.Windows.Automation.AndCondition($a, $b) }
function Desc($parent, $cond) { $parent.FindAll($TS::Descendants, $cond) }
function TopWins { @($AE::RootElement.FindAll($TS::Children, (And (PidCond) (TypeCond $CT::Window))) | Where-Object { $_.Current.IsOffscreen -eq $false }) }
function MainWin {
  for ($k = 0; $k -lt 120; $k++) {
    Start-Sleep -Milliseconds 250
    foreach ($w in (TopWins)) { if ($w.Current.Name -ne '' -and $w.Current.BoundingRectangle.Width -gt 900) { return $w } }
  }
  return $null
}
$main = MainWin
if ($main -eq $null) { Write-Output 'no main window'; exit 1 }
$mr = $main.Current.BoundingRectangle
Write-Output ("main=" + $main.Current.Name + " " + $mr)
[P4]::ShowWindow([IntPtr]$main.Current.NativeWindowHandle, 9) | Out-Null
[P4]::SetForegroundWindow([IntPtr]$main.Current.NativeWindowHandle) | Out-Null
Start-Sleep -Seconds 32
[P4]::Capture([IntPtr]$main.Current.NativeWindowHandle, (Join-Path $base 'shot_120_main.png'))

$panes = @(Desc $main ([System.Windows.Automation.Condition]::TrueCondition) | Where-Object { $_.Current.ControlType.ProgrammaticName -eq 'ControlType.Pane' -and $_.Current.Name -ne '' -and $_.Current.BoundingRectangle.Y -lt ($mr.Y + 150) -and $_.Current.BoundingRectangle.Width -lt 200 } | Sort-Object { $_.Current.BoundingRectangle.X })
Write-Output ("top panes=" + $panes.Count)
$more = $panes[$panes.Count - 1]
[P4]::ClickRect($more.Current.BoundingRectangle)
Start-Sleep -Milliseconds 1200
$pop = $null
foreach ($w in (TopWins)) { if ($w.Current.BoundingRectangle.Width -lt 420 -and $w.Current.BoundingRectangle.Height -gt 180) { $pop = $w } }
if ($pop -eq $null) { Write-Output 'menu popup not found' } else {
  $items = @(Desc $pop ([System.Windows.Automation.Condition]::TrueCondition) | Where-Object { $_.Current.Name -ne '' -and $_.Current.BoundingRectangle.Height -gt 10 -and $_.Current.BoundingRectangle.Height -lt 40 } | Sort-Object { $_.Current.BoundingRectangle.Y })
  Write-Output ("menu items=" + $items.Count)
  if ($items.Count -ge 6) { [P4]::ClickRect($items[5].Current.BoundingRectangle) }
}
Start-Sleep -Milliseconds 2200
$wiz = $null
foreach ($w in (TopWins)) { if ($w.Current.BoundingRectangle.Width -ge 780 -and $w.Current.BoundingRectangle.Width -le 900) { $wiz = $w } }
if ($wiz -eq $null) { Write-Output 'wizard not found' } else {
  Write-Output ("wizard=" + $wiz.Current.Name + " " + $wiz.Current.BoundingRectangle)
  [P4]::Capture([IntPtr]$wiz.Current.NativeWindowHandle, (Join-Path $base 'shot_120_wizard1.png'))
  $wr = $wiz.Current.BoundingRectangle
  $wb = @(Desc $wiz ([System.Windows.Automation.Condition]::TrueCondition) | Where-Object { $_.Current.ControlType.ProgrammaticName -eq 'ControlType.Pane' -and $_.Current.Name -ne '' -and $_.Current.BoundingRectangle.Y -gt ($wr.Y + 550) -and $_.Current.BoundingRectangle.Height -lt 60 } | Sort-Object { $_.Current.BoundingRectangle.X })
  Write-Output ("wizard buttons=" + $wb.Count)
  $nextBtn = $wb[$wb.Count - 1]
  [P4]::ClickRect($nextBtn.Current.BoundingRectangle)
  Start-Sleep -Milliseconds 1800
  [P4]::Capture([IntPtr]$wiz.Current.NativeWindowHandle, (Join-Path $base 'shot_120_wizard2.png'))
  $cancel = $wb[0]
  [P4]::ClickRect($cancel.Current.BoundingRectangle)
  Start-Sleep -Milliseconds 900
}
$export = $panes[0]
[P4]::ClickRect($export.Current.BoundingRectangle)
Start-Sleep -Milliseconds 1200
$pop2 = $null
foreach ($w in (TopWins)) { if ($w.Current.BoundingRectangle.Width -lt 420 -and $w.Current.BoundingRectangle.Height -gt 100 -and $w.Current.BoundingRectangle.Height -lt 260) { $pop2 = $w } }
if ($pop2 -eq $null) { Write-Output 'export popup not found' } else {
  $items2 = @(Desc $pop2 ([System.Windows.Automation.Condition]::TrueCondition) | Where-Object { $_.Current.Name -ne '' -and $_.Current.BoundingRectangle.Height -gt 10 -and $_.Current.BoundingRectangle.Height -lt 40 } | Sort-Object { $_.Current.BoundingRectangle.Y })
  Write-Output ("export items=" + $items2.Count)
  if ($items2.Count -ge 1) { [P4]::ClickRect($items2[0].Current.BoundingRectangle) }
}
Start-Sleep -Milliseconds 1800
$out = Join-Path $base 'out_report.txt'
if (Test-Path $out) { Remove-Item $out -Force }
$dlg = $null
foreach ($w in (TopWins)) { if ($w.Current.BoundingRectangle.Width -ge 300 -and $w.Current.BoundingRectangle.Width -lt 1000) { $dlg = $w } }
if ($dlg -eq $null) { Write-Output 'save dialog not found' } else {
  $edits = @(Desc $dlg (TypeCond $CT::Edit))
  Write-Output ("dialog edits=" + $edits.Count)
  if ($edits.Count -ge 1) { $edits[0].GetCurrentPattern([System.Windows.Automation.ValuePattern]::Pattern).SetValue('E:\user\docs\Trae-CN\temp_20261107_02\probe\out_report.txt') }
  Start-Sleep -Milliseconds 500
  $db = @(Desc $dlg (TypeCond $CT::Button) | Sort-Object { $_.Current.BoundingRectangle.X })
  if ($db.Count -ge 2) { [P4]::ClickRect($db[0].Current.BoundingRectangle) }
}
Start-Sleep -Milliseconds 1800
if (Test-Path $out) { Write-Output ('report ok size=' + (Get-Item $out).Length); Get-Content $out -TotalCount 1 } else { Write-Output 'report NOT created' }
