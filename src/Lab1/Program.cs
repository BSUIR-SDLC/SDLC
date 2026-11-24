using System;
using System.Windows.Forms;
using EmployeeValueMVC.Views;

namespace EmployeeValueMVC
{
    static class Program
    {
        [STAThread]
        static void Main()
        {
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new MainForm());
        }
    }
}
