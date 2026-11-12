Add-Type @"
using System;
using System.Runtime.InteropServices;
public class K {
 [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, UIntPtr extra);
 public const byte VK_DOWN = 0x28, VK_RETURN = 0x0D, VK_ESC = 0x1B, VK_NEXT = 0x22, VK_MENU = 0x12, VK_F = 0x46;
 public static void Tap(byte vk) {
   keybd_event(vk, 0, 0, UIntPtr.Zero);
   keybd_event(vk, 0, 2, UIntPtr.Zero);
 }
}
"@
foreach ($a in $args) { if ($a -eq 'down') { [K]::Tap([K]::VK_DOWN); Start-Sleep -Milliseconds 200 } elseif ($a -eq 'enter') { [K]::Tap([K]::VK_RETURN); Start-Sleep -Milliseconds 300 } elseif ($a -eq 'esc') { [K]::Tap([K]::VK_ESC); Start-Sleep -Milliseconds 300 } elseif ($a -eq 'pgdn') { [K]::Tap([K]::VK_NEXT); Start-Sleep -Milliseconds 500 } elseif ($a -eq 'altf') { [K]::keybd_event([K]::VK_MENU, 0, 0, [UIntPtr]::Zero); [K]::Tap([K]::VK_F); [K]::keybd_event([K]::VK_MENU, 0, 2, [UIntPtr]::Zero); Start-Sleep -Milliseconds 400 } }
Write-Output "keys sent"
