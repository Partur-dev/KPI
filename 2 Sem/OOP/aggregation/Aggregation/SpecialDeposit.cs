namespace Aggregation
{
    public class SpecialDeposit : Deposit
    {
        public SpecialDeposit(decimal amount, int period)
            : base(amount, period)
        {
        }

        public override decimal Income()
        {
            decimal currentSum = Amount;
            for (int month = 0; month < Period; month++)
            {
                currentSum = currentSum * (month + 101) / 100;
            }

            return currentSum - Amount;
        }
    }
}
