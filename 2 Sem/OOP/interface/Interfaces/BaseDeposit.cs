using System;

namespace Interfaces
{
    public class BaseDeposit : Deposit
    {
        public BaseDeposit(decimal amount, int period) : base(amount, period)
        {
        }

        public override decimal Income()
        {
            decimal currentSum = Amount;
            for (int month = 0; month < Period; month++)
            {
                currentSum = Math.Round(currentSum * 1.05m, 2);
            }
            return currentSum - Amount;
        }
    }
}