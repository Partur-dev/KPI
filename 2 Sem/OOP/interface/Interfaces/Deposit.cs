using System;

namespace Interfaces
{
    public abstract class Deposit : IComparable<Deposit>
    {
        public decimal Amount { get; }
        public int Period { get; }

        protected Deposit(decimal depositAmount, int depositPeriod)
        {
            Amount = depositAmount;
            Period = depositPeriod;
        }

        public abstract decimal Income();

        public int CompareTo(Deposit other)
        {
            if (other == null)
            {
                return 1;
            }

            return (Amount + Income()).CompareTo(other.Amount + other.Income());
        }

        public override bool Equals(object obj) =>
            obj is Deposit d && Amount == d.Amount && Period == d.Period;

        public override int GetHashCode() => Amount.GetHashCode() ^ Period.GetHashCode();

        public static bool operator ==(Deposit left, Deposit right) => Equals(left, right);
        public static bool operator !=(Deposit left, Deposit right) => !(left == right);

        public static bool operator <(Deposit left, Deposit right) =>
            left is null ? right is not null : left.CompareTo(right) < 0;
        public static bool operator <=(Deposit left, Deposit right) =>
            left is null || left.CompareTo(right) <= 0;

        public static bool operator >(Deposit left, Deposit right) => !(left <= right);
        public static bool operator >=(Deposit left, Deposit right) => !(left < right);
    }
}