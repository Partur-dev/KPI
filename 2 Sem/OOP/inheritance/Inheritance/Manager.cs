namespace InheritanceTask
{
    public class Manager : Employee
    {
        private readonly int quantity;

        public Manager(string name, decimal salary, int clientAmount) : base(name, salary)
        {
            quantity = clientAmount;
        }

        public override void SetBonus(decimal bonus)
        {
            var newBonus = quantity switch
            {
                > 150 => bonus + 1000,
                > 100 => bonus + 500,
                _ => bonus
            };

            base.SetBonus(newBonus);
        }
    }
}

