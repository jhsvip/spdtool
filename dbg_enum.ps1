Add-Type @"
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public class WEnum {
 public delegate bool EnumProc(IntPtr h, IntPtr l);
 [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
 [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
 public static List<string> List(uint target) {
   var res = new List<string>();
   EnumWindows((h, l) => {
     uint pid; GetWindowThreadProcessId(h, out pid);
     if (pid == target) {
       var sb = new StringBuilder(256); GetWindowText(h, sb, 256);
       var cb2 = new StringBuilder(256); GetClassName(h, cb2, 256);
       res.Add(h.ToString() + " vis=" + IsWindowVisible(h) + " class=" + cb2 + " title=" + sb);
     }
     return true;
   }, IntPtr.Zero);
   return res;
 }
}
"@
$exe = "E:\user\docs\Trae-CN\temp_20261107_02\probe\EditTest\bin\Release\net8.0-windows\EditTest.exe"
$p = Start-Process -FilePath $exe -ArgumentList @("dialog", "E:\user\docs\Trae-CN\temp_20261107_02\probe\spd_raw.bin", "trcd") -PassThru
Start-Sleep -Seconds 3
Write-Output ("pid=" + $p.Id + " exited=" + $p.HasExited + " mwh=" + $p.MainWindowHandle)
[WEnum]::List([uint32]$p.Id) | ForEach-Object { Write-Output $_ }
if (-not $p.HasExited) { $p.Kill() }
