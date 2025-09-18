#include "utils.h"
#include <math.h>
#include <stdbool.h>

#define MIN_L 1e-6
#define MAX_L 1e+6
#define MIN_C 1e-6
#define MAX_C 1e+6
#define MIN_R 1e-6
#define MAX_R 1e+6
#define MIN_F 1
#define MAX_F 1000

typedef struct complex {
    double real;
    double imag;
} complex;

complex divide(complex a, complex b) {
    // a - a.real
    // b - a.imag
    // c - b.real
    // d - b.imag

    complex result;
    double denominator = b.real * b.real + b.imag * b.imag;
    result.real = (a.real * b.real + a.imag * b.imag) / denominator;
    result.imag = (a.imag * b.real - a.real * b.imag) / denominator;
    return result;
}

void print_complex(complex c) {
    if (c.imag >= 0)
        printf("%g + %gi\n", c.real, c.imag);
    else
        printf("%g - %gi\n", c.real, -c.imag);
}

complex calc(int variant, double f, double l, double c, double r1, double r2) {
    double w = 2 * M_PI * f;
    complex numerator, denominator;

    switch (variant) {
    case 1:
        numerator.real = l / c;
        numerator.imag = -r1 / (w * c);
        denominator.real = r1;
        denominator.imag = (w * l - 1 / (w * c));
        break;
    case 2:
        numerator.real = l / c;
        numerator.imag = r1 / (w * c);
        denominator.real = r1;
        denominator.imag = (w * l - 1 / (w * c));
        break;
    case 3:
        numerator.real = r1 * r2;
        numerator.imag = r1 * (w * l - 1 / (w * c));
        denominator.real = r1 + r2;
        denominator.imag = w * l - 1 / (w * c);
        break;
    case 4:
        numerator.real = r1 * r2 + l / c;
        numerator.imag = w * l * r1 - r2 / (w * c);
        denominator.real = r1 + r2;
        denominator.imag = w * l - 1 / (w * c);
        break;
    }

    return divide(numerator, denominator);
}

void print_step(double l, double c, double r1, double r2, int variant, int f, int* i) {
    *i += 1;
    complex result = calc(variant, f, l, c, r1, r2);
    print(SUCCESS, "f%i = %i\tz = ", *i, f);
    print_complex(result);
}

double calculate_resonant_frequency(double l, double c) {
    return 1 / (2 * M_PI * sqrt(l * c));
}

int main() {
    do {
        double l, c, r1, r2;
        int variant, fmin, fmax, step;

        println(INFO, "Select circuit { 1, 2, 3, 4 }");
        scan_int(&variant, 1, 4);

        println(INFO, "Enter L(mHn) [%g; %g]", MIN_L, MAX_L);
        scan_double(&l, MIN_L, MAX_L, false);

        println(INFO, "Enter C(mcF) [%g; %g]", MIN_C, MAX_C);
        scan_double(&c, MIN_C, MAX_C, false);

        if (variant <= 2) {
            println(INFO, "Enter R(Ohm) [%g; %g]", MIN_R, MAX_R);
            scan_double(&r1, MIN_R, MAX_R, false);
        } else {
            println(INFO, "Enter R1(Ohm) [%g; %g]", MIN_R, MAX_R);
            scan_double(&r1, MIN_R, MAX_R, false);

            println(INFO, "Enter R2(Ohm) [%g; %g]", MIN_R, MAX_R);
            scan_double(&r2, MIN_R, MAX_R, false);
        }

        do {
            println(INFO, "Enter F_min [%i; %i]", MIN_F, MAX_F);
            scan_int(&fmin, MIN_F, MAX_F);

            println(INFO, "Enter F_max [%i; %i]", MIN_F, MAX_F);
            scan_int(&fmax, MIN_F, MAX_F);

            if (fmin > fmax) {
                println(ERROR, "F_min must be less or equal to F_max");
            }
        } while (fmin > fmax);

        println(INFO, "Enter step [%i; %i]", MIN_F, MAX_F);
        scan_int(&step, MIN_F, MAX_F);

        double resonant_frequency = calculate_resonant_frequency(l, c);
        println(SUCCESS, "Resonant frequency: %g Hz", resonant_frequency);

        int i = 0;
        for (int f = fmin; f <= fmax; f += step) {
            print_step(l, c, r1, r2, variant, f, &i);
        }

        if ((fmax - fmin) % step != 0) {
            print_step(l, c, r1, r2, variant, fmax, &i);
        }

        println(QUESTION, "Press enter to restart or any other key to exit");
    } while (getch() == KEY_ENTER);
}
