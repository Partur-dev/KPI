#include <math.h>
#include <stdbool.h>
#include <stdio.h>

///-----------------------------
///  Terminal utils
///-----------------------------

#define COLOR_RED "\x1b[31m"
#define COLOR_GREEN "\x1b[32m"
#define COLOR_BLUE "\x1b[34m"
#define COLOR_RESET "\x1b[0m"

#define ERROR COLOR_RED "⨯" COLOR_RESET
#define SUCCESS COLOR_GREEN "✔️" COLOR_RESET
#define QUESTION COLOR_BLUE "?" COLOR_RESET

#define print(x, fmt, ...) printf(x " " fmt, ##__VA_ARGS__)
#define println(x, fmt, ...) printf(x " " fmt "\n", ##__VA_ARGS__)

///-----------------------------
///  Declarations
///-----------------------------

typedef struct {
    const double a;
    const double b;
    const double c;
} Triangle;

Triangle NewTriangle(const double a, const double b, const double c);
bool TriangleValidate(const Triangle* t);
double TrianglePerimeter(const Triangle* t);
double TriangleArea(const Triangle* t);
double TriangleHeight(const Triangle* t, const double side);
double TriangleMedian(const Triangle* t, double side);
double TriangleBisector(const Triangle* t, double side);

void clearStdio();
Triangle inputTriangle();
int inputPrecision();

///-----------------------------
///  Main
///-----------------------------

int main() {
    const Triangle t = inputTriangle();
    if (!TriangleValidate(&t)) {
        println(ERROR, "Can't form triangle with provided sides");
        return 0;
    }

    const int prec = inputPrecision();

    const double ha = TriangleHeight(&t, t.a);
    const double hb = TriangleHeight(&t, t.b);
    const double hc = TriangleHeight(&t, t.c);

    const double ma = TriangleMedian(&t, t.a);
    const double mb = TriangleMedian(&t, t.b);
    const double mc = TriangleMedian(&t, t.c);

    const double ba = TriangleBisector(&t, t.a);
    const double bb = TriangleBisector(&t, t.b);
    const double bc = TriangleBisector(&t, t.c);

    printf("\n");
    println(SUCCESS, "Perimeter: %.*lf", prec, TrianglePerimeter(&t));
    println(SUCCESS, "Area: %.*lf", prec, TriangleArea(&t));

    printf("\n");
    println(SUCCESS, "Height(a): %.*lf", prec, ha);
    println(SUCCESS, "Height(b): %.*lf", prec, hb);
    println(SUCCESS, "Height(c): %.*lf", prec, hc);

    printf("\n");
    println(SUCCESS, "Median(a): %.*lf", prec, ma);
    println(SUCCESS, "Median(b): %.*lf", prec, mb);
    println(SUCCESS, "Median(c): %.*lf", prec, mc);

    printf("\n");
    println(SUCCESS, "Bisector(a): %.*lf", prec, ba);
    println(SUCCESS, "Bisector(b): %.*lf", prec, bb);
    println(SUCCESS, "Bisector(c): %.*lf", prec, bc);
}

///-----------------------------
///  Inputs
///-----------------------------

Triangle inputTriangle() {
    double sides[3] = {0, 0, 0};
    bool validSides[3] = {false, false, false};
    const char* text[3] = {"1st", "2nd", "3rd"};

    const int size = (sizeof(sides) / sizeof(sides[0]));
    for (int i = 0; i < size; i++) {
        do {
            fflush(stdin);

            print(QUESTION, "Enter the %s side of the triangle: ", text[i]);
            int read = scanf("%lf", &sides[i]);

            if (read == 0) {
                println(ERROR, "Couldn't read number\n");
            } else {
                char ch = getchar();
                if (ch == ',') {
                    println(ERROR, "Use period instead of comma\n");
                } else if (ch != '\n') {
                    println(ERROR, "Unexpected characters\n");
                } else {
                    if (sides[i] < 0.001 || sides[i] > 99999) {
                        println(ERROR, "All sides must be between 0.001 and 99999\n");
                    } else {
                        validSides[i] = true;
                    }
                }
            }
        } while (validSides[i] == false);
    }

    return NewTriangle(sides[0], sides[1], sides[2]);
}

int inputPrecision() {
    int prec;

    do {
        print(QUESTION, "Enter precision between 0 and 12: ");
        scanf("%i", &prec);
        fflush(stdin);

        if (prec < 0 || prec > 12) {
            println(ERROR, "Precision must be between 0 and 12\n");
        }
    } while (prec < 0 || prec > 12);

    return prec;
}

///-----------------------------
///  Triangle Implementations
///-----------------------------

Triangle NewTriangle(const double a, const double b, const double c) {
    return (Triangle) {a, b, c};
}

bool TriangleValidate(const Triangle* t) {
    return (t->a + t->b) > t->c && (t->a + t->c) > t->b && (t->b + t->c) > t->a;
}

double TrianglePerimeter(const Triangle* t) {
    return t->a + t->b + t->c;
}

double TriangleArea(const Triangle* t) {
    const double hp = TrianglePerimeter(t) / 2;
    return sqrt(hp * (hp - t->a) * (hp - t->b) * (hp - t->c));
}

double TriangleHeight(const Triangle* t, const double side) {
    return 2 * TriangleArea(t) / side;
}

double TriangleMedian(const Triangle* t, double side) {
    if (side == t->a) {
        return sqrt(2 * pow(t->b, 2) + 2 * pow(t->c, 2) - pow(t->a, 2)) / 2;
    } else if (side == t->b) {
        return sqrt(2 * pow(t->a, 2) + 2 * pow(t->c, 2) - pow(t->b, 2)) / 2;
    } else {
        return sqrt(2 * pow(t->a, 2) + 2 * pow(t->b, 2) - pow(t->c, 2)) / 2;
    }
}

double TriangleBisector(const Triangle* t, double side) {
    double p = TrianglePerimeter(t) / 2;

    if (side == t->a) {
        return (2 / (t->b + t->c)) * sqrt(t->b * t->c * p * (p - t->a));
    } else if (side == t->b) {
        return (2 / (t->a + t->c)) * sqrt(t->a * t->c * p * (p - t->b));
    } else {
        return (2 / (t->a + t->b)) * sqrt(t->a * t->b * p * (p - t->c));
    }
}
