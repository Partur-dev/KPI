#include "utils.h"
#include <float.h>
#include <math.h>
#include <stdbool.h>

typedef double (*fn_t)(double x, double y);
typedef double (*method_t)(fn_t fn, double a, double b, double y, double eps);

double first_function(double x, double y);
double second_function(double x, double y);

double bisection(fn_t fn, double a, double b, double y, double eps);
double newton(fn_t fn, double a, double b, double y, double eps);

void solve(method_t method, fn_t fn, double a, double b, double y, double eps);

#define LOWER_BOUND -1e+5
#define UPPER_BOUND 1e+5
#define MINIMAL_PARAMETER -1e+5
#define MAXIMAL_PARAMETER 1e+5
#define MINIMAL_PRECISION 1e-10
#define MAXIMAL_PRECISION 1e-1
#define MIN_FN 1
#define MIN_METHOD 1
#define MAX_FN 2
#define MAX_METHOD 2

int main() {
    double lower_bound = LOWER_BOUND;
    double a, b, y, eps;
    int fn, method;

    do {
        bool valid_bounds = false;
        clear();

        println(QUESTION, "Select function:");
        println(QUESTION, "1. cos(y / x) - 2 * sin(1 / x) + (1 / x)");
        println(QUESTION, "2. sin(log(x)) - cos(log(x)) + y * log(x)");
        scan_int(&fn, MIN_FN, MAX_FN);
        println(QUESTION, "Select method:");
        println(QUESTION, "1. Bisection");
        println(QUESTION, "2. Newton");
        scan_int(&method, MIN_METHOD, MAX_METHOD);

        if (fn == 2)
            lower_bound = 0;

        do {
            println(QUESTION, "Enter A from %g to %g except 0:", lower_bound, UPPER_BOUND);
            scan_double(&a, lower_bound, UPPER_BOUND, true);
            println(QUESTION, "Enter B from %g to %g except 0:", lower_bound, UPPER_BOUND);
            scan_double(&b, lower_bound, UPPER_BOUND, true);

            if (a > b || a == b) {
                println(ERROR, "A must be < B");
            } else {
                valid_bounds = true;
            }
        } while (!valid_bounds);

        println(QUESTION, "Enter Y [%g; %g]:", MINIMAL_PARAMETER, MAXIMAL_PARAMETER);
        scan_double(&y, MINIMAL_PARAMETER, MAXIMAL_PARAMETER, false);
        println(QUESTION, "Enter epsilon [%g; %g]:", MINIMAL_PRECISION, MAXIMAL_PRECISION);
        scan_double(&eps, MINIMAL_PRECISION, MAXIMAL_PRECISION, false);

        solve(
            method == 1 ? bisection : newton,
            fn == 1 ? first_function : second_function,
            a,
            b,
            y,
            eps
        );

        println(QUESTION, "Press enter to restart or any other key to exit");
    } while (getch() == KEY_ENTER);
}

double first_function(double x, double y) {
    if (x == 0)
        return NAN;
    return cos(y / x) - 2 * sin(1 / x) + (1 / x);
}

double second_function(double x, double y) {
    if (x <= 0)
        return NAN;
    return sin(log(x)) - cos(log(x)) + y * log(x);
}

double bisection(fn_t fn, double a, double b, double y, double eps) {
    double x;
    double fn_a = fn(a, y);
    double fn_b = fn(b, y);

    if (isnan(fn_a) || isnan(fn_b)) {
        println(ERROR, "Function returned nan at initial bounds");
        return NAN;
    }

    if (fn_a * fn_b > 0) {
        println(ERROR, "Function has the same sign at initial bounds");
        return NAN;
    }

    while (fabs(b - a) > eps) {
        x = (a + b) / 2.0;
        double fn_x = fn(x, y);

        if (isnan(fn_x)) {
            println(ERROR, "Function returns nan at x = %lf", x);
            return NAN;
        }

        if (fn_a * fn_x > 0) {
            a = x;
            fn_a = fn_x;
        } else {
            b = x;
            fn_b = fn_x;
        }
    }

    return x;
}

double newton(fn_t function, double a, double b, double y, double eps) {
    double x = b;
    double delta;

    do {
        double fn_x = function(x, y);
        double fn_x_eps = function(x + eps, y);
        double fn_x_derivative = (fn_x_eps - fn_x) / eps;

        if (fabs(fn_x_derivative) < DBL_EPSILON) {
            println(ERROR, "Derivative is too close to 0 at x = %lf", x);
            return NAN;
        }

        delta = fn_x / fn_x_derivative;
        x -= delta;

        if (isnan(fn_x) || isnan(fn_x_derivative)) {
            println(ERROR, "Function or derivative returns nan at x = %lf", x);
            return NAN;
        }
    } while (fabs(delta) > eps);

    return x;
}

void solve(method_t method, fn_t fn, double a, double b, double y, double eps) {
    println(TEXT, "");
    println(INFO, "a = %lf", a);
    println(INFO, "b = %lf", b);
    println(INFO, "y = %lf", y);

    double result = method(fn, a, b, y, eps);
    bool in_bounds = result >= a && result <= b;

    if (isnan(result) || !in_bounds) {
        println(ERROR, "Could not find x");
    } else {
        println(SUCCESS, "x = %lf", result);
    }

    println(TEXT, "");
}
