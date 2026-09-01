package dev.partur.task1;

public class App {
    public static void main(String[] args) {
        final int number = Integer.parseInt(args[0]);
        final int count = SuperPrimeCounter.countSuperPrimes(number);

        System.out.printf("🤙 %d have %d super primes", number, count);
    }
}
