Add-Type @"
using System;
using System.Runtime.InteropServices;
public class A {
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 public delegate bool EnumProc(IntPtr h, IntPtr l);
 public static uint Pid = 0;
 public static IntPtr Target = IntPtr.Zero;
 public static bool Cb(IntPtr h, IntPtr l) {
   uint pid; GetWindowThreadProcessId(h, out pid);
   if (pid == Pid && IsWindowVisible(h)) { Target = h; return false; }
   return true;
 }
}
"@
[A]::SetProcessDPIAware() | Out-Null
$p = Get-Process "SPDTool" -ErrorAction Stop | Select-Object -First 1
[A]::Pid = [uint32]$p.Id
[A]::EnumWindows([A]::Cb, [IntPtr]::Zero) | Out-Null
$h = [A]::Target
[A]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 500
$ws = New-Object -ComObject WScript.Shell
$ws.SendKeys($args[0])
Start-Sleep -Milliseconds 300
$ws.SendKeys("{ENTER}")
Write-Output ("typed " + $args[0])
