using System;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Windows.Forms;
using SpdTool;
using SpdTool.Core;

namespace EditTest
{
    internal static class Program
    {
        [STAThread]
        private static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.ThreadException += (s, e) => Log(e.Exception);
            AppDomain.CurrentDomain.UnhandledException += (s, e) => Log(e.ExceptionObject as Exception);

            string mode = args.Length > 0 ? args[0] : "main";
            string dump = args.Length > 1 ? args[1] : @"E:\user\docs\Trae-CN\temp_20261107_02\probe\spd_raw.bin";
            byte[] work = File.ReadAllBytes(dump);

            try
            {
                if (mode == "dialog")
                {
                    var defs = SpdFieldCatalog.Build(work);
                    var def = SpdFieldCatalog.ByKey(defs, args.Length > 2 ? args[2] : "trcd");
                    var dlg = new FieldEditorForm(def, work, work.ToArray());
                    dlg.StartPosition = FormStartPosition.Manual;
                    dlg.Location = new System.Drawing.Point(30, 30);
                    Application.Run(dlg);
                }
                else if (mode == "compare")
                {
                    var b = work.ToArray();
                    b[25] = (byte)(b[25] + 2);           // tRCD +250ps
                    b[24] = (byte)(b[24] + 1);           // tCL +125ps
                    b[195] = (byte)(b[195] + 1);         // XMP P1 tRAS 低字节
                    SpdCrc.Fix(b);
                    var dlg = new CompareForm(work, "A：原始读取", b, "B：演示改动（tRCD/tCL/XMP tRAS）");
                    dlg.StartPosition = FormStartPosition.Manual;
                    dlg.Location = new System.Drawing.Point(30, 30);
                    Application.Run(dlg);
                }
                else
                {
                    var form = new MainForm();
                    var mi = typeof(MainForm).GetMethod("LoadDumpFile",
                        BindingFlags.Instance | BindingFlags.Public | BindingFlags.NonPublic);
                    mi.Invoke(form, new object[] { dump });

                    string tabArg = args.Length > 2 ? args[2] : "";
                    int tab = 0;
                    if (tabArg == "edit")
                    {
                        // 演示：把 tRCD 抽头改大 2×125ps + tCL +1 → 生成改动并联动 hex/CRC 状态
                        var editedField = typeof(MainForm).GetField("_edited", BindingFlags.Instance | BindingFlags.NonPublic);
                        var edited = (byte[])editedField.GetValue(form);
                        edited[25] = (byte)(edited[25] + 2);
                        edited[24] = (byte)(edited[24] + 1);
                        var after = typeof(MainForm).GetMethod("AfterEdit", BindingFlags.Instance | BindingFlags.NonPublic);
                        after.Invoke(form, new object[] { "演示：字段编辑后（内存工作副本，未写入硬件）" });
                        if (args.Length > 3) int.TryParse(args[3], out tab);
                    }
                    else if (!int.TryParse(tabArg, out tab)) tab = 0;
                    var tabsField = typeof(MainForm).GetField("_tabs", BindingFlags.Instance | BindingFlags.NonPublic);
                    var tabs = (TabControl)tabsField.GetValue(form);
                    if (tab >= 0 && tab < tabs.TabPages.Count) tabs.SelectedIndex = tab;

                    form.StartPosition = FormStartPosition.Manual;
                    form.Location = new System.Drawing.Point(20, 20);
                    Application.Run(form);
                }
            }
            catch (Exception ex)
            {
                Log(ex);
                MessageBox.Show("测试宿主异常：" + ex, "EditTest");
            }
        }

        private static void Log(Exception ex)
        {
            try
            {
                File.AppendAllText(@"E:\user\docs\Trae-CN\temp_20261107_02\probe\edittest_error.log",
                    DateTime.Now + "\r\n" + (ex?.ToString() ?? "(null)") + "\r\n\r\n");
            }
            catch { }
        }
    }
}
