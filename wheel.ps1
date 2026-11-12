Add-Type -AssemblyName System.Drawing
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class WH {
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
}
"@
[WH]::SetProcessDPIAware() | Out-Null
$p = Get-Process "SPDTool" -ErrorAction Stop | Select-Object -First 1
$h = $p.MainWindowHandle
$r = New-Object WH+RECT
[WH]::GetWindowRect($h, [ref]$r) | Out-Null
[WH]::SetCursorPos(($r.L + 300), ($r.T + 500)) | Out-Null
Start-Sleep -Milliseconds 200
$n = [int]$args[0]
for ($i = 0; $i -lt $n; $i++) {
  [WH]::mouse_event(0x0800, 0, 0, [uint32]4294967116, [UIntPtr]::Zero)
  Start-Sleep -Milliseconds 80
}
Write-Output ("wheel " + $n)
