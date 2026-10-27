using System;
using System.Drawing;
using System.Windows.Forms;
using EmployeeValueMVC.Models;
using EmployeeValueMVC.Controllers;

namespace EmployeeValueMVC.Views
{
    public class MainForm : Form
    {
        private readonly EmployeeModel _model;
        private readonly EmployeeController _controller;

        private Panel panelResults;
        private Label lblClickCost;
        private Label lblCodeLineCost;
        private Label lblBreathCost;
        private Button btnOpenInput;

        private string _lastSalary = "0";
        private string _lastHours = "0";
        private string _lastActualHours = "0";

        public MainForm()
        {
            this.Text = "Калькулятор сотрудника (Вариант 25)";
            this.Size = new Size(420, 360);
            this.MinimumSize = new Size(420, 360);
            this.StartPosition = FormStartPosition.CenterScreen;
            this.BackColor = Color.FromArgb(245, 246, 250);

            Label lblHeader = new Label()
            {
                Text = "Стоимость действий сотрудника",
                Font = new Font("Segoe UI", 14, FontStyle.Bold),
                ForeColor = Color.FromArgb(47, 53, 66),
                Location = new Point(20, 15),
                Size = new Size(360, 30),
                TextAlign = ContentAlignment.MiddleLeft
            };

            panelResults = new Panel()
            {
                Location = new Point(20, 55),
                Size = new Size(364, 160),
                BackColor = Color.White,
                BorderStyle = BorderStyle.FixedSingle
            };

            lblClickCost = new Label() 
            { 
                Text = "[>] Стоимость клика: --", 
                Location = new Point(15, 20), 
                Size = new Size(330, 30), 
                Font = new Font("Segoe UI", 11, FontStyle.Regular),
                ForeColor = Color.FromArgb(116, 125, 140)
            };

            lblCodeLineCost = new Label() 
            { 
                Text = "[>] Стоимость строки кода: --", 
                Location = new Point(15, 65), 
                Size = new Size(330, 30), 
                Font = new Font("Segoe UI", 11, FontStyle.Regular),
                ForeColor = Color.FromArgb(116, 125, 140)
            };

            lblBreathCost = new Label() 
            { 
                Text = "[>] Стоимость вздоха: --", 
                Location = new Point(15, 110), 
                Size = new Size(330, 30), 
                Font = new Font("Segoe UI", 11, FontStyle.Regular),
                ForeColor = Color.FromArgb(116, 125, 140)
            };

            panelResults.Controls.AddRange(new Control[] { lblClickCost, lblCodeLineCost, lblBreathCost });

            btnOpenInput = new Button() 
            { 
                Text = "Ввести данные", 
                Size = new Size(180, 45),
                Font = new Font("Segoe UI", 11, FontStyle.Bold),
                BackColor = Color.FromArgb(74, 144, 226), 
                ForeColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                Cursor = Cursors.Hand
            };
            btnOpenInput.FlatAppearance.BorderSize = 0; 
            btnOpenInput.Click += btnOpenInput_Click;

            btnOpenInput.Location = new Point((this.ClientSize.Width - btnOpenInput.Width) / 2, 245);

            this.Controls.AddRange(new Control[] { lblHeader, panelResults, btnOpenInput });

            _model = new EmployeeModel();
            _controller = new EmployeeController(_model);

            _model.ModelChanged += UpdateView;
        }

        private void btnOpenInput_Click(object? sender, EventArgs? e)
        {
            using (InputForm inputForm = new InputForm(_lastSalary, _lastHours, _lastActualHours))
            {
                if (inputForm.ShowDialog() == DialogResult.OK)
                {
                    bool success = _controller.ProcessInput(inputForm.SalaryInput, inputForm.HoursInput, inputForm.ActualHoursInput);
                    if (success)
                    {
                        _lastSalary = inputForm.SalaryInput;
                        _lastHours = inputForm.HoursInput;
                        _lastActualHours = inputForm.ActualHoursInput;
                    }
                }
            }
        }

        private void UpdateView()
        {
            lblClickCost.ForeColor = Color.FromArgb(46, 204, 113); 
            if (_model.ClickCost > 999999999)
                lblClickCost.Text = $"► Стоимость клика: {_model.ClickCost:E4} руб.";
            else
                lblClickCost.Text = $"► Стоимость клика: {_model.ClickCost:F4} руб.";

            lblCodeLineCost.ForeColor = Color.FromArgb(155, 89, 182); 
            if (_model.CodeLineCost > 999999999)
                lblCodeLineCost.Text = $"► Стоимость строки: {_model.CodeLineCost:E4} руб.";
            else
                lblCodeLineCost.Text = $"► Стоимость строки: {_model.CodeLineCost:F4} руб.";

            lblBreathCost.ForeColor = Color.FromArgb(230, 126, 34); 
            if (_model.BreathCost > 999999999)
                lblBreathCost.Text = $"► Стоимость вздоха: {_model.BreathCost:E4} руб.";
            else
                lblBreathCost.Text = $"► Стоимость вздоха: {_model.BreathCost:F4} руб.";
        }
    }
}
