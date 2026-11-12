Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class DL {
 public delegate bool CB(IntPtr h, IntPtr l);
 [DllImport("user32.dll")] public static extern bool EnumWindows(CB cb, IntPtr l);
 [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
 [DllImport("user32.dll")] public static extern int GetWindowThreadProcessId(IntPtr h, out int p);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
 [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr h, IntPtr after, int x, int y, int w, int ht, uint flags);
 [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, int e);
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
}
"@
[DL]::SetProcessDPIAware() | Out-Null
$pidTarget = [int]$args[0]
$x = [int]$args[1]
$y = [int]$args[2]
$out = $args[3]
$p = Get-Process -Id $pidTarget
$h = $p.MainWindowHandle
[DL]::SetWindowPos($h, [IntPtr](-1), 0, 0, 0, 0, 0x0001 -bor 0x0002) | Out-Null
[DL]::BringWindowToTop($h) | Out-Null
[DL]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 400
$r = New-Object DL+RECT
[DL]::GetWindowRect($h, [ref]$r) | Out-Null
Write-Output ("main rect=" + $r.L + "," + $r.T + " " + ($r.R - $r.L) + "x" + ($r.B - $r.T))
[DL]::SetCursorPos($r.L + $x, $r.T + $y) | Out-Null
Start-Sleep -Milliseconds 200
[DL]::mouse_event(0x0002, 0, 0, 0, 0); [DL]::mouse_event(0x0004, 0, 0, 0, 0)
Start-Sleep -Milliseconds 150
[DL]::mouse_event(0x0002, 0, 0, 0, 0); [DL]::mouse_event(0x0004, 0, 0, 0, 0)
Start-Sleep -Milliseconds 1200

# 找该进程的“编辑字段”窗口
$sb = New-Object System.Text.StringBuilder
$found = [IntPtr]::Zero
$cb = {
  param($w, $l)
  $s = New-Object System.Text.StringBuilder 256
  [DL]::GetWindowText($w, $s, 256) | Out-Null
  $procId = 0
  [DL]::GetWindowThreadProcessId($w, [ref]$procId) | Out-Null
  if ($procId -eq $pidTarget -and [DL]::IsWindowVisible($w)) {
    $title = $s.ToString()
    Write-Output ("visible: " + $title)
    if ($title -like "*编辑字段*") { $script:found = $w }
  }
  return $true
}
[DL]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
if ($script:found -eq [IntPtr]::Zero) { Write-Output "no dialog"; exit 1 }
[DL]::SetForegroundWindow($script:found) | Out-Null
Start-Sleep -Milliseconds 300
$dr = New-Object DL+RECT
[DL]::GetWindowRect($script:found, [ref]$dr) | Out-Null
$bmp = New-Object System.Drawing.Bitmap(($dr.R - $dr.L), ($dr.B - $dr.T))
$g = [System.Drawing.Graphics]::FromImage($bmp)
$hdc = $g.GetHdc()
[DL]::PrintWindow($script:found, $hdc, 2) | Out-Null
$g.ReleaseHdc($hdc); $g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output ("saved " + $out + " size=" + ($dr.R - $dr.L) + "x" + ($dr.B - $dr.T))
