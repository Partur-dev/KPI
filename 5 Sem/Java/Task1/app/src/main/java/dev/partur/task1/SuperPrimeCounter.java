package dev.partur.task1;

public class SuperPrimeCounter {
    public static int countSuperPrimes(int n) throws IllegalArgumentException {
        if (n < 1 || n > 1000) {
            throw new IllegalArgumentException("N should be in [1; 1000], got: " + n);
        }

        int count = 0;

        for (int i = 1; i <= n; i++) {
            if (isSuperPrime(i)) {
                count++;
            }
        }

        return count;
    }

    public static boolean isSuperPrime(int number) {
        if (!isPrime(number)) {
            return false;
        }

        int reversed = reverseNumber(number);
        return isPrime(reversed);
    }

    public static boolean isPrime(int number) {
        if (number <= 1) {
            return false;
        }

        int sqrt = (int) Math.sqrt(number);
        for (int i = 2; i <= sqrt; i++) {
            if (number % i == 0) {
                return false;
            }

        }

        return true;
    }

    public static int reverseNumber(int number) {
        int reversed = 0;

        while (number > 0) {
            reversed = reversed * 10 + number % 10;
            number /= 10;
        }

        return reversed;
    }
}
