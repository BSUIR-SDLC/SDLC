using System;
using System.Windows.Forms;
using EmployeeValueMVC.Models;

namespace EmployeeValueMVC.Controllers
{
    public class EmployeeController
    {
        private readonly EmployeeModel _model;

        public EmployeeController(EmployeeModel model)
        {
            _model = model;
        }

        public bool ProcessInput(string salaryStr, string hoursStr, string actualHoursStr)
        {
            try
            {
                if (!decimal.TryParse(salaryStr, out decimal salary) ||
                    !double.TryParse(hoursStr, out double hours) ||
                    !double.TryParse(actualHoursStr, out double actualHours))
                {
                    MessageBox.Show("Ошибка: Введены некорректные символы!", "Ошибка ввода", MessageBoxButtons.OK, MessageBoxIcon.Error);
                    return false;
                }

                _model.SetData(salary, hours, actualHours);
                return true;
            }
            catch (Exception ex)
            {
                MessageBox.Show($"Ошибка: {ex.Message}", "Ошибка валидации", MessageBoxButtons.OK, MessageBoxIcon.Error);
                return false;
            }
        }
    }
}
