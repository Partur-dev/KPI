namespace Aggregation
{
    public class LongDeposit : Deposit
    {
        public LongDeposit(decimal amount, int period)
            : base(amount, period)
        {
        }

        public override decimal Income()
        {
            decimal currentSum = Amount;
            for (int month = 6; month < Period; month++)
            {
                currentSum *= 1.15m;
            }
            return currentSum - Amount;
        }
    }
}