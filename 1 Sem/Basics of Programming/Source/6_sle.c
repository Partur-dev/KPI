#include "utils.h"
#include <math.h>
#include <stdbool.h>
#include <stdlib.h>

#define MIN_SIZE 2
#define MAX_SIZE 9

#define MIN_EPS 1e-15
#define MAX_EPS 0.1

#define MIN_NUM -100
#define MAX_NUM 100

void calc() {
    int size;
    double eps;

    println(INFO, "Enter size of SLE [%i; %i]", MIN_SIZE, MAX_SIZE);
    scan_int(&size, MIN_SIZE, MAX_SIZE);
    println(INFO, "Enter epsilon [%g; %g]", MIN_EPS, MAX_EPS);
    scan_double(&eps, MIN_EPS, MAX_EPS, false);

    double** coefficients = calloc(size, sizeof(double*));
    for (int i = 0; i < size; i++) {
        coefficients[i] = calloc(size, sizeof(double));
    }

    double* free_members = calloc(size, sizeof(double));
    double* xp = calloc(size, sizeof(double));
    double* x = calloc(size, sizeof(double));
    double delta;

    println(INFO, "Enter coefficients of SLE [%i; %i]", MIN_NUM, MAX_NUM);
    println(INFO, "Ensure the convergence condition: |a[i][i]| > ∑|a[i][j]|");

    for (int i = 0; i < size; i++) {
        for (int j = 0; j < size; j++) {
            println(INFO, "A%i%i: ", i + 1, j + 1);
            scan_double(&coefficients[i][j], MIN_NUM, MAX_NUM, false);

            if (i == j && coefficients[i][j] == 0) {
                println(ERROR, "0 isn't allowed on diagonal elements");
                j--;
            }
        }

        double sum = 0;
        for (int j = 0; j < size; j++) {
            if (j != i)
                sum += fabs(coefficients[i][j]);
        }

        if (fabs(coefficients[i][i]) <= sum) {
            println(ERROR, "The convergence condition isn't met");
            i--;
        }
    }

    println(INFO, "Enter free members of SLE [%i; %i]", MIN_NUM, MAX_NUM);

    for (int i = 0; i < size; i++) {
        println(INFO, "B%i: ", i + 1);
        scan_double(&free_members[i], MIN_NUM, MAX_NUM, false);
    }

    for (int i = 0; i < size; i++) {
        xp[i] = free_members[i] / coefficients[i][i];
    }

    do {
        delta = 0;

        for (int i = 0; i < size; i++) {
            double sum = 0;

            for (int j = 0; j < size; j++) {
                if (j != i)
                    sum += coefficients[i][j] * xp[j];
            }

            x[i] = (free_members[i] - sum) / coefficients[i][i];

            double current_delta = fabs(x[i] - xp[i]);
            if (current_delta > delta) {
                delta = current_delta;
            }
        }

        for (int i = 0; i < size; i++) {
            xp[i] = x[i];
        }
    } while (delta > eps);

    for (int i = 0; i < size; i++) {
        println(SUCCESS, "x%i = %g", i + 1, x[i]);
    }

    for (int i = 0; i < size; i++) {
        free(coefficients[i]);
    }

    free(coefficients);
    free(free_members);
    free(xp);
    free(x);
}

int main() {
    do {
        calc();
        println(QUESTION, "Press enter to restart or any other key to exit");
    } while (getch() == KEY_ENTER);

    return 0;
}
