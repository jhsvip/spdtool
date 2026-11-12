Add-Type @"
using System;
using System.Runtime.InteropServices;
public class M {
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
 public const uint LEFTDOWN = 0x0002, LEFTUP = 0x0004;
}
"@
[M]::SetProcessDPIAware() | Out-Null
$x = [int]$args[0]; $y = [int]$args[1]
[M]::SetCursorPos($x, $y) | Out-Null
Start-Sleep -Milliseconds 150
[M]::mouse_event([M]::LEFTDOWN, 0, 0, 0, [UIntPtr]::Zero)
[M]::mouse_event([M]::LEFTUP, 0, 0, 0, [UIntPtr]::Zero)
Write-Output ("clicked " + $x + "," + $y)
