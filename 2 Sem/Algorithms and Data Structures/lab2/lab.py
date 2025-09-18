import sys

if len(sys.argv) != 3:
    print("Usage: python lab.py <user_id> <filename>")
    sys.exit(1)

selected_user = int(sys.argv[1]) - 1
filename = sys.argv[2]


def count_inversions(arr: list[int]) -> int:
    return merge_sort(arr, 0, len(arr) - 1)


def merge_sort(arr: list[int], left: int, right: int) -> int:
    if left >= right:
        return 0

    mid = (left + right) // 2
    inv_count = merge_sort(arr, left, mid)
    inv_count += merge_sort(arr, mid + 1, right)
    inv_count += merge(arr, left, mid, right)

    return inv_count


def merge(arr: list[int], left: int, mid: int, right: int) -> int:
    left_arr = arr[left : mid + 1]
    right_arr = arr[mid + 1 : right + 1]

    i = 0
    j = 0
    k = left
    inv_count = 0

    while i < len(left_arr) and j < len(right_arr):
        if left_arr[i] <= right_arr[j]:
            arr[k] = left_arr[i]
            i += 1
        else:
            arr[k] = right_arr[j]
            inv_count += len(left_arr) - i
            j += 1
        k += 1

    while i < len(left_arr):
        arr[k] = left_arr[i]
        i += 1
        k += 1

    while j < len(right_arr):
        arr[k] = right_arr[j]
        j += 1
        k += 1

    return inv_count


num_users = 0
num_items = 0

matrix: list[list[int]] = []

with open(filename, "r") as f:
    num_users, num_items = map(int, f.readline().split())

    matrix = [[] for _ in range(num_users)]

    for i in range(num_users):
        user_id, *rating = map(int, f.readline().split())
        matrix[user_id - 1] = rating

selected_ranking = matrix[selected_user]

order = sorted(range(num_items), key=lambda i: selected_ranking[i])

results = {
    i: count_inversions([matrix[i][j] for j in order])
    for i in range(num_users)
    if i != selected_user
}

for user_i, inv in sorted(results.items(), key=lambda x: x[1]):
    print(user_i + 1, inv)
