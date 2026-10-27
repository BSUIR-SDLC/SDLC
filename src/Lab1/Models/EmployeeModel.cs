using System;

namespace EmployeeValueMVC.Models
{
    public class EmployeeModel
    {
        public decimal Salary { get; private set; }
        public double WorkingHours { get; private set; }
        public double ActualHours { get; private set; }

        public decimal ClickCost { get; private set; }
        public decimal CodeLineCost { get; private set; }
        public decimal BreathCost { get; private set; }

        public event Action? ModelChanged;

        public void SetData(decimal salary, double workingHours, double actualHours)
        {
            if (salary < 0 || workingHours <= 0 || actualHours <= 0)
                throw new ArgumentException("Данные должны быть положительными числами!");

            if (actualHours > workingHours)
                throw new ArgumentException("Фактические часы не могут превышать плановые!");

            Salary = salary;
            WorkingHours = workingHours;
            ActualHours = actualHours;

            CalculateCosts();

            ModelChanged?.Invoke();
        }

        private void CalculateCosts()
        {
            double totalClicks = ActualHours * 750;
            double totalLines = ActualHours * 200;
            double totalBreaths = ActualHours * 1320;

            ClickCost = totalClicks > 0 ? Salary / (decimal)totalClicks : 0;
            CodeLineCost = totalLines > 0 ? Salary / (decimal)totalLines : 0;
            BreathCost = totalBreaths > 0 ? Salary / (decimal)totalBreaths : 0;
        }
    }
}
