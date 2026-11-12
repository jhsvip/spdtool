using System;
using System.Runtime.InteropServices;
using Microsoft.Win32.SafeHandles;

class Probe
{
    const uint READ_PORT = 0x80102050, WRITE_PORT = 0x80102054;

    [DllImport("kernel32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    static extern SafeFileHandle CreateFileW(string name, uint access, uint share, IntPtr sa, uint disp, uint flags, IntPtr tmpl);

    [DllImport("kernel32.dll", SetLastError = true)]
    static extern bool DeviceIoControl(SafeFileHandle h, uint code, byte[] inBuf, int inSize,
        byte[] outBuf, int outSize, out int bytesRet, IntPtr overlapped);

    static SafeFileHandle h;

    static bool Open()
    {
        foreach (var n in new[] { @"\\.\MsIo", @"\\.\MsIo64" })
        {
            h = CreateFileW(n, 0xC0000000, 3, IntPtr.Zero, 3, 0, IntPtr.Zero);
            if (!h.IsInvalid) { Console.WriteLine("opened " + n); return true; }
            Console.WriteLine("open failed " + n + " err=" + Marshal.GetLastWin32Error());
        }
        return false;
    }

    static uint Read(int port, byte size)
    {
        byte[] i = new byte[8]; i[0] = (byte)port; i[1] = (byte)(port >> 8); i[6] = size;
        byte[] o = new byte[8]; int r;
        if (!DeviceIoControl(h, READ_PORT, i, 8, o, 8, out r, IntPtr.Zero)) return 0xFFFFFFFF;
        uint v = BitConverter.ToUInt32(o, 0);
        return size == 1 ? v & 0xFF : v & 0xFFFF;
    }

    static void Write(int port, uint val, byte size)
    {
        byte[] i = new byte[8]; i[0] = (byte)port; i[1] = (byte)(port >> 8);
        i[2] = (byte)val; i[3] = (byte)(val >> 8); i[4] = (byte)(val >> 16); i[5] = (byte)(val >> 24); i[6] = size;
        int r; DeviceIoControl(h, WRITE_PORT, i, 8, null, 0, out r, IntPtr.Zero);
    }

    static int _base;

    static bool WaitReady(int timeoutMs)
    {
        var t0 = Environment.TickCount;
        while ((int)(Environment.TickCount - t0) < timeoutMs)
        {
            if ((Read(_base, 1) & 1) == 0) return true;
            System.Threading.Thread.Sleep(1);
        }
        return false;
    }

    static bool Begin()
    {
        if (!WaitReady(100)) { Console.WriteLine("BUSY stuck"); return false; }
        Write(_base, 0x3E, 1); // clear INTR/DEV_ERR/BUS_ERR/FAILED
        if (!WaitReady(50)) { Console.WriteLine("BUSY after clear"); return false; }
        return true;
    }

    static bool SendByte(int slave7, byte data)
    {
        if (!Begin()) return false;
        Write(_base + 4, (uint)(slave7 << 1), 1);
        Write(_base + 5, data, 1);
        Write(_base + 2, 0x44, 1);
        if (!WaitReady(100)) { Console.WriteLine("timeout send"); return false; }
        uint st = Read(_base, 1);
        Console.WriteLine("send sts=0x" + st.ToString("X2"));
        return (st & 0x1C) == 0;
    }

    static int ReadByte(int slave7, byte cmd)
    {
        if (!Begin()) return -1;
        Write(_base + 4, (uint)((slave7 << 1) | 1), 1);
        Write(_base + 3, cmd, 1);
        Write(_base + 2, 0x48, 1);
        if (!WaitReady(100)) { Console.WriteLine("timeout read"); return -1; }
        uint st = Read(_base, 1);
        if ((st & 0x1C) != 0) { Console.WriteLine("read err sts=0x" + st.ToString("X2")); return -1; }
        return (int)Read(_base + 5, 1);
    }

    static void Main()
    {
        if (!Open()) return;
        Console.WriteLine("PCI 00:1F.4 id = " + ReadPci(0, 0x1F, 4, 0x00).ToString("X8"));
        Console.WriteLine("PCI 00:1F.4 class = " + ReadPci(0, 0x1F, 4, 0x08).ToString("X8"));
        uint bar4 = ReadPci(0, 0x1F, 4, 0x20);
        _base = (int)(bar4 & 0xFFE0);
        Console.WriteLine("BAR4 @0x20 = 0x" + bar4.ToString("X8") + " -> IO base 0x" + _base.ToString("X4"));
        Console.WriteLine("STS = 0x" + Read(_base, 1).ToString("X2"));

        var raw = new byte[512];
        int txn = 0;
        for (int page = 0; page < 2; page++)
        {
            int sel = SendByte(0x36 + page, 0) ? 1 : 0;
            System.Threading.Thread.Sleep(2);
            bool pageAck = ReceiveByte(0x36);
            Console.WriteLine($"page{page}: select-ack={sel} curpage0-ack={pageAck}");
            txn += 3;
            for (int off = 0; off < 256; off++)
            {
                int v = ReadByte(0x51, (byte)off);
                if (v < 0) { Console.WriteLine($"FAIL page{page} off {off}"); return; }
                raw[page * 256 + off] = (byte)v;
                txn++;
                if ((off & 63) == 63) System.Threading.Thread.Sleep(1);
            }
        }
        ushort crc0 = Crc16(raw, 0, 126);
        ushort crc1 = Crc16(raw, 128, 126);
        Console.WriteLine($"txn={txn} crc0 calc={crc0:X4} stored={raw[127]:X2}{raw[126]:X2} crc1 calc={crc1:X4} stored={raw[255]:X2}{raw[254]:X2}");
        System.IO.File.WriteAllBytes(@"E:\user\docs\Trae-CN\temp_20261107_02\probe\spd_raw.bin", raw);
        Console.WriteLine("first 16: " + BitConverter.ToString(raw, 0, 16));
        Console.WriteLine("part#: " + System.Text.Encoding.ASCII.GetString(raw, 329, 20));
    }

    static bool ReceiveByte(int slave7)
    {
        if (!Begin()) return false;
        Write(_base + 4, (uint)((slave7 << 1) | 1), 1);
        Write(_base + 2, 0x44, 1);
        if (!WaitReady(100)) return false;
        uint st = Read(_base, 1);
        return (st & 0x1C) == 0;
    }

    static ushort Crc16(byte[] d, int start, int len)
    {
        ushort crc = 0;
        for (int i = 0; i < len; i++)
        {
            crc ^= (ushort)(d[start + i] << 8);
            for (int b = 0; b < 8; b++)
                crc = (ushort)((crc << 1) ^ (((crc >> 15) & 1) != 0 ? 0x1021 : 0));
        }
        return crc;
    }

    static uint ReadPci(int bus, int dev, int fn, int reg)
    {
        uint a = 0x80000000u | ((uint)bus << 16) | ((uint)dev << 11) | ((uint)fn << 8) | ((uint)(reg & 0xFC));
        byte[] i = new byte[8]; i[0] = 0xF8; i[1] = 0x0C; i[2] = (byte)a; i[3] = (byte)(a >> 8); i[4] = (byte)(a >> 16); i[5] = (byte)(a >> 24); i[6] = 4;
        byte[] o = new byte[8]; int r;
        DeviceIoControl(h, WRITE_PORT, i, 8, null, 0, out r, IntPtr.Zero);
        byte[] q = new byte[8]; q[0] = 0xFC; q[1] = 0x0C; q[6] = 4;
        if (!DeviceIoControl(h, READ_PORT, q, 8, o, 8, out r, IntPtr.Zero)) return 0xFFFFFFFF;
        return BitConverter.ToUInt32(o, 0);
    }
}
