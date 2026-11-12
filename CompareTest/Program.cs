using System;
using System.IO;
using System.Windows.Forms;
using SpdTool;

namespace CompareTest
{
    internal static class Program
    {
        [STAThread]
        private static void Main(string[] args)
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.ThreadException += (s, e) =>
                File.WriteAllText(Path.Combine(AppContext.BaseDirectory, "compare_err.txt"), "ThreadException:\n" + e.Exception);
            AppDomain.CurrentDomain.UnhandledException += (s, e) =>
                File.WriteAllText(Path.Combine(AppContext.BaseDirectory, "compare_err2.txt"), "Unhandled:\n" + e.ExceptionObject);
            if (args.Length < 2)
            {
                MessageBox.Show("需要两个 512 字节 SPD 文件作为参数。");
                return;
            }
            try
            {
                var a = File.ReadAllBytes(args[0]);
                var b = File.ReadAllBytes(args[1]);
                var f = new CompareForm(a, Path.GetFileName(args[0]), b, Path.GetFileName(args[1]));
                Application.Run(f);
            }
            catch (Exception ex)
            {
                File.WriteAllText(Path.Combine(AppContext.BaseDirectory, "compare_err.txt"), ex.ToString());
                MessageBox.Show(ex.ToString());
            }
        }
    }
}
