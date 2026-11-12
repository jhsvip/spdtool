param()
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -ReferencedAssemblies 'System.Drawing','System.Windows.Forms' @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class T2 {
 [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
 public delegate bool EnumProc(IntPtr h, IntPtr l);
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
 public const uint DOWN = 0x0002, UP = 0x0004;
 public static IntPtr FindByPid(uint target, IntPtr exclude, int minW, int maxW) {
   IntPtr found = IntPtr.Zero;
   EnumWindows((h, l) => {
     uint pid; GetWindowThreadProcessId(h, out pid);
     if (pid == target && h != exclude && IsWindowVisible(h)) {
       RECT r; GetWindowRect(h, out r);
       int w = r.R - r.L;
       if (w >= minW && w <= maxW) { found = h; return false; }
     }
     return true;
   }, IntPtr.Zero);
   return found;
 }
 public static IntPtr FindMain(uint target) {
   IntPtr found = IntPtr.Zero;
   EnumWindows((h, l) => {
     uint pid; GetWindowThreadProcessId(h, out pid);
     if (pid == target && IsWindowVisible(h)) {
       var sb = new StringBuilder(256); GetWindowText(h, sb, 256);
       if (sb.ToString().Length > 0) { found = h; return false; }
     }
     return true;
   }, IntPtr.Zero);
   return found;
 }
 public static void Click(int x, int y, int n) {
   SetCursorPos(x, y); System.Threading.Thread.Sleep(120);
   for (int i = 0; i < n; i++) {
     mouse_event(DOWN, 0, 0, 0, UIntPtr.Zero);
     mouse_event(UP, 0, 0, 0, UIntPtr.Zero);
     System.Threading.Thread.Sleep(80);
   }
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
[T2]::SetProcessDPIAware() | Out-Null
$base = 'E:\user\docs\Trae-CN\temp_20261107_02\probe'
$exe = Join-Path $base 'run\SPDTool.exe'
Get-Process SPDTool -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 800
$p = Start-Process -FilePath $exe -PassThru
$h = [IntPtr]::Zero
for ($i = 0; $i -lt 120 -and $h -eq [IntPtr]::Zero; $i++) { Start-Sleep -Milliseconds 250; $h = [T2]::FindMain([uint32]$p.Id) }
if ($h -eq [IntPtr]::Zero) { Write-Output 'no main window'; exit 1 }
[T2]::ShowWindow($h, 9) | Out-Null; [T2]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Seconds 32
[T2]::Capture($h, (Join-Path $base 'shot_120_main.png'))
$r = New-Object T2+RECT; [T2]::GetWindowRect($h, [ref]$r) | Out-Null
Write-Output ("main " + $r.L + ',' + $r.T + ' ' + ($r.R-$r.L) + 'x' + ($r.B-$r.T))
[T2]::Click(($r.L + 1224), ($r.T + 80), 1)
Start-Sleep -Milliseconds 1000
[System.Windows.Forms.SendKeys]::SendWait('{DOWN}{DOWN}{DOWN}{DOWN}{DOWN}{DOWN}{ENTER}')
Start-Sleep -Milliseconds 2200
$w = [T2]::FindByPid([uint32]$p.Id, $h, 780, 900)
if ($w -eq [IntPtr]::Zero) { Write-Output 'wizard not found' } else {
  [T2]::Capture($w, (Join-Path $base 'shot_120_wizard1.png'))
  $wr = New-Object T2+RECT; [T2]::GetWindowRect($w, [ref]$wr) | Out-Null
  Write-Output ("wizard " + $wr.L + ',' + $wr.T + ' ' + ($wr.R-$wr.L) + 'x' + ($wr.B-$wr.T))
  [T2]::SetForegroundWindow($w) | Out-Null
  [T2]::Click(($wr.L + 760), ($wr.T + 662), 1)
  Start-Sleep -Milliseconds 1800
  [T2]::Capture($w, (Join-Path $base 'shot_120_wizard2.png'))
  [System.Windows.Forms.SendKeys]::SendWait('{ESC}')
  Start-Sleep -Milliseconds 900
}
[T2]::SetForegroundWindow($h) | Out-Null; Start-Sleep -Milliseconds 400
[T2]::Click(($r.L + 1106), ($r.T + 80), 1)
Start-Sleep -Milliseconds 1000
[System.Windows.Forms.SendKeys]::SendWait('{DOWN}{ENTER}')
Start-Sleep -Milliseconds 1600
$out = Join-Path $base 'out_report.txt'
if (Test-Path $out) { Remove-Item $out -Force }
[System.Windows.Forms.SendKeys]::SendWait('E:\user\docs\Trae-CN\temp_20261107_02\probe\out_report.txt')
Start-Sleep -Milliseconds 700
[System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
Start-Sleep -Milliseconds 1800
if (Test-Path $out) { Write-Output ('report ok size=' + (Get-Item $out).Length); Get-Content $out -TotalCount 1 } else { Write-Output 'report NOT created' }
