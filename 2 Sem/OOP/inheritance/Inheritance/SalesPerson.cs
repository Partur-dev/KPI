namespace InheritanceTask
{
    public class SalesPerson : Employee
    {
        private readonly int percent;

        public SalesPerson(string name, decimal salary, int percent) : base(name, salary)
        {
            this.percent = percent;
        }

        public override void SetBonus(decimal bonus)
        {
            var newBonus = percent switch
            {
                > 200 => bonus * 3,
                > 100 => bonus * 2,
                _ => bonus
            };

            base.SetBonus(newBonus);
        }
    }
}
