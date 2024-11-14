#include <ctype.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
    #include <conio.h>
#else
    #include <termios.h>
    #include <unistd.h>
#endif

#define COLOR_RED "\x1b[31m"
#define COLOR_GREEN "\x1b[32m"
#define COLOR_BLUE "\x1b[34m"
#define COLOR_RESET "\x1b[0m"

#define TEXT ""
#define INFO COLOR_BLUE "ℹ" COLOR_RESET
#define ERROR COLOR_RED "⨯" COLOR_RESET
#define SUCCESS COLOR_GREEN "✔️" COLOR_RESET
#define QUESTION COLOR_BLUE "?" COLOR_RESET

#define KEY_ENTER 10

#define print(x, fmt, ...) printf(x " " fmt, ##__VA_ARGS__)
#define println(x, fmt, ...) printf(x " " fmt "\n", ##__VA_ARGS__)

#ifndef _WIN32
int getch() {
    struct termios oldt, newt;
    tcgetattr(STDIN_FILENO, &oldt);
    newt = oldt;
    newt.c_lflag &= ~(ICANON | ECHO);
    tcsetattr(STDIN_FILENO, TCSANOW, &newt);
    int c = getchar();
    tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
    return c;
}
#endif

void scan_int(int* value, int min, int max) {
    bool valid = false;

    do {
        print(QUESTION, "");
        int res = scanf("%i", value);
        if (res != 1 || getchar() != '\n') {
            println(ERROR, "Invalid input");
            fflush(stdin);
        } else if (*value < min || *value > max) {
            println(ERROR, "Entered number is out of bounds");
        } else {
            valid = true;
        }
    } while (!valid);
}

void scan_double(double* value, double min, double max, bool exclude_zero) {
    bool valid = false;

    do {
        print(QUESTION, "");
        int res = scanf("%lf", value);
        if (res != 1 || getchar() != '\n') {
            println(ERROR, "Invalid input");
            fflush(stdin);
        } else if (exclude_zero && *value == 0) {
            println(ERROR, "Entered number is equal to 0");
        } else if (*value < min || *value > max) {
            println(ERROR, "Entered number is out of bounds");
        } else {
            valid = true;
        }
    } while (!valid);
}

bool is_alphanum(const char* str) {
    for (int i = 0; str[i] != '\0'; i++) {
        if (!isalpha(str[i]) && !isdigit(str[i])) {
            return false;
        }
    }

    return true;
}

void scan_string(char* value, unsigned int max) {
    bool valid = false;

    do {
        print(QUESTION, "");
        int res = scanf("%s", value);
        if (res != 1 || getchar() != '\n') {
            println(ERROR, "Invalid input");
            fflush(stdin);
        } else if (strlen(value) > max) {
            println(ERROR, "Entered string is too big");
        } else if (!is_alphanum(value)) {
            println(ERROR, "Only english letters and numbers are allowed");
        } else {
            valid = true;
        }
    } while (!valid);
}

void clear() {
#ifdef _WIN32
    system("cls");
#else
    system("clear");
#endif
}
