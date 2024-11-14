#include "utils.h"
#include <math.h>
#include <stdbool.h>
#include <stdlib.h>
#include <time.h>

#define ROW_ELEMENTS 4
#define PREC 4
#define RANGE 10000
#define MIN_SIZE 2
#define MAX_SIZE 24

void sort(double* ar, int num) {
    for (int i = 0; i < num - 1; i++) {
        for (int j = i + 1; j < num; j++) {
            if (ar[i] > ar[j]) {
                double t = ar[i];
                ar[i] = ar[j];
                ar[j] = t;
            }
        }
    }
}

int random_num(int range_max) {
    return (rand() % (range_max + 1));
}

int main() {
    srand(time(NULL));

    do {
        println(INFO, "Enter size of array [%i; %i]", MIN_SIZE, MAX_SIZE);
        int size;
        scan_int(&size, MIN_SIZE, MAX_SIZE);
        double arr[size];

        println(QUESTION, "Press R to generate random numbers or any other key to enter manually");
        bool randNumbers = getch() == 'r';

        if (randNumbers) {
            println(SUCCESS, "Generated array");
            for (int i = 0; i < size; i++) {
                arr[i] = pow(-1, random_num(2)) * random_num(RANGE + 1)
                         + random_num(RANGE + 1) / (pow(10, PREC));
                print(
                    TEXT,
                    "%.*lf%c",
                    PREC,
                    arr[i],
                    i % ROW_ELEMENTS == ROW_ELEMENTS - 1 ? '\n' : '\t'
                );
            }
        } else {
            for (int i = 0; i < size; i++) {
                println(INFO, "Enter %i element [%i; %i]", i + 1, -RANGE, RANGE);
                scan_double(&arr[i], -RANGE, RANGE, false);
            }
        }
        println(TEXT, "");

        println(SUCCESS, "Sorted array");
        sort(arr, size);
        for (int i = 0; i < size; i++) {
            print(
                TEXT,
                "%.*lf%c",
                PREC,
                arr[i],
                i % ROW_ELEMENTS == ROW_ELEMENTS - 1 ? '\n' : '\t'
            );
        }

        println(TEXT, "");
        println(QUESTION, "Press enter to restart or any key to exit");
    } while (getch() == KEY_ENTER);

    return 0;
}
