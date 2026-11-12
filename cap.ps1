Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class CP {
 [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
}
"@
[CP]::SetProcessDPIAware() | Out-Null
$pidTarget = [int]$args[0]
$out = $args[1]
$p = Get-Process -Id $pidTarget
$h = $p.MainWindowHandle
if ($h -eq 0) { Write-Output "no main window"; exit 1 }
$r = New-Object CP+RECT
[CP]::GetWindowRect($h, [ref]$r) | Out-Null
$bmp = New-Object System.Drawing.Bitmap(($r.R - $r.L), ($r.B - $r.T))
$g = [System.Drawing.Graphics]::FromImage($bmp)
$hdc = $g.GetHdc()
[CP]::PrintWindow($h, $hdc, 2) | Out-Null
$g.ReleaseHdc($hdc); $g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output ("saved " + $out + " size=" + ($r.R - $r.L) + "x" + ($r.B - $r.T) + " title=" + $p.MainWindowTitle)
