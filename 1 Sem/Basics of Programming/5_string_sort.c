#include "utils.h"
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <termios.h>
#include <time.h>
#include <unistd.h>

#define MIN_LIST_SIZE 2
#define MAX_LIST_SIZE 10
#define MAX_STRING_SIZE 10
#define MIN_STRING_SIZE 1

char random_char() {
    int r = rand() % 62;
    if (r < 26) {
        return 'a' + r;
    } else if (r < 52) {
        return 'A' + (r - 26);
    } else {
        return '0' + (r - 52);
    }
}

void random_string(char* str, int size) {
    for (int i = 0; i < size; i++) {
        str[i] = random_char();
    }
    str[size] = '\0';
}

void sort(char** arr, int num) {
    for (int i = 0; i < num - 1; i++) {
        for (int j = i + 1; j < num; j++) {
            if (strcmp(arr[i], arr[j]) > 0) {
                char* tmp;
                tmp = arr[i];
                arr[i] = arr[j];
                arr[j] = tmp;
            }
        }
    }
}

int main() {
    srand(time(NULL));

    do {
        int size, str_size;

        println(INFO, "Enter size of list [%i, %i]", MIN_LIST_SIZE, MAX_LIST_SIZE);
        scan_int(&size, MIN_LIST_SIZE, MAX_LIST_SIZE);

        println(INFO, "Enter size of string [%i, %i]", MIN_STRING_SIZE, MAX_STRING_SIZE);
        scan_int(&str_size, MIN_STRING_SIZE, MAX_STRING_SIZE);

        char list[size][str_size + 1];
        char* addr[size];

        println(INFO, "Press R to generate random list or any other key to enter manually");

        if (getch() == 'r') {
            println(SUCCESS, "Generated list");
            for (int i = 0; i < size; i++) {
                random_string(list[i], str_size);
                println(TEXT, "%s", list[i]);
                addr[i] = list[i];
            }
        } else {
            for (int i = 0; i < size; i++) {
                println(INFO, "Enter %i element (Alphanumeric)", i + 1);
                scan_string(list[i], str_size);
                addr[i] = list[i];
            }
        }

        println(SUCCESS, "Sorted list");
        sort(addr, size);
        for (int i = 0; i < size; i++) {
            println(TEXT, "%s", addr[i]);
        }

        println(QUESTION, "Press enter to restart or any other key to exit");
    } while (getch() == KEY_ENTER);

    return 0;
}
