#include <stdio.h>

typedef struct {
    const int arabic;
    const char* roman;
} RomanNumbers;

const RomanNumbers roman_map[] = {
    {1000, "M"},
    {900, "CM"},
    {500, "D"},
    {400, "CD"},
    {100, "C"},
    {90, "XC"},
    {50, "L"},
    {40, "XL"},
    {10, "X"},
    {9, "IX"},
    {5, "V"},
    {4, "IV"},
    {1, "I"},
};

void to_roman(long arabic) {
    int map_size = sizeof(roman_map) / sizeof(roman_map[0]);

    for (int i = 0; i < map_size; i++) {
        while (arabic >= roman_map[i].arabic) {
            printf("%s", roman_map[i].roman);
            arabic -= roman_map[i].arabic;
        }
    }

    printf("\n");
}

int main() {
    printf("Enter number: ");

    long n;
    while (1) {
        scanf("%li", &n);

        if (n <= 0) {
            printf("Number should be >= 0\n");
        } else {
            break;
        }
    }

    to_roman(n);
    return 0;
}
