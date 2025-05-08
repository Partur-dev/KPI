using System;
using System.Linq;

namespace Functions
{
    public enum SortOrder { Ascending, Descending }
    public static class DemoFunction
    {
        public static bool IsSorted(int[] array, SortOrder order)
        {
            var newArr = order == SortOrder.Ascending ? array.OrderBy(x => x) : array.OrderByDescending(x => x);
            return array.SequenceEqual(newArr);
        }

        public static void Transform(int[] array, SortOrder order)
        {
            if (array == null)
            {
                throw new ArgumentNullException(nameof(array));
            }

            if (!IsSorted(array, order))
            {
                return;
            }

            for (int i = 0; i < array.Length; i++)
            {
                array[i] += i;
            }
        }

        public static double MultArithmeticElements(double a, double t, int n)
        {
            if (n < 1)
            {
                throw new ArgumentOutOfRangeException(nameof(n), "n must be greater than 0");
            }

            double sum = 1;
            double term = a;

            for (int i = 0; i < n; i++)
            {
                sum *= term;
                term += t;
            }

            return sum;
        }

        public static double SumGeometricElements(double a, double t, double alim)
        {
            if (t <= 0 || t >= 1)
            {
                throw new ArgumentOutOfRangeException(nameof(t), "t must be in the range (0, 1)");
            }

            double sum = 0;
            double term = a;

            while (term > alim)
            {
                sum += term;
                term *= t;
            }

            return sum;
        }
    }
}
