#include "shared.hh"

void generate(const std::string& path, size_t n) {
    fast_writer w(path);
    for (size_t i = 0; i < n; i++) {
        record r;

        r.key.clear();
        for (int j = 0; j < 5; ++j) {
            r.key += 'A' + (rand() % 26);
        }

        std::string str;
        for (int j = 0; j < rand() % 45 + 1; ++j) {
            str += 'a' + (rand() % 26);
        }

        // E.164 compliant phone: + followed by 7-15 digits
        int digit_count = 7 + (rand() % 9);
        std::string phone = "+";

        for (int j = 0; j < digit_count; ++j) {
            phone += '0' + (rand() % 10);
        }

        r.data = str + "\t" + phone;
        w.write_record(r);
    }
}

int main(int argc, char** argv) {
    srand(0);

    size_t n = 16'000'000;
    if (argc > 1) {
        n = std::stoull(argv[1]);
    }

    generate("data/c.txt", n);
}
