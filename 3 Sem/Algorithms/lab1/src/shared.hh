#pragma once

#include <cstdlib>
#include <string>

static const size_t IBUF_SIZE = 1 << 20;
static const size_t OBUF_SIZE = 1 << 20;

struct record {
    std::string key;
    std::string data;

    bool operator<=(const record& other) const {
        return key <= other.key;
    }

    bool operator<(const record& other) const {
        return key < other.key;
    }

    bool operator>=(const record& other) const {
        return key >= other.key;
    }
};

struct fast_writer {
    FILE* f;
    char buf[OBUF_SIZE];
    size_t pos = 0;

    fast_writer(const std::string& path) {
        f = fopen(path.c_str(), "wb");
        if (!f) {
            perror("open");
            exit(1);
        }
    }

    ~fast_writer() {
        flush();
        fclose(f);
    }

    inline void flush() {
        if (pos) {
            fwrite(buf, 1, pos, f);
            pos = 0;
        }
    }

    inline void write_record(const record& r) {
        if (pos > OBUF_SIZE - (6 + 1 + r.data.size() + 1))
            flush();

        for (size_t i = 0; i < 5; ++i) {
            buf[pos++] = (i < r.key.size()) ? r.key[i] : ' ';
        }
        buf[pos++] = '\t';

        for (char c : r.data) {
            buf[pos++] = c;
        }
        buf[pos++] = '\n';
    }
};

struct fast_reader {
    FILE* f;
    char buf[IBUF_SIZE];
    size_t len = 0, pos = 0;

    fast_reader(const std::string& path) {
        f = fopen(path.c_str(), "rb");
        if (!f) {
            perror("open");
            exit(1);
        }
    }

    ~fast_reader() {
        fclose(f);
    }

    inline int read() {
        if (pos >= len) {
            len = fread(buf, 1, IBUF_SIZE, f);
            pos = 0;
            if (!len)
                return EOF;
        }
        return buf[pos++];
    }

    bool next_record(record& out) {
        out.key.clear();
        out.data.clear();
        int c;

        for (int i = 0; i < 5; ++i) {
            c = read();
            if (c == EOF || c == '\n')
                return false;
            out.key += (char)c;
        }

        c = read();
        if (c != '\t')
            return false;

        while ((c = read()) != '\n' && c != EOF) {
            out.data += (char)c;
        }

        return true;
    }
};

class run_reader {
    fast_reader fr;
    record prev;
    record cur;
    bool hasCur;
    bool boundary; // cur -> next run relative to prev. run
public:
    run_reader(const std::string& path) : fr(path), hasCur(false), boundary(false) {
        read_first();
    }

    bool has_value() const {
        return hasCur;
    }

    bool at_boundary() const {
        return boundary;
    }

    const record& peek() const {
        return cur;
    }

    void clear_boundary() {
        boundary = false;
    }

    void consume() {
        if (!hasCur || boundary)
            return; // should not consume past boundary
        prev = cur;
        record x;
        if (fr.next_record(x)) {
            boundary = (x < prev);
            cur = x;
            hasCur = true;
        } else {
            hasCur = false;
        }
    }

private:
    void read_first() {
        record x;
        if (fr.next_record(x)) {
            cur = x;
            hasCur = true;
            boundary = false;
            prev = x;
        }
    }
};
