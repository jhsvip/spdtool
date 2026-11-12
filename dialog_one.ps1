Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName UIAutomationClient
Add-Type -AssemblyName UIAutomationTypes
Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class O {
 public delegate bool CB(IntPtr h, IntPtr l);
 [DllImport("user32.dll")] public static extern bool EnumWindows(CB cb, IntPtr l);
 [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int ht, bool repaint);
 [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint x, uint y, uint d, int e);
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
}
"@
[O]::SetProcessDPIAware() | Out-Null
$exe = $args[0]
$dump = $args[1]
$out = $args[2]
$p = Start-Process -FilePath $exe -ArgumentList @($dump) -PassThru
for ($i = 0; $i -lt 80 -and $p.MainWindowHandle -eq 0; $i++) { Start-Sleep -Milliseconds 250; $p.Refresh() }
$h = $p.MainWindowHandle
if ($h -eq 0) { Write-Output "no main window"; exit 1 }
[O]::ShowWindow($h, 9) | Out-Null
[O]::MoveWindow($h, 100, 60, 1280, 820, $true) | Out-Null
[O]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 1200

# 点击“时序”标签（窗口相对坐标 144,183）
[O]::SetCursorPos(100 + 144, 60 + 183) | Out-Null
Start-Sleep -Milliseconds 200
[O]::mouse_event(0x0002, 0, 0, 0, 0); [O]::mouse_event(0x0004, 0, 0, 0, 0)
Start-Sleep -Milliseconds 900

# 双击 tRCD 行
[O]::SetCursorPos(100 + 500, 60 + 364) | Out-Null
Start-Sleep -Milliseconds 200
[O]::mouse_event(0x0002, 0, 0, 0, 0); [O]::mouse_event(0x0004, 0, 0, 0, 0)
Start-Sleep -Milliseconds 150
[O]::mouse_event(0x0002, 0, 0, 0, 0); [O]::mouse_event(0x0004, 0, 0, 0, 0)
Start-Sleep -Milliseconds 1500

$found = [IntPtr]::Zero
$cb = {
  param($w, $l)
  $s = New-Object System.Text.StringBuilder 256
  [O]::GetWindowText($w, $s, 256) | Out-Null
  $t = $s.ToString()
  if ($t -like "*编辑字段*" -and [O]::IsWindowVisible($w)) { $script:found = $w; Write-Output ("dialog: " + $t) }
  return $true
}
[O]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
if ($found -eq [IntPtr]::Zero) { Write-Output "no dialog"; $found = $h }
$r = New-Object O+RECT
[O]::GetWindowRect($found, [ref]$r) | Out-Null
$bmp = New-Object System.Drawing.Bitmap(($r.R - $r.L), ($r.B - $r.T))
$g = [System.Drawing.Graphics]::FromImage($bmp)
$hdc = $g.GetHdc()
[O]::PrintWindow($found, $hdc, 2) | Out-Null
$g.ReleaseHdc($hdc); $g.Dispose()
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output ("saved " + $out + " size=" + ($r.R - $r.L) + "x" + ($r.B - $r.T) + " pid=" + $p.Id)
