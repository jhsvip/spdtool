Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;
public class E {
 public delegate bool CB(IntPtr h, IntPtr l);
 [DllImport("user32.dll")] public static extern bool EnumWindows(CB cb, IntPtr l);
 [DllImport("user32.dll")] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
 [DllImport("user32.dll")] public static extern int GetWindowThreadProcessId(IntPtr h, out int p);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
}
"@
$target = [int]$args[0]
$cb = {
  param($h, $l)
  $sb = New-Object System.Text.StringBuilder 256
  [E]::GetWindowText($h, $sb, 256) | Out-Null
  $procId = 0
  [E]::GetWindowThreadProcessId($h, [ref]$procId) | Out-Null
  if ($procId -eq $target) {
    Write-Output ($h.ToString() + " vis=" + [E]::IsWindowVisible($h) + " title=" + $sb.ToString())
  }
  return $true
}
[E]::EnumWindows($cb, [IntPtr]::Zero) | Out-Null
