using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

namespace Interfaces
{
    public class Client : IEnumerable<Deposit>
    {
        private readonly Deposit[] deposits;

        public Client()
        {
            deposits = new Deposit[10];
        }

        public bool AddDeposit(Deposit deposit)
        {
            int index = Array.FindIndex(deposits, d => d == null);
            if (index == -1)
            {
                return false;
            }

            deposits[index] = deposit;
            return true;
        }

        public decimal TotalIncome()
        {
            return deposits.Where(deposit => deposit != null)
                           .Select(deposit => deposit.Income())
                           .Sum();
        }

        public decimal MaxIncome()
        {
            return deposits.Where(deposit => deposit != null)
                           .Select(deposit => deposit.Income())
                           .DefaultIfEmpty(0)
                           .Max();
        }

        public decimal GetIncomeByNumber(int number)
        {
            var deposit = deposits[number - 1];
            return deposit == null ? 0 : deposit.Income();
        }

        public void SortDeposits()
        {
            deposits.OrderByDescending(deposit => deposit)
                    .ToArray()
                    .CopyTo(deposits, 0);
        }

        public int CountPossibleToProlongDeposit()
        {
            return deposits.Count(deposit => deposit is IProlongable p && p.CanToProlong());
        }

        public IEnumerator<Deposit> GetEnumerator()
        {
            foreach (var deposit in deposits)
            {
                if (deposit != null)
                {
                    yield return deposit;
                }
            }
        }

        IEnumerator IEnumerable.GetEnumerator()
        {
            return GetEnumerator();
        }
    }
}