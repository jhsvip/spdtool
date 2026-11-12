param([string]$Exe, [string]$Out, [string]$ArgList = "", [int]$X = 20, [int]$Y = 20, [int]$W = 1120, [int]$H = 780)
Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class PW2 {
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
 public static IntPtr Find(uint target) {
   IntPtr found = IntPtr.Zero;
   EnumWindows((h, l) => {
     uint pid; GetWindowThreadProcessId(h, out pid);
     if (pid == target && IsWindowVisible(h)) {
       var cn = new StringBuilder(256); GetClassName(h, cn, 256);
       if (cn.ToString().StartsWith("WindowsForms")) { found = h; return false; }
     }
     return true;
   }, IntPtr.Zero);
   return found;
 }
}
"@
[PW2]::SetProcessDPIAware() | Out-Null
$arr = @()
if ($ArgList -ne "") { $arr = $ArgList -split '\|' }
$p = Start-Process -FilePath $Exe -ArgumentList $arr -PassThru
$h = [IntPtr]::Zero
for ($i = 0; $i -lt 60 -and $h -eq [IntPtr]::Zero; $i++) {
  Start-Sleep -Milliseconds 250
  $h = [PW2]::Find([uint32]$p.Id)
}
if ($h -eq [IntPtr]::Zero) { Write-Output "no window"; exit 1 }
[PW2]::ShowWindow($h, 9) | Out-Null
[PW2]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 1200
if ($W -le 0 -or $H -le 0) {
  Add-Type -AssemblyName System.Windows.Forms
  $b = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
  $X = $b.X; $Y = $b.Y; $W = $b.Width; $H = $b.Height
}
$bmp = New-Object System.Drawing.Bitmap($W, $H)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($X, $Y, 0, 0, (New-Object System.Drawing.Size($W, $H)))
$g.Dispose()
$bmp.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output ("saved " + $Out + " pid=" + $p.Id)
