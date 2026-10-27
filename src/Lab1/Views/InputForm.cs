using System;
using System.Drawing;
using System.Windows.Forms;

namespace EmployeeValueMVC.Views
{
    public class InputForm : Form
    {
        private TextBox txtSalary;
        private TextBox txtHours;
        private TextBox txtActualHours;
        private Button btnSave;

        public string SalaryInput => txtSalary.Text;
        public string HoursInput => txtHours.Text;
        public string ActualHoursInput => txtActualHours.Text;

        public InputForm(string salary, string hours, string actualHours)
        {
            this.Text = "Ввод параметров";
            this.Size = new Size(320, 260);
            this.StartPosition = FormStartPosition.CenterParent;
            this.FormBorderStyle = FormBorderStyle.FixedDialog;

            Label lbl1 = new Label() { Text = "Зарплата:", Location = new Point(20, 20), Size = new Size(120, 20) };
            txtSalary = new TextBox() { Text = salary, Location = new Point(150, 20), Size = new Size(120, 20) };

            Label lbl2 = new Label() { Text = "План часов:", Location = new Point(20, 60), Size = new Size(120, 20) };
            txtHours = new TextBox() { Text = hours, Location = new Point(150, 60), Size = new Size(120, 20) };

            Label lbl3 = new Label() { Text = "Факт часов:", Location = new Point(20, 100), Size = new Size(120, 20) };
            txtActualHours = new TextBox() { Text = actualHours, Location = new Point(150, 100), Size = new Size(120, 20) };

            btnSave = new Button() { Text = "Сохранить", Location = new Point(90, 160), Size = new Size(120, 35) };
            btnSave.Click += (s, e) => { this.DialogResult = DialogResult.OK; this.Close(); };

            this.Controls.AddRange(new Control[] { lbl1, txtSalary, lbl2, txtHours, lbl3, txtActualHours, btnSave });
        }
    }
}
