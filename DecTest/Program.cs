using System;
using System.IO;
using SpdTool.Core;

class P
{
    static void Main(string[] args)
    {
        byte[] raw = File.ReadAllBytes(args[0]);
        if (args.Length > 1 && args[1] == "fields")
        {
            var defs = SpdFieldCatalog.Build(raw);
            foreach (var fd in defs)
            {
                string edit = "";
                try { edit = fd.EditText(raw); } catch (Exception e) { edit = "ERR:" + e.Message; }
                string disp = "";
                try { disp = fd.Display(raw); } catch (Exception e) { disp = "ERR:" + e.Message; }
                Console.WriteLine($"{fd.Key,-22} {fd.Name,-14} edit=[{edit}] display=[{disp}]");
            }
            Console.WriteLine("count=" + defs.Count);
            return;
        }
        Console.WriteLine("CRC: " + SpdCrc.Describe(raw));
        var d = new Ddr4Decoder(raw);
        foreach (var g in d.Decode())
        {
            Console.WriteLine("[" + g.Title + "]");
            foreach (var f in g.Fields)
                Console.WriteLine($"  {f.Name,-16} {f.Value}" + (f.Note == null ? "" : "  # " + f.Note));
        }
        bool ok;
        Console.WriteLine(d.SelfCheck(out ok));
        Console.WriteLine("SELFCHECK=" + ok);
    }
}
