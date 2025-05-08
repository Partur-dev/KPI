using System.Linq;


namespace InheritanceTask
{
    public class Company
    {
        private readonly Employee[] employees;

        public Company(Employee[] employees)
        {
            this.employees = employees;
        }

        public void GiveEverybodyBonus(decimal companyBonus)
        {
            foreach (var employee in employees)
            {
                employee.SetBonus(companyBonus);
            }
        }

        public decimal TotalToPay()
        {
            return employees.Sum(employee => employee.ToPay());
        }

        public string NameMaxSalary()
        {
            return employees
                .OrderByDescending(employee => employee.ToPay())
                .First().Name;
        }
    }
}
