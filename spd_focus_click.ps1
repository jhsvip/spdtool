Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Text;
public class F {
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
 [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
 [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, UIntPtr e);
 [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
 [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint pid);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 public delegate bool EnumProc(IntPtr h, IntPtr l);
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
 public const uint LEFTDOWN = 0x0002, LEFTUP = 0x0004;
 public static IntPtr Target = IntPtr.Zero;
 public static uint TargetPid = 0;
 public static long BestArea = 0;
 public static bool Cb(IntPtr h, IntPtr l) {
   uint pid; GetWindowThreadProcessId(h, out pid);
   if (pid == TargetPid && IsWindowVisible(h)) {
     RECT r; GetWindowRect(h, out r);
     long a = (long)(r.R - r.L) * (r.B - r.T);
     if (a > BestArea) { BestArea = a; Target = h; }
   }
   return true;
 }
 public static IntPtr Find(uint pid) { TargetPid = pid; Target = IntPtr.Zero; BestArea = 0; EnumWindows(Cb, IntPtr.Zero); return Target; }
}
"@
[F]::SetProcessDPIAware() | Out-Null
$p = Get-Process "SPDTool" -ErrorAction Stop | Select-Object -First 1
$h = [F]::Find([uint32]$p.Id)
if ($h -eq [IntPtr]::Zero) { Write-Output "window not found"; exit 1 }
[F]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 400
$r = New-Object F+RECT
[F]::GetWindowRect($h, [ref]$r) | Out-Null
Write-Output ("window " + $r.L + "," + $r.T + " " + ($r.R - $r.L) + "x" + ($r.B - $r.T))
if ($args.Count -ge 2) {
  $x = $r.L + [int]$args[0]; $y = $r.T + [int]$args[1]
  [F]::SetCursorPos($x, $y) | Out-Null
  Start-Sleep -Milliseconds 150
  [F]::mouse_event([F]::LEFTDOWN, 0, 0, 0, [UIntPtr]::Zero)
  [F]::mouse_event([F]::LEFTUP, 0, 0, 0, [UIntPtr]::Zero)
  Write-Output ("clicked " + $x + "," + $y)
}
if ($args.Count -ge 4) {
  Start-Sleep -Milliseconds 1200
  $x2 = $r.L + [int]$args[2]; $y2 = $r.T + [int]$args[3]
  [F]::SetCursorPos($x2, $y2) | Out-Null
  Start-Sleep -Milliseconds 150
  [F]::mouse_event([F]::LEFTDOWN, 0, 0, 0, [UIntPtr]::Zero)
  [F]::mouse_event([F]::LEFTUP, 0, 0, 0, [UIntPtr]::Zero)
  Write-Output ("clicked2 " + $x2 + "," + $y2)
}
