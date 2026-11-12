using System;
using System.IO;
using System.Linq;
using SpdTool.Core;

class W
{
    static void Main(string[] args)
    {
        const int Target = 0x1FE;   // 保留区末字节，不在 CRC 覆盖范围内，适合做可逆写入验证
        string baseBin = args.Length > 0 ? args[0] : "spd_raw.bin";

        var io = new MsIoPort();
        string err;
        if (!io.Open(out err)) { Console.WriteLine("驱动不可用: " + err); return; }
        var pci = PciSmbusLocator.Locate(io);
        Console.WriteLine("MsIo=" + io.OpenedName + "  " + pci);
        var bus = new SmbusIntel(io, pci.IoBase);
        var dev = new Ddr4SpdDevice(bus, 0x51);

        byte[] cur = dev.ReadAll(null);
        Console.WriteLine("当前 CRC: " + SpdCrc.Describe(cur));
        byte[] baseline = args.Length > 1 ? File.ReadAllBytes(args[1]) : null;
        if (baseline != null)
            Console.WriteLine("与基线 bin 一致: " + (Reports.Sha256Hex(cur) == Reports.Sha256Hex(baseline)));
        Console.WriteLine("目标字节 0x" + Target.ToString("X3") + " 现值 = 0x" + cur[Target].ToString("X2"));

        if (args.Length > 2 && args[2] == "read")
        {
            var dec = new Ddr4Decoder(cur);
            var groups = dec.Decode();
            string dir = Path.GetDirectoryName(baseBin);
            File.WriteAllText(Path.Combine(dir, "export_test.csv"), Reports.BuildCsv(cur, dec, groups), System.Text.Encoding.UTF8);
            File.WriteAllText(Path.Combine(dir, "export_test.txt"), Reports.BuildTextReport(cur, dec, groups, "WriteTest"), System.Text.Encoding.UTF8);
            File.WriteAllText(Path.Combine(dir, "export_test_hex.txt"), Reports.HexDump(cur), System.Text.Encoding.UTF8);
            Console.WriteLine("导出已生成: export_test.csv / export_test.txt / export_test_hex.txt");
            io.Close(); return;
        }

        string backupDir = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "backups");
        string backup = Reports.SaveVerifiedBackup(cur, backupDir, "写入测试（标准保留字节）+ 写前自动备份");
        Console.WriteLine("备份: " + backup);

        byte[] desired = cur.ToArray();
        desired[Target] = (byte)(cur[Target] ^ 0x01);
        Console.WriteLine("写入 0x" + Target.ToString("X3") + ": 0x" + cur[Target].ToString("X2") + " -> 0x" + desired[Target].ToString("X2"));

        var r1 = dev.WriteAll(desired, cur, n => { });
        Console.WriteLine("写入1: " + (r1.Success ? "成功" : "失败") + " | " + r1.Message +
                          " | 写入字节 " + r1.WrittenOffsets.Count + " | 不一致 " + r1.MismatchOffsets.Count +
                          " | CRC " + r1.CrcValid);
        if (!r1.Success)
        {
            Console.WriteLine("写入未成功，不执行恢复；请用备份人工核对。");
            return;
        }

        // 恢复原值（同样走完整写流程：逐页写 + 回读比对）
        var r2 = dev.WriteAll(cur, desired, n => { });
        Console.WriteLine("恢复: " + (r2.Success ? "成功" : "失败") + " | " + r2.Message +
                          " | 写入字节 " + r2.WrittenOffsets.Count + " | 不一致 " + r2.MismatchOffsets.Count +
                          " | CRC " + r2.CrcValid);

        byte[] final = dev.ReadAll(null);
        Console.WriteLine("恢复后与基线一致: " + (Reports.Sha256Hex(final) == Reports.Sha256Hex(baseline)));
        Console.WriteLine("恢复后 CRC: " + SpdCrc.Describe(final));
        io.Close();
    }
}
