namespace Aggregation
{
    public abstract class Deposit
    {
        public decimal Amount { get; }
        public int Period { get; }

        protected Deposit(decimal depositAmount, int depositPeriod)
        {
            Amount = depositAmount;
            Period = depositPeriod;
        }

        public abstract decimal Income();
    }
}