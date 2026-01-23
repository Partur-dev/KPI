#include <algorithm>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <map>
#include <mutex>
#include <set>
#include <vector>

constexpr int DEGREE = 100;
constexpr const char* DB_FILE = "btree.bin";

struct Payload {
    char data[40];

    Payload() {
        std::memset(data, 0, 40);
    }

    Payload(std::string_view s) {
        std::memset(data, 0, 40);
        std::strncpy(data, s.data(), std::min(s.size(), size_t(39)));
    }

    std::string toString() const {
        return std::string(data);
    }
};

struct Record {
    int64_t key;
    Payload value;
};

using NodeIndex = int64_t;
constexpr NodeIndex NULL_INDEX = -1;

#pragma pack(push, 1)

struct Node {
    NodeIndex self_index = NULL_INDEX;
    bool is_leaf = true;
    int num_keys = 0;
    Record records[2 * DEGREE - 1];
    NodeIndex children[2 * DEGREE];

    Node() {
        std::fill(std::begin(children), std::end(children), NULL_INDEX);
    }
};

#pragma pack(pop)

struct MetaData {
    NodeIndex root_index = NULL_INDEX;
    NodeIndex next_free_index = 0;
};

class DiskManager {
    std::fstream file;
    MetaData meta;

public:
    DiskManager() {
        bool exists = std::filesystem::exists(DB_FILE);
        file.open(DB_FILE, std::ios::in | std::ios::out | std::ios::binary);
        if (!exists || !file.is_open()) {
            file.open(DB_FILE, std::ios::out | std::ios::binary);
            file.close();
            file.open(DB_FILE, std::ios::in | std::ios::out | std::ios::binary);
            writeMeta();
        } else {
            readMeta();
        }
    }

    ~DiskManager() {
        if (file.is_open())
            file.close();
    }

    void readMeta() {
        file.seekg(0, std::ios::beg);
        file.read(reinterpret_cast<char*>(&meta), sizeof(MetaData));
    }

    void writeMeta() {
        file.seekp(0, std::ios::beg);
        file.write(reinterpret_cast<const char*>(&meta), sizeof(MetaData));
    }

    NodeIndex getRoot() const {
        return meta.root_index;
    }

    void setRoot(NodeIndex idx) {
        meta.root_index = idx;
        writeMeta();
    }

    NodeIndex allocateNode() {
        NodeIndex idx = meta.next_free_index++;
        writeMeta();
        Node node;
        node.self_index = idx;
        std::streampos pos = sizeof(MetaData) + (idx * sizeof(Node));
        file.seekp(pos);
        file.write(reinterpret_cast<const char*>(&node), sizeof(Node));
        return idx;
    }

    void readNode(NodeIndex idx, Node& node) {
        if (idx == NULL_INDEX)
            return;
        std::streampos pos = sizeof(MetaData) + (idx * sizeof(Node));
        file.seekg(pos);
        file.read(reinterpret_cast<char*>(&node), sizeof(Node));
    }

    void writeNode(NodeIndex idx, const Node& node) {
        std::streampos pos = sizeof(MetaData) + (idx * sizeof(Node));
        file.seekp(pos);
        file.write(reinterpret_cast<const char*>(&node), sizeof(Node));
    }
};

class BTree {
    std::mutex diskMutex;

    DiskManager disk;

    int findKeyIndex(const Node& node, int64_t k, int& comparisons) {
        auto cmp = [&](const Record& r, int64_t val) {
            comparisons++;
            return r.key < val;
        };
        auto it = std::lower_bound(node.records, node.records + node.num_keys, k, cmp);
        return std::distance(node.records, it);
    }

    int findKeyIndex(const Node& node, int64_t k) {
        auto cmp = [&](const Record& r, int64_t val) {
            return r.key < val;
        };
        auto it = std::lower_bound(node.records, node.records + node.num_keys, k, cmp);
        return std::distance(node.records, it);
    }

    void splitChild(Node& x, int i) {
        Node y;
        disk.readNode(x.children[i], y);
        Node z;
        z.self_index = disk.allocateNode();
        z.is_leaf = y.is_leaf;
        z.num_keys = DEGREE - 1;

        for (int j = 0; j < DEGREE - 1; j++)
            z.records[j] = y.records[j + DEGREE];
        if (!y.is_leaf) {
            for (int j = 0; j < DEGREE; j++)
                z.children[j] = y.children[j + DEGREE];
        }
        y.num_keys = DEGREE - 1;

        for (int j = x.num_keys; j >= i + 1; j--)
            x.children[j + 1] = x.children[j];
        x.children[i + 1] = z.self_index;

        for (int j = x.num_keys - 1; j >= i; j--)
            x.records[j + 1] = x.records[j];
        x.records[i] = y.records[DEGREE - 1];
        x.num_keys++;

        disk.writeNode(y.self_index, y);
        disk.writeNode(z.self_index, z);
        disk.writeNode(x.self_index, x);
    }

    void insertNonFull(Node& x, const Record& k) {
        int i = x.num_keys - 1;
        if (x.is_leaf) {
            while (i >= 0 && k.key < x.records[i].key) {
                x.records[i + 1] = x.records[i];
                i--;
            }
            x.records[i + 1] = k;
            x.num_keys++;
            disk.writeNode(x.self_index, x);
        } else {
            int childIdx = findKeyIndex(x, k.key);
            Node child;
            disk.readNode(x.children[childIdx], child);
            if (child.num_keys == 2 * DEGREE - 1) {
                splitChild(x, childIdx);
                if (k.key > x.records[childIdx].key)
                    childIdx++;
                disk.readNode(x.children[childIdx], child);
            }
            insertNonFull(child, k);
        }
    }

    void removeFromLeaf(Node& node, int idx) {
        for (int i = idx + 1; i < node.num_keys; ++i)
            node.records[i - 1] = node.records[i];
        node.num_keys--;
        disk.writeNode(node.self_index, node);
    }

    void removeFromNonLeaf(Node& node, int idx) {
        int64_t k = node.records[idx].key;
        Node child;
        disk.readNode(node.children[idx], child);

        if (child.num_keys >= DEGREE) {
            Record pred = getPredecessor(node, idx);
            node.records[idx] = pred;
            disk.writeNode(node.self_index, node);
            removeInternal(child, pred.key);
        } else {
            Node sibling;
            disk.readNode(node.children[idx + 1], sibling);
            if (sibling.num_keys >= DEGREE) {
                Record succ = getSuccessor(node, idx);
                node.records[idx] = succ;
                disk.writeNode(node.self_index, node);
                removeInternal(sibling, succ.key);
            } else {
                merge(node, idx);
                Node mergedChild;
                disk.readNode(node.children[idx], mergedChild);
                removeInternal(mergedChild, k);
            }
        }
    }

    Record getPredecessor(Node& node, int idx) {
        Node curr;
        disk.readNode(node.children[idx], curr);
        while (!curr.is_leaf)
            disk.readNode(curr.children[curr.num_keys], curr);
        return curr.records[curr.num_keys - 1];
    }

    Record getSuccessor(Node& node, int idx) {
        Node curr;
        disk.readNode(node.children[idx + 1], curr);
        while (!curr.is_leaf)
            disk.readNode(curr.children[0], curr);
        return curr.records[0];
    }

    void fill(Node& node, int idx) {
        Node prevChild, nextChild;
        bool hasPrev = (idx != 0);
        bool hasNext = (idx != node.num_keys);

        if (hasPrev)
            disk.readNode(node.children[idx - 1], prevChild);
        if (hasNext)
            disk.readNode(node.children[idx + 1], nextChild);

        if (hasPrev && prevChild.num_keys >= DEGREE)
            borrowFromPrev(node, idx);
        else if (hasNext && nextChild.num_keys >= DEGREE)
            borrowFromNext(node, idx);
        else {
            if (hasNext)
                merge(node, idx);
            else
                merge(node, idx - 1);
        }
    }

    void borrowFromPrev(Node& node, int idx) {
        Node child, sibling;
        disk.readNode(node.children[idx], child);
        disk.readNode(node.children[idx - 1], sibling);

        for (int i = child.num_keys - 1; i >= 0; --i)
            child.records[i + 1] = child.records[i];

        if (!child.is_leaf) {
            for (int i = child.num_keys; i >= 0; --i)
                child.children[i + 1] = child.children[i];
        }

        child.records[0] = node.records[idx - 1];
        if (!child.is_leaf)
            child.children[0] = sibling.children[sibling.num_keys];

        node.records[idx - 1] = sibling.records[sibling.num_keys - 1];

        child.num_keys += 1;
        sibling.num_keys -= 1;

        disk.writeNode(node.self_index, node);
        disk.writeNode(child.self_index, child);
        disk.writeNode(sibling.self_index, sibling);
    }

    void borrowFromNext(Node& node, int idx) {
        Node child, sibling;
        disk.readNode(node.children[idx], child);
        disk.readNode(node.children[idx + 1], sibling);

        child.records[child.num_keys] = node.records[idx];

        if (!child.is_leaf)
            child.children[child.num_keys + 1] = sibling.children[0];

        node.records[idx] = sibling.records[0];

        for (int i = 1; i < sibling.num_keys; ++i)
            sibling.records[i - 1] = sibling.records[i];

        if (!sibling.is_leaf) {
            for (int i = 1; i <= sibling.num_keys; ++i)
                sibling.children[i - 1] = sibling.children[i];
        }

        child.num_keys += 1;
        sibling.num_keys -= 1;

        disk.writeNode(node.self_index, node);
        disk.writeNode(child.self_index, child);
        disk.writeNode(sibling.self_index, sibling);
    }

    void merge(Node& node, int idx) {
        Node child, sibling;
        disk.readNode(node.children[idx], child);
        disk.readNode(node.children[idx + 1], sibling);

        child.records[DEGREE - 1] = node.records[idx];

        for (int i = 0; i < sibling.num_keys; ++i)
            child.records[i + DEGREE] = sibling.records[i];

        if (!child.is_leaf) {
            for (int i = 0; i <= sibling.num_keys; ++i)
                child.children[i + DEGREE] = sibling.children[i];
        }

        for (int i = idx + 1; i < node.num_keys; ++i)
            node.records[i - 1] = node.records[i];

        for (int i = idx + 2; i <= node.num_keys; ++i)
            node.children[i - 1] = node.children[i];

        child.num_keys += sibling.num_keys + 1;
        node.num_keys--;

        disk.writeNode(child.self_index, child);
        disk.writeNode(node.self_index, node);
    }

    void removeInternal(Node& x, int64_t k) {
        int idx = findKeyIndex(x, k);

        if (idx < x.num_keys && x.records[idx].key == k) {
            if (x.is_leaf)
                removeFromLeaf(x, idx);
            else
                removeFromNonLeaf(x, idx);
        } else {
            if (x.is_leaf)
                return;

            bool flag = (idx == x.num_keys);
            Node child;
            disk.readNode(x.children[idx], child);

            if (child.num_keys < DEGREE) {
                fill(x, idx);
                if (flag && idx > x.num_keys)
                    idx--;
                disk.readNode(x.children[idx], child);
            }
            removeInternal(child, k);
        }
    }

public:
    BTree() = default;

    struct SearchResult {
        std::string value;
        int comparisons = 0;
        bool found = false;
    };

    SearchResult getWithStats(int64_t key) {
        std::lock_guard<std::mutex> lock(diskMutex);
        NodeIndex currIdx = disk.getRoot();
        SearchResult result;
        result.value = "NOT_FOUND";

        while (currIdx != NULL_INDEX) {
            Node curr;
            disk.readNode(currIdx, curr);
            int i = findKeyIndex(curr, key, result.comparisons);

            if (i < curr.num_keys && curr.records[i].key == key) {
                result.value = curr.records[i].value.toString();
                result.found = true;
                return result;
            }
            if (curr.is_leaf)
                break;
            currIdx = curr.children[i];
        }
        return result;
    }

    std::pair<std::vector<NodeIndex>, int> getPathToKey(int64_t key) {
        std::lock_guard<std::mutex> lock(diskMutex);
        std::vector<NodeIndex> path;
        int comparisons = 0;
        NodeIndex currIdx = disk.getRoot();

        while (currIdx != NULL_INDEX) {
            path.push_back(currIdx);
            Node curr;
            disk.readNode(currIdx, curr);
            int i = findKeyIndex(curr, key, comparisons);
            if (i < curr.num_keys && curr.records[i].key == key)
                return {path, comparisons};
            if (curr.is_leaf)
                break;
            currIdx = curr.children[i];
        }
        return {{}, comparisons};
    }

    std::string upsert(int64_t key, std::string_view value) {
        std::lock_guard<std::mutex> lock(diskMutex);
        NodeIndex currIdx = disk.getRoot();

        // Update
        while (currIdx != NULL_INDEX) {
            Node curr;
            disk.readNode(currIdx, curr);
            int i = findKeyIndex(curr, key);
            if (i < curr.num_keys && curr.records[i].key == key) {
                curr.records[i].value = Payload(value);
                disk.writeNode(curr.self_index, curr);
                return "Updated existing key";
            }
            if (curr.is_leaf)
                break;
            currIdx = curr.children[i];
        }

        // Insert
        NodeIndex rootIdx = disk.getRoot();
        Record newRecord {key, Payload(value)};
        if (rootIdx == NULL_INDEX) {
            Node root;
            root.self_index = disk.allocateNode();
            root.is_leaf = true;
            root.num_keys = 1;
            root.records[0] = newRecord;
            disk.writeNode(root.self_index, root);
            disk.setRoot(root.self_index);
        } else {
            Node root;
            disk.readNode(rootIdx, root);
            if (root.num_keys == 2 * DEGREE - 1) {
                Node s;
                s.self_index = disk.allocateNode();
                s.is_leaf = false;
                s.children[0] = rootIdx;
                disk.writeNode(s.self_index, s);
                disk.setRoot(s.self_index);
                splitChild(s, 0);
                insertNonFull(s, newRecord);
            } else {
                insertNonFull(root, newRecord);
            }
        }
        return "Added new key";
    }

    std::string remove(int64_t key) {
        std::lock_guard<std::mutex> lock(diskMutex);
        NodeIndex rootIdx = disk.getRoot();
        if (rootIdx == NULL_INDEX)
            return "Tree is empty";

        Node root;
        disk.readNode(rootIdx, root);

        removeInternal(root, key);

        disk.readNode(rootIdx, root);
        if (root.num_keys == 0) {
            if (root.is_leaf)
                disk.setRoot(NULL_INDEX);
            else
                disk.setRoot(root.children[0]);
        }
        return "Deletion attempted";
    }

    NodeIndex getRootIndex() {
        std::lock_guard<std::mutex> lock(diskMutex);
        return disk.getRoot();
    }

    void readNodeForVis(NodeIndex idx, Node& n) {
        std::lock_guard<std::mutex> lock(diskMutex);
        disk.readNode(idx, n);
    }
};
