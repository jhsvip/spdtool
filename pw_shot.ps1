Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class PW {
 [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int ht, bool repaint);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
}
"@
[PW]::SetProcessDPIAware() | Out-Null
$exe = $args[0]
$out = $args[1]
$w = if ($args.Count -gt 2) { [int]$args[2] } else { 1280 }
$h = if ($args.Count -gt 3) { [int]$args[3] } else { 840 }
$dump = if ($args.Count -gt 4) { $args[4] } else { $null }
$argList = @()
if ($dump) { $argList = @($dump) }
$p = Start-Process -FilePath $exe -ArgumentList $argList -PassThru
for ($i = 0; $i -lt 80 -and $p.MainWindowHandle -eq 0; $i++) { Start-Sleep -Milliseconds 250; $p.Refresh() }
if ($p.MainWindowHandle -eq 0) { Write-Output "no window pid=$($p.Id) exited=$($p.HasExited)"; exit 1 }
[PW]::ShowWindow($p.MainWindowHandle, 9) | Out-Null
[PW]::MoveWindow($p.MainWindowHandle, 40, 40, $w, $h, $true) | Out-Null
[PW]::SetForegroundWindow($p.MainWindowHandle) | Out-Null
Start-Sleep -Milliseconds 1200
$r = New-Object PW+RECT
[PW]::GetWindowRect($p.MainWindowHandle, [ref]$r) | Out-Null
$bw = $r.R - $r.L; $bh = $r.B - $r.T
$bmp = New-Object System.Drawing.Bitmap($bw, $bh)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$hdc = $g.GetHdc()
[PW]::PrintWindow($p.MainWindowHandle, $hdc, 2) | Out-Null
$g.ReleaseHdc($hdc)
$g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output ("saved " + $out + " pid=" + $p.Id + " size=" + $bw + "x" + $bh)
