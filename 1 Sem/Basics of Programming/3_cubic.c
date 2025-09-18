#include <complex.h>
#include <math.h>
#include <stdbool.h>
#include <stdio.h>
#include <termios.h>
#include <unistd.h>

#define COLOR_RED "\x1b[31m"
#define COLOR_GREEN "\x1b[32m"
#define COLOR_BLUE "\x1b[34m"
#define COLOR_RESET "\x1b[0m"

#define INFO COLOR_BLUE "ℹ" COLOR_RESET
#define ERROR COLOR_RED "⨯" COLOR_RESET
#define SUCCESS COLOR_GREEN "✔️" COLOR_RESET
#define QUESTION COLOR_BLUE "?" COLOR_RESET

#define print(x, fmt, ...) printf(x " " fmt, ##__VA_ARGS__)
#define println(x, fmt, ...) printf(x " " fmt "\n", ##__VA_ARGS__)

#define SCAN_DOUBLE_MIN -10000
#define SCAN_DOUBLE_MAX 10000

double scan_double(const char* str) {
    double value;
    bool valid = false;

    do {
        print(QUESTION, "%s [%i; %i]: ", str, SCAN_DOUBLE_MIN, SCAN_DOUBLE_MAX);
        int res = scanf("%lf", &value);
        if (res != 1 || getchar() != '\n') {
            println(ERROR, "Invalid input");
            fflush(stdin);
        } else if (value < SCAN_DOUBLE_MIN || value > SCAN_DOUBLE_MAX) {
            println(ERROR, "Entered number is out of bounds");
        } else {
            valid = true;
        }
    } while (!valid);

    return value;
}

void calc() {
    println(INFO, "Enter coefficients for cubic equality x^3 + ax^2 + bx + c = 0");
    double a = scan_double("a");
    double b = scan_double("b");
    double c = scan_double("c");

    double p = b - (pow(a, 2) / 3);
    double q = (2 * pow(a, 3) / 27) - (a * b / 3) + c;
    double d = pow(p, 3) / 27 + pow(q, 2) / 4;

    if (d > 0) {
        double y = -q / 2 + sqrt(d);
        double u = (y > 0) ? (pow(y, 1 / 3.f)) : (pow(fabs(y), 1 / 3.f) * -1);
        double v = -p / (3 * u);

        if (v == 0) {
            println(ERROR, "V is zero, equality isn't solvable");
            return;
        }

        double y1 = u + v;
        double real = (-(u + v) / 2.f) - a / 3.f;
        double im = sqrt(3.0) * (u - v) / 2.f;

        double x1 = y1 - (a / 3);

        println(SUCCESS, "x1: %.6f", x1);
        println(SUCCESS, "x2: %.6f+%.6fi", real, im);
        println(SUCCESS, "x3: %.6f-%.6fi", real, im);
    } else if (d == 0) {
        if (p == 0) {
            println(ERROR, "P is zero, equality isn't solvable");
            return;
        }

        double y1 = 3 * q / p;
        double y2 = -(3 * q) / (2 * p);

        println(SUCCESS, "x1: %.6f", y1 - a / 3.f);
        println(SUCCESS, "x2: %.6f", y2 - a / 3.f);
        println(SUCCESS, "x3: %.6f", y2 - a / 3.f);
    } else {
        double rs = -pow(p, 3) / 27;

        if (rs < 0) {
            println(ERROR, "RS is negative, equality isn't solvable");
        }

        double r = sqrt(rs);
        double fi = acos(-q / (2 * r));

        double y1 = 2 * fabs(cbrt(r)) * cos(fi / 3);
        double y2 = 2 * fabs(cbrt(r)) * cos((fi + 2 * M_PI) / 3);
        double y3 = 2 * fabs(cbrt(r)) * cos((fi + 4 * M_PI) / 3);

        println(SUCCESS, "x1: %.6f", y1 - a / 3.f);
        println(SUCCESS, "x2: %.6f", y2 - a / 3.f);
        println(SUCCESS, "x3: %.6f", y3 - a / 3.f);
    }
}

int main() {
    struct termios oldt, newt;
    tcgetattr(STDIN_FILENO, &oldt);
    newt = oldt;
    newt.c_lflag &= ~(ICANON | ECHO);

    do {
        tcsetattr(STDIN_FILENO, TCSANOW, &oldt);
        calc();

        tcsetattr(STDIN_FILENO, TCSANOW, &newt);
        printf("Press ENTER to restart or any other key to exit\n");
    } while (getchar() == 10);
}
