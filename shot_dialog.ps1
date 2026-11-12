param([string]$Exe, [string]$Out, [string]$Mode = "dialog", [string]$Key = "trcd", [int]$W = 660, [int]$H = 560, [string]$TitleLike = "")
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class PW {
 [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int ht, bool repaint);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
 [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
 public delegate bool EnumProc(IntPtr h, IntPtr l);
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
 public static IntPtr Find(uint target, string like) {
   IntPtr found = IntPtr.Zero;
   EnumWindows((h, l) => {
     uint pid; GetWindowThreadProcessId(h, out pid);
     if (pid == target && IsWindowVisible(h)) {
       var sb = new StringBuilder(256); GetWindowText(h, sb, 256);
       var cn = new StringBuilder(256); GetClassName(h, cn, 256);
       if (cn.ToString().StartsWith("WindowsForms") || cn.ToString().StartsWith("#32770")) {
         if (like == "" || sb.ToString().Contains(like)) { found = h; return false; }
       }
     }
     return true;
   }, IntPtr.Zero);
   return found;
 }
}
"@
[PW]::SetProcessDPIAware() | Out-Null
$dump = "E:\user\docs\Trae-CN\temp_20261107_02\probe\spd_raw.bin"
$p = Start-Process -FilePath $Exe -ArgumentList @($Mode, $dump, $Key) -PassThru
$h = [IntPtr]::Zero
for ($i = 0; $i -lt 60 -and $h -eq [IntPtr]::Zero; $i++) {
  Start-Sleep -Milliseconds 250
  $h = [PW]::Find([uint32]$p.Id, $TitleLike)
}
if ($h -eq [IntPtr]::Zero) { Write-Output "no window pid=$($p.Id) exited=$($p.HasExited)"; exit 1 }
[PW]::ShowWindow($h, 9) | Out-Null
if ($W -gt 0 -and $H -gt 0) { [PW]::MoveWindow($h, 40, 40, $W, $H, $true) | Out-Null }
[PW]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 1500
$r = New-Object PW+RECT
[PW]::GetWindowRect($h, [ref]$r) | Out-Null
$bw = $r.R - $r.L; $bh = $r.B - $r.T
$bmp = New-Object System.Drawing.Bitmap($bw, $bh)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$hdc = $g.GetHdc()
[PW]::PrintWindow($h, $hdc, 2) | Out-Null
$g.ReleaseHdc($hdc); $g.Dispose()
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
$sb = New-Object System.Text.StringBuilder 256
[PW]::GetWindowText($h, $sb, 256) | Out-Null
Write-Output ("saved " + $Out + " pid=" + $p.Id + " size=" + $bw + "x" + $bh + " title=" + $sb)
