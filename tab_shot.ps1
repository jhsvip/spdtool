Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class TS {
 [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr h, ref POINT p);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, int e);
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
 [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }
}
"@
[TS]::SetProcessDPIAware() | Out-Null
$pidTarget = [int]$args[0]
$fx = [double]$args[1]
$fy = [double]$args[2]
$out = $args[3]
$p = Get-Process -Id $pidTarget
$h = $p.MainWindowHandle
[TS]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 300
$cr = New-Object TS+RECT
[TS]::GetClientRect($h, [ref]$cr) | Out-Null
$pt = New-Object TS+POINT
$pt.X = [int]($cr.R * $fx); $pt.Y = [int]($cr.B * $fy)
[TS]::ClientToScreen($h, [ref]$pt) | Out-Null
[TS]::SetCursorPos($pt.X, $pt.Y) | Out-Null
Start-Sleep -Milliseconds 150
[TS]::mouse_event(0x0002, 0, 0, 0, 0)
[TS]::mouse_event(0x0004, 0, 0, 0, 0)
Start-Sleep -Milliseconds 900
$r = New-Object TS+RECT
[TS]::GetWindowRect($h, [ref]$r) | Out-Null
$bmp = New-Object System.Drawing.Bitmap(($r.R - $r.L), ($r.B - $r.T))
$g = [System.Drawing.Graphics]::FromImage($bmp)
$hdc = $g.GetHdc()
[TS]::PrintWindow($h, $hdc, 2) | Out-Null
$g.ReleaseHdc($hdc); $g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output ("clicked client $($pt.X),$($pt.Y) saved $out")
