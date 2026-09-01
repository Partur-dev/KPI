package dev.partur.task1;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;
import org.junit.jupiter.params.provider.ValueSource;

import static org.junit.jupiter.api.Assertions.*;

class SuperPrimeCounterTest {
    @Test
    @DisplayName("Should correctly reverse the number")
    void testReverseNumber() {
        assertEquals(1, SuperPrimeCounter.reverseNumber(1));
        assertEquals(31, SuperPrimeCounter.reverseNumber(13));
        assertEquals(7, SuperPrimeCounter.reverseNumber(70));
        assertEquals(991, SuperPrimeCounter.reverseNumber(199));
    }

    @ParameterizedTest(name = "{0} should be super prime")
    @ValueSource(ints = { 2, 3, 5, 7, 11, 13, 17, 31, 37, 71, 73, 79, 97, 101, 107, 701, 991 })
    void testIsSuperPrimeTrue(int prime) {
        assertTrue(SuperPrimeCounter.isSuperPrime(prime));
    }

    @ParameterizedTest(name = "{0} should NOT be super prime")
    @ValueSource(ints = { 1, 4, 6, 8, 9, 19, 23, 29, 61, 83 })
    void testIsSuperPrimeFalse(int number) {
        assertFalse(SuperPrimeCounter.isSuperPrime(number));
    }

    @ParameterizedTest(name = "Expected {1} for n={0}")
    @CsvSource({
            "1, 0", // None
            "2, 1", // [2]
            "10, 4", // [2, 3, 5, 7]
            "13, 6", // [2, 3, 5, 7, 11, 13]
            "100, 13", // [2, 3, 5, 7, 11, 13, 17, 31, 37, 71, 73, 79, 97]
            "1000, 56" // All super primes up to 1000
    })
    void testCountSuperPrimes(int n, int expectedCount) {
        assertEquals(expectedCount, SuperPrimeCounter.countSuperPrimes(n));
    }

    @Test
    @DisplayName("Should throw IllegalArgumentException for values not in [1; 1000]")
    void testBoundaryValidation() {
        assertThrows(IllegalArgumentException.class, () -> SuperPrimeCounter.countSuperPrimes(0));
        assertThrows(IllegalArgumentException.class, () -> SuperPrimeCounter.countSuperPrimes(-10));
        assertThrows(IllegalArgumentException.class, () -> SuperPrimeCounter.countSuperPrimes(1001));
    }
}
