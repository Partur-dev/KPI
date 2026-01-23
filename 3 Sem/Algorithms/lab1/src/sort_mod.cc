#include "shared.hh"

#include <algorithm>
#include <cstdlib>
#include <iostream>
#include <utility>
#include <vector>

size_t distribute(const std::string& source, const std::string& fa, const std::string& fb) {
    fast_reader in(source);
    fast_writer wA(fa), wB(fb);

    fast_writer* cur = &wA;
    fast_writer* other = &wB;

    record last;
    bool hasLast = false;
    size_t runs = 0;
    record x;

    while (in.next_record(x)) {
        if (!hasLast) {
            runs++;
            cur->write_record(x);
            last = x;
            hasLast = true;
        } else if (x >= last) {
            cur->write_record(x);
            last = x;
        } else {
            std::swap(cur, other);
            runs++;
            cur->write_record(x);
            last = x;
        }
    }

    return runs;
}

void initial_distribute(const std::string& source, const std::string& fa, const std::string& fb) {
    fast_reader in(source);
    fast_writer wA(fa), wB(fb);

    fast_writer* cur = &wA;
    fast_writer* other = &wB;

    std::vector<record> block;
    const size_t blockSize = 1'000'000;
    record x;

    while (in.next_record(x)) {
        block.push_back(x);
        if (block.size() >= blockSize) {
            std::sort(block.begin(), block.end());
            for (const auto& r : block) {
                cur->write_record(r);
            }
            std::swap(cur, other);
            block.clear();
        }
    }

    if (!block.empty()) {
        std::sort(block.begin(), block.end());
        for (const auto& r : block) {
            cur->write_record(r);
        }
    }
}

size_t merge_files(const std::string& f1, const std::string& f2, const std::string& out) {
    run_reader r1(f1), r2(f2);
    fast_writer w(out);
    size_t run_count = 0;

    while (r1.has_value() || r2.has_value()) {
        run_count++;

        // merge one run
        for (;;) {
            bool a = r1.has_value() && !r1.at_boundary();
            bool b = r2.has_value() && !r2.at_boundary();

            if (!a && !b)
                break;

            if (a && b) {
                if (r1.peek() <= r2.peek()) {
                    w.write_record(r1.peek());
                    r1.consume();
                } else {
                    w.write_record(r2.peek());
                    r2.consume();
                }
            } else if (a) {
                w.write_record(r1.peek());
                r1.consume();
            } else {
                w.write_record(r2.peek());
                r2.consume();
            }
        }

        if (r1.at_boundary())
            r1.clear_boundary();
        if (r2.at_boundary())
            r2.clear_boundary();
    }

    return run_count;
}

void natural_merge_sort(
    const std::string& path,
    const std::string& a = "data/a.txt",
    const std::string& b = "data/b.txt"
) {
    initial_distribute(path, a, b);
    size_t merged = merge_files(a, b, path);
    if (merged <= 1) {
        remove(a.c_str());
        remove(b.c_str());
        return;
    }

    while (true) {
        size_t runs = distribute(path, a, b);
        if (runs <= 1)
            break;
        merged = merge_files(a, b, path);
        if (merged <= 1)
            break;
    }

    remove(a.c_str());
    remove(b.c_str());
}

int main(int argc, char** argv) {
    std::ios::sync_with_stdio(false);
    std::cin.tie(nullptr);

    natural_merge_sort("data/c.txt");
}
