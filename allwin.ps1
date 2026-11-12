Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class EW {
 public delegate bool CB(IntPtr h, IntPtr l);
 [DllImport("user32.dll")] public static extern bool EnumWindows(CB cb, IntPtr l);
 [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
}
"@
$cb = {
  param($h, $l)
  $s = New-Object System.Text.StringBuilder 256
  [EW]::GetWindowText($h, $s, 256) | Out-Null
  $t = $s.ToString()
  if ($t.Length -gt 0 -and [EW]::IsWindowVisible($h)) { Write-Output ($h.ToString() + " | " + $t) }
  return $true
}
[EW]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
