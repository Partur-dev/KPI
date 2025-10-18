#include <algorithm>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <queue>
#include <string>
#include <vector>

// priority_queue - log n
// sort - n log n

const size_t MAX_MEMORY = 100 * 1024 * 1024; // 100 MB for buffer
const std::string TMP_PREFIX = "chunk_";

struct Record {
    std::string key;
    std::string line;

    bool operator<(const Record& o) const {
        return key < o.key;
    }
};

std::string get_key(const std::string& line) {
    return line.substr(0, 5);
}

int main(int argc, char* argv[]) {
    std::string infile = "data/c.txt", outfile = "data/c.txt";
    std::ifstream in(infile);
    if (!in) {
        std::cerr << "Cannot open input\n";
        return 1;
    }

    std::vector<std::string> chunk_files;
    std::vector<Record> buffer;
    buffer.reserve(1'000'000);

    size_t current_mem = 0, chunk_idx = 0;
    std::string line;
    while (getline(in, line)) {
        current_mem += line.size() + sizeof(Record);
        buffer.push_back({get_key(line), line});
        if (current_mem >= MAX_MEMORY) {
            sort(buffer.begin(), buffer.end());
            std::string chunk_name = TMP_PREFIX + std::to_string(chunk_idx++) + ".txt";
            std::ofstream out(chunk_name);
            for (auto& r : buffer)
                out << r.line << '\n';
            out.close();
            chunk_files.push_back(chunk_name);
            buffer.clear();
            current_mem = 0;
        }
    }

    if (!buffer.empty()) {
        sort(buffer.begin(), buffer.end());
        std::string chunk_name = TMP_PREFIX + std::to_string(chunk_idx++) + ".txt";
        std::ofstream out(chunk_name);
        for (auto& r : buffer)
            out << r.line << '\n';
        out.close();
        chunk_files.push_back(chunk_name);
    }
    in.close();

    // --- Merge Phase ---
    struct Node {
        std::string key;
        std::string line;
        int file_id;

        bool operator>(const Node& o) const {
            return key > o.key;
        }
    };

    std::priority_queue<Node, std::vector<Node>, std::greater<Node>> pq;
    std::vector<std::ifstream> files(chunk_files.size());
    for (int i = 0; i < (int)chunk_files.size(); ++i) {
        files[i].open(chunk_files[i]);
        if (getline(files[i], line))
            pq.push({get_key(line), line, i});
    }

    std::ofstream out(outfile);
    while (!pq.empty()) {
        auto cur = pq.top();
        pq.pop();
        out << cur.line << '\n';
        if (getline(files[cur.file_id], line))
            pq.push({get_key(line), line, cur.file_id});
    }
    out.close();

    for (auto& f : files)
        f.close();
    for (auto& f : chunk_files)
        remove(f.c_str());

    std::cerr << "Sorting done. Output: " << outfile << "\n";
    return 0;
}
