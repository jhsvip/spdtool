param()
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
Add-Type -ReferencedAssemblies 'System.Drawing','System.Windows.Forms' @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class T {
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
 public static IntPtr FindOther(uint target, IntPtr main) {
   IntPtr found = IntPtr.Zero;
   EnumWindows((h, l) => {
     uint pid; GetWindowThreadProcessId(h, out pid);
     if (pid == target && h != main && IsWindowVisible(h)) {
       RECT r; GetWindowRect(h, out r);
       int w = r.R - r.L, ht = r.B - r.T;
       if (w > 400 && w < 1000) { found = h; return false; }
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
   int w = r.R - r.L, ht = r.B - r.T;
   var bmp = new System.Drawing.Bitmap(w, ht);
   using (var g = System.Drawing.Graphics.FromImage(bmp)) {
     IntPtr hdc = g.GetHdc();
     PrintWindow(h, hdc, 2);
     g.ReleaseHdc(hdc);
   }
   bmp.Save(path, System.Drawing.Imaging.ImageFormat.Png);
   bmp.Dispose();
 }
}
"@
[T]::SetProcessDPIAware() | Out-Null
$base = 'E:\user\docs\Trae-CN\temp_20261107_02\probe'
$exe = Join-Path $base 'run\SPDTool.exe'
Get-Process SPDTool -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Milliseconds 800
$p = Start-Process -FilePath $exe -PassThru
$h = [IntPtr]::Zero
for ($i = 0; $i -lt 80 -and $h -eq [IntPtr]::Zero; $i++) { Start-Sleep -Milliseconds 250; $h = [T]::FindMain([uint32]$p.Id) }
if ($h -eq [IntPtr]::Zero) { Write-Output 'no main window'; exit 1 }
[T]::ShowWindow($h, 9) | Out-Null
[T]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Seconds 32
[T]::Capture($h, (Join-Path $base 'shot_v10_main.png'))
$r = New-Object T+RECT
[T]::GetWindowRect($h, [ref]$r) | Out-Null
Write-Output ("main rect=" + $r.L + ',' + $r.T + ' ' + ($r.R - $r.L) + 'x' + ($r.B - $r.T))
[T]::Click(($r.L + 170), ($r.T + 247), 2)
Start-Sleep -Milliseconds 2500
$d = [T]::FindOther([uint32]$p.Id, $h)
if ($d -ne [IntPtr]::Zero) {
  $sb = New-Object System.Text.StringBuilder 256
  [T]::GetWindowText($d, $sb, 256) | Out-Null
  [T]::Capture($d, (Join-Path $base 'shot_v10_editor.png'))
  Write-Output ('dialog title=' + $sb.ToString())
  [T]::SetForegroundWindow($d) | Out-Null
  [System.Windows.Forms.SendKeys]::SendWait('{ESC}')
  Start-Sleep -Milliseconds 900
} else { Write-Output 'dialog not found' }
[T]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 400
[T]::Click(($r.L + 1026), ($r.T + 96), 1)
Start-Sleep -Milliseconds 1200
[System.Windows.Forms.SendKeys]::SendWait('{DOWN}{ENTER}')
Start-Sleep -Milliseconds 1600
$out = Join-Path $base 'out_report.txt'
if (Test-Path $out) { Remove-Item $out -Force }
[System.Windows.Forms.SendKeys]::SendWait('E:\user\docs\Trae-CN\temp_20261107_02\probe\out_report.txt')
Start-Sleep -Milliseconds 600
[System.Windows.Forms.SendKeys]::SendWait('{ENTER}')
Start-Sleep -Milliseconds 1600
if (Test-Path $out) { Write-Output ('report ok size=' + (Get-Item $out).Length); Get-Content $out -TotalCount 2 } else { Write-Output 'report file NOT created' }
