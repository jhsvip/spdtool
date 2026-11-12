Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class W {
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int ht, bool repaint);
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
}
"@
[W]::SetProcessDPIAware() | Out-Null
$exe = $args[0]
$dump = $args[1]
$out = $args[2]
$w = if ($args.Count -gt 3) { [int]$args[3] } else { 1200 }
$h = if ($args.Count -gt 4) { [int]$args[4] } else { 820 }
$p = Start-Process -FilePath $exe -ArgumentList @($dump) -PassThru
for ($i = 0; $i -lt 60 -and $p.MainWindowHandle -eq 0; $i++) { Start-Sleep -Milliseconds 250; $p.Refresh() }
[W]::ShowWindow($p.MainWindowHandle, 9) | Out-Null
[W]::MoveWindow($p.MainWindowHandle, 20, 20, $w, $h, $true) | Out-Null
[W]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 800
$r = New-Object W+RECT
[W]::GetWindowRect($p.MainWindowHandle, [ref]$r) | Out-Null
$bmp = New-Object System.Drawing.Bitmap(($r.R - $r.L), ($r.B - $r.T))
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($r.L, $r.T, 0, 0, $bmp.Size)
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Output ("saved " + $out + " pid=" + $p.Id + " rect=" + ($r.R - $r.L) + "x" + ($r.B - $r.T))
