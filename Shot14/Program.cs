using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Threading;
using System.Windows.Forms;
using SpdTool;
using SpdTool.Core;

namespace Shot12
{
    internal static class Program
    {
        [DllImport("user32.dll")] private static extern bool PrintWindow(IntPtr h, IntPtr hdc, uint flags);
        [DllImport("user32.dll")] private static extern bool SetProcessDPIAware();

        private static string _dir;

        [STAThread]
        private static void Main(string[] args)
        {
            File.WriteAllText(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "main_enter.txt"), string.Join(" ", args));
            SetProcessDPIAware();
            if (args.Length > 0 && args[0] == "regen-jedec")
            {
                string target = args.Length > 1 ? args[1] : AppDomain.CurrentDomain.BaseDirectory;
                JedecBins.EnsureGenerated(target);
                Console.WriteLine("jedec-bins.json regenerated at " + target);
                return;
            }
            if (args.Length > 0 && args[0] == "import-test")
            {
                RunImportTest();
                return;
            }
            if (args.Length > 0 && args[0] == "build-db")
            {
                RunBuildDb(args.Length > 1 ? args[1] : Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\..\..\..\db_chunks"),
                           args.Length > 2 ? args[2] : Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\..\..\..\spd-database.json"));
                return;
            }
            if (args.Length > 0 && args[0] == "db-test")
            {
                string dir = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\..\..\.."));
                try { RunDbTest(); }
                catch (Exception ex) { File.WriteAllText(Path.Combine(dir, "db_test.txt"), ex.ToString()); }
                return;
            }
            if (args.Length > 0 && args[0] == "wizard-db")
            {
                RunWizardDb();
                return;
            }
            _dir = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\..\..\.."));
            byte[] raw = File.ReadAllBytes(Path.Combine(_dir, "spd_raw.bin"));

            var wiz = new XmpWizardForm(raw, null, false, "离线转储");
            wiz.StartPosition = FormStartPosition.Manual;
            wiz.Location = new Point(0, 0);
            wiz.Show();
            Pump(1500);
            Capture(wiz, "shot_130_wizard1.png");

            Button next = FindButton(wiz, "下一步");
            if (next != null)
            {
                next.PerformClick();
                Pump(1200);
                Capture(wiz, "shot_130_wizard2.png");

                CheckBox chk = FindCheckBox(wiz, "仅看推荐");
                if (chk != null && chk.Checked)
                {
                    chk.Checked = false;
                    Pump(900);
                    Capture(wiz, "shot_130_wizard2_all.png");

                    ComboBox brand = FindComboWithItem(wiz, "全部品牌");
                    if (brand != null)
                    {
                        brand.SelectedIndex = 1;
                        Pump(900);
                        Capture(wiz, "shot_130_wizard2_filter.png");
                    }
                }
            }
            wiz.Close();
            Pump(300);

            var die = new DieInfoForm(raw);
            die.StartPosition = FormStartPosition.Manual;
            die.Location = new Point(0, 0);
            die.Show();
            Pump(1200);
            Capture(die, "shot_130_die.png");
            die.Close();

            var main = new MainForm(Path.Combine(_dir, "spd_raw.bin"));
            main.StartPosition = FormStartPosition.Manual;
            main.Location = new Point(0, 0);
            main.Show();
            Pump(3000);
            Capture(main, "shot_130_main.png");
            main.Close();

            var dec = new Ddr4Decoder(raw);
            string report = Reports.BuildTextReport(raw, dec, dec.Decode(), "离线转储 · 导出测试", false);
            File.WriteAllText(Path.Combine(_dir, "out_report.txt"), report, new System.Text.UTF8Encoding(false));
        }

        private static void RunImportTest()
        {
            string root = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\..\..\.."));
            string work = Path.Combine(root, "import_test");
            if (Directory.Exists(work)) Directory.Delete(work, true);
            Directory.CreateDirectory(work);

            var log = new System.Text.StringBuilder();
            string thp = @"F:\软件工具\ThaiphoonBurner16_1115\JUHOR JHD3600U1616JGS DDR4-2400T with XMP.thp";
            string bin = Path.Combine(root, "spd_raw.bin");

            string err;
            var r1 = ImportedPresets.Import(thp, work, out err);
            log.AppendLine("[.thp] " + thp);
            log.AppendLine("added=" + r1.Added + " skipped=" + r1.Skipped + " duplicates=" + r1.Duplicates);
            log.AppendLine("error=" + (err ?? "(none)"));
            log.AppendLine("message=" + (r1.Message ?? "(none)"));
            log.AppendLine();

            var r2 = ImportedPresets.Import(bin, work, out err);
            log.AppendLine("[.bin 首次] " + bin);
            log.AppendLine("added=" + r2.Added + " skipped=" + r2.Skipped + " duplicates=" + r2.Duplicates);
            log.AppendLine("error=" + (err ?? "(none)"));
            log.AppendLine("message=" + (r2.Message ?? "(none)"));
            log.AppendLine();

            var r3 = ImportedPresets.Import(bin, work, out err);
            log.AppendLine("[.bin 二次] " + bin);
            log.AppendLine("added=" + r3.Added + " skipped=" + r3.Skipped + " duplicates=" + r3.Duplicates);
            log.AppendLine("error=" + (err ?? "(none)"));
            log.AppendLine();

            string lib = Path.Combine(work, ImportedPresets.FileName);
            log.AppendLine("imported-presets.json exists=" + File.Exists(lib) +
                           (File.Exists(lib) ? " size=" + new FileInfo(lib).Length : ""));

            byte[] raw = File.ReadAllBytes(bin);
            log.AppendLine("spd_raw byte0=0x" + raw[0].ToString("X2") +
                           " crc0=" + SpdCrc.ValidSection0(raw) + " crc1=" + SpdCrc.ValidSection1(raw));
            log.AppendLine();

            var libj = JedecBins.BuildLibrary();
            string hex = libj.Bins[0].SpdHex;
            byte[] synth = new byte[512];
            for (int i = 0; i < 256; i++)
                synth[i] = Convert.ToByte(hex.Substring(i * 2, 2), 16);
            string synthPath = Path.Combine(work, "jedec2133_synth.bin");
            File.WriteAllBytes(synthPath, synth);
            var r4 = ImportedPresets.Import(synthPath, work, out err);
            log.AppendLine("[合成 JEDEC .bin 首次] " + synthPath);
            log.AppendLine("added=" + r4.Added + " skipped=" + r4.Skipped + " duplicates=" + r4.Duplicates);
            log.AppendLine("error=" + (err ?? "(none)"));
            log.AppendLine("message=" + (r4.Message ?? "(none)"));
            log.AppendLine();
            var r5 = ImportedPresets.Import(synthPath, work, out err);
            log.AppendLine("[合成 JEDEC .bin 二次]");
            log.AppendLine("added=" + r5.Added + " skipped=" + r5.Skipped + " duplicates=" + r5.Duplicates);
            log.AppendLine("error=" + (err ?? "(none)"));
            log.AppendLine();
            File.WriteAllText(Path.Combine(work, "import_result.txt"), log.ToString(), new System.Text.UTF8Encoding(false));
        }

        private static void RunBuildDb(string chunkDir, string target)
        {
            var all = new List<SpdDbEntry>();
            var log = new System.Text.StringBuilder();
            foreach (string file in Directory.GetFiles(chunkDir, "*.json").OrderBy(f => f))
            {
                string err;
                var list = SpdDbImport.ReadJson(file, out err);
                if (list == null)
                {
                    log.AppendLine(Path.GetFileName(file) + "：读取失败 " + err);
                    continue;
                }
                int added = SpdDatabase.Merge(all, list);
                log.AppendLine(Path.GetFileName(file) + "：读入 " + list.Count + "，新增 " + added);
            }
            string saveErr;
            bool ok = SpdDatabase.Save(all, target, out saveErr);
            log.AppendLine("total=" + all.Count + " save=" + ok + (saveErr == null ? "" : " err=" + saveErr));
            foreach (var g in all.GroupBy(e => e.Brand).OrderByDescending(g => g.Count()))
                log.AppendLine("brand " + g.Key + "=" + g.Count());
            foreach (var g in all.GroupBy(e => e.SourceType).OrderByDescending(g => g.Count()))
                log.AppendLine("source " + g.Key + "=" + g.Count());
            File.WriteAllText(target + ".log", log.ToString(), new System.Text.UTF8Encoding(false));
        }

        private static void RunDbTest()
        {
            string root = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\..\..\.."));
            _dir = root;
            string stepFile = Path.Combine(root, "db_steps.txt");
            File.WriteAllText(stepFile, "");
            void Step(string s) { File.AppendAllText(stepFile, s + "\r\n"); }
            Step("start");
            var log = new System.Text.StringBuilder();
            byte[] raw = File.ReadAllBytes(Path.Combine(root, "spd_raw.bin"));
            Step("raw loaded");
            var all = SpdDatabase.Load();
            Step("db loaded " + all.Count);
            log.AppendLine("db entries=" + all.Count);
            log.AppendLine("db brands=" + string.Join(",", all.GroupBy(e => e.Brand).Select(g => g.Key + ":" + g.Count()).ToArray()));

            // 1) 数据库页 + 搜索 + 选中详情
            Step("page ctor");
            var page = new SpdDatabasePage(e => { }, s => { });
            Step("host ctor");
            var host = new Form { ClientSize = new Size(1040, 660), Text = "SPD 数据库", StartPosition = FormStartPosition.Manual, Location = new Point(0, 0) };
            host.Controls.Add(page);
            Step("host show");
            host.Show();
            Step("host shown");
            Pump(500);
            Step("search");
            var search = (TextBox)typeof(SpdDatabasePage).GetField("_search", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(page);
            search.Text = "3200";
            Pump(350);
            Step("search done");
            var tree = FindControl<TreeView>(page);
            int brandNodes = tree.Nodes.Count;
            int leafNodes = tree.Nodes.Cast<TreeNode>().Sum(n => n.Nodes.Count);
            log.AppendLine("search 3200 -> brandNodes=" + brandNodes + " leafNodes=" + leafNodes);
            if (tree.Nodes.Count > 0 && tree.Nodes[0].Nodes.Count > 0)
            {
                tree.SelectedNode = tree.Nodes[0].Nodes[0];
                Pump(250);
            }
            Capture(host, "shot_140_db.png");
            search.Text = "";
            Pump(300);
            if (tree.Nodes.Count > 0 && tree.Nodes[0].Nodes.Count > 0)
            {
                tree.SelectedNode = tree.Nodes[0].Nodes[0];
                Pump(250);
            }
            Capture(host, "shot_140_db_selected.png");
            Step("db shots done");
            host.Close();

            // 2) 三联编辑器：ns 改 -> CK/nCK 同步；应用后工作副本回读
            Step("timing start");
            var entry = all.FirstOrDefault(e => e.DataRate == 3200) ?? all.FirstOrDefault();
            if (entry != null)
            {
                var work = raw.ToArray();
                var defs = SpdFieldCatalog.Build(work);
                var freq = SpdFieldCatalog.ByKey(defs, "timing.freq");
                if (freq != null) freq.Apply(work, (entry.DataRate / 2.0).ToString("0.###", System.Globalization.CultureInfo.InvariantCulture));
                var tf = new TimingEditorForm(entry, work);
                Step("timing ctor ok");
                tf.StartPosition = FormStartPosition.Manual;
                tf.Location = new Point(0, 0);
                tf.Show();
                Step("timing shown");
                Pump(500);
                Capture(tf, "shot_140_timing.png");
                Step("timing shot done");
                var grid = FindControl<DataGridView>(tf);
                var sync = typeof(TimingEditorForm).GetMethod("SyncRow", BindingFlags.Instance | BindingFlags.NonPublic);
                grid.Rows[1].Cells[2].Value = "11.25";
                sync.Invoke(tf, new object[] { 1, 2 });
                log.AppendLine("sync tRCD ns=11.25 -> CK=" + grid.Rows[1].Cells[1].Value + " nCK=" + grid.Rows[1].Cells[3].Value);
                var apply = typeof(TimingEditorForm).GetMethod("ApplyAll", BindingFlags.Instance | BindingFlags.NonPublic);
                apply.Invoke(tf, null);
                var dec = new Ddr4Decoder(work);
                log.AppendLine("after apply tRCD=" + dec.TrcdNs.ToString("0.###") + "ns tCK=" + dec.TCKMinNs.ToString("0.###"));
            }

            // 3) 批量导入：CSV 列映射 + 去重
            Step("import start");
            byte[] dumpSpd = ImportedPresets.FindSpdBlock(raw, out int dumpOffset);
            if (dumpSpd != null)
            {
                var dump = SpdDatabase.FromWork(dumpSpd, "spd_raw");
                var dec2 = new Ddr4Decoder(dumpSpd);
                log.AppendLine("dump import offset=" + dumpOffset + " brand=" + dec2.ModuleVendorName +
                               " model=" + dec2.PartNumber + " -> DDR4-" + dump.DataRate + " " + dump.TimingText);
            }
            string csv = Path.Combine(root, "import_test", "sample_models.csv");
            Directory.CreateDirectory(Path.GetDirectoryName(csv));
            File.WriteAllText(csv,
                "品牌,系列,型号,容量GB,频率,CL,tRCD,tRP,tRAS,电压,来源链接\r\n" +
                "金百达,银爵,示例3200,16,3200,16,18,18,38,1.35,https://example.com/a\r\n" +
                "光威,天策,示例3600,32,3600,18,22,22,42,1.35,https://example.com/b\r\n" +
                "坏行,,,,,,,,,,\r\n", new System.Text.UTF8Encoding(false));
            string err;
            var table = SpdDbImport.ReadTable(csv, out err);
            var map = SpdDbImport.AutoMap(table.Headers);
            var mapped = SpdDbImport.MapRows(table, map, out int skipped, out err);
            log.AppendLine("csv rows=" + table.Rows.Count + " mapped=" + (mapped == null ? 0 : mapped.Count) + " skipped=" + skipped);
            var importForm = new SpdDbImportForm(csv);
            Step("import form ctor ok");
            var maps = (ComboBox[])typeof(SpdDbImportForm)
                .GetField("_maps", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(importForm);
            log.AppendLine("ui map=" + string.Join(",", maps.Select(c =>
                c.SelectedItem is SpdDbMapField f ? f.Id : "ignore").ToArray()));
            importForm.StartPosition = FormStartPosition.Manual;
            importForm.Location = new Point(0, 0);
            importForm.Show();
            Step("import form shown");
            Pump(450);
            Capture(importForm, "shot_140_import.png");
            importForm.Close();
            Step("import done");

            // 4) 主界面标题与数据库标签页
            Step("main ctor");
            var main = new MainForm(Path.Combine(root, "spd_raw.bin"));
            Step("main ctor ok");
            main.StartPosition = FormStartPosition.Manual;
            main.Location = new Point(0, 0);
            main.Show();
            Step("main shown");
            Pump(600);
            Capture(main, "shot_140_main.png");
            Step("main shot done");
            var tabs = FindControl<TabControl>(main);
            if (tabs != null)
            {
                var dbTab = tabs.TabPages.Cast<TabPage>().FirstOrDefault(t => t.Text == "SPD 数据库");
                if (dbTab != null)
                {
                    tabs.SelectedTab = dbTab;
                    Pump(400);
                    Capture(main, "shot_140_main_db.png");
                }
                log.AppendLine("main tabs=" + string.Join(",", tabs.TabPages.Cast<TabPage>().Select(t => t.Text).ToArray()));
            }
            log.AppendLine("main title=" + main.Text);
            Step("main title=" + main.Text);
            main.Close();
            File.WriteAllText(Path.Combine(root, "db_test.txt"), log.ToString(), new System.Text.UTF8Encoding(false));
        }

        private static void RunWizardDb()
        {
            string root = Path.GetFullPath(Path.Combine(AppDomain.CurrentDomain.BaseDirectory, @"..\..\..\.."));
            _dir = root;
            var log = new System.Text.StringBuilder();
            byte[] raw = File.ReadAllBytes(Path.Combine(root, "spd_raw.bin"));

            var wiz = new XmpWizardForm(raw, null, false, "离线转储");
            wiz.StartPosition = FormStartPosition.Manual;
            wiz.Location = new Point(0, 0);
            wiz.Show();
            Pump(1200);
            Button next = FindButton(wiz, "下一步");
            if (next != null) { next.PerformClick(); Pump(1200); }
            Capture(wiz, "shot_140_wizard2_db.png");
            log.AppendLine("wizard step2 has db button=" + (FindButton(wiz, "从 SPD 数据库选择…") != null));
            wiz.Close();
            Pump(300);

            var picker = new SpdDbPickerForm();
            picker.StartPosition = FormStartPosition.Manual;
            picker.Location = new Point(0, 0);
            picker.Show();
            Pump(600);
            var tree = (TreeView)typeof(SpdDbPickerForm)
                .GetField("_tree", BindingFlags.Instance | BindingFlags.NonPublic).GetValue(picker);
            if (tree.Nodes.Count > 0 && tree.Nodes[0].Nodes.Count > 2)
                tree.SelectedNode = tree.Nodes[0].Nodes[2];
            Pump(300);
            Capture(picker, "shot_140_db_picker.png");
            log.AppendLine("picker groups=" + tree.Nodes.Count +
                           " leaves=" + tree.Nodes.Cast<TreeNode>().Sum(n => n.Nodes.Count));
            var choose = typeof(SpdDbPickerForm).GetMethod("Choose", BindingFlags.Instance | BindingFlags.NonPublic);
            choose.Invoke(picker, null);
            Pump(200);

            if (picker.Selected != null)
            {
                log.AppendLine("picked=" + picker.Selected.Brand + " " + picker.Selected.Model +
                               " DDR4-" + picker.Selected.DataRate + " " + picker.Selected.TimingText);
                var m = typeof(XmpWizardForm).GetMethod("PresetFromDatabase", BindingFlags.Static | BindingFlags.NonPublic);
                var preset = (XmpPreset)m.Invoke(null, new object[] { picker.Selected });
                string why;
                log.AppendLine("preset=" + preset.Name + " rate=" + preset.DataRate +
                               " valid=" + preset.Validate(out why) + (why == null ? "" : " why=" + why));
            }
            File.WriteAllText(Path.Combine(root, "wizard_db_test.txt"), log.ToString(), new System.Text.UTF8Encoding(false));
            Console.WriteLine(log.ToString());
        }

        private static T FindControl<T>(Control root) where T : Control
        {
            foreach (Control c in root.Controls)
            {
                if (c is T t) return t;
                var r = FindControl<T>(c);
                if (r != null) return r;
            }
            return null;
        }

        private static void Pump(int ms)
        {
            var end = DateTime.Now.AddMilliseconds(ms);
            while (DateTime.Now < end)
            {
                Application.DoEvents();
                Thread.Sleep(20);
            }
        }

        private static Button FindButton(Control root, string text)
        {
            foreach (Control c in root.Controls)
            {
                if (c is Button && c.Text == text) return (Button)c;
                Button b = FindButton(c, text);
                if (b != null) return b;
            }
            return null;
        }

        private static CheckBox FindCheckBox(Control root, string text)
        {
            foreach (Control c in root.Controls)
            {
                if (c is CheckBox && c.Text == text) return (CheckBox)c;
                CheckBox b = FindCheckBox(c, text);
                if (b != null) return b;
            }
            return null;
        }

        private static ComboBox FindComboWithItem(Control root, string item)
        {
            foreach (Control c in root.Controls)
            {
                if (c is ComboBox && ((ComboBox)c).Items.Contains(item)) return (ComboBox)c;
                ComboBox b = FindComboWithItem(c, item);
                if (b != null) return b;
            }
            return null;
        }

        private static void Capture(Form f, string name)
        {
            var bmp = new Bitmap(f.Width, f.Height);
            using (var g = Graphics.FromImage(bmp))
            {
                IntPtr hdc = g.GetHdc();
                PrintWindow(f.Handle, hdc, 2);
                g.ReleaseHdc(hdc);
            }
            bmp.Save(Path.Combine(_dir, name), ImageFormat.Png);
            bmp.Dispose();
            Console.WriteLine("saved " + name);
        }
    }
}
