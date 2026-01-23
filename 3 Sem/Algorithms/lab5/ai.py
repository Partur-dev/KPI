from dataclasses import dataclass
from typing import Tuple

import numpy as np
import matplotlib.pyplot as plt

np.random.seed(1515)


@dataclass
class Item:
    weight: int
    value: int


def generate_items(
    n: int,
) -> Tuple[np.ndarray, np.ndarray]:
    """
    Генерує випадкові предмети.
    Повертає:
      weights: (n,) int
      values:  (n,) int
    """
    weights = np.random.randint(1, 6, size=n)  # [1, 5]
    values = np.random.randint(2, 11, size=n)  # [2, 10]
    return weights, values


def knapsack_exact_dp(
    capacity: int,
    weights: np.ndarray,
    values: np.ndarray,
) -> tuple[int, np.ndarray]:
    """
    Точний 0/1 knapsack через DP.
    Повертає:
      max_value: максимальна сумарна цінність
      chosen:    маска (bool) розміром n, які предмети обрані
    """
    n = weights.shape[0]
    # dp[i, w] = макс. цінність, використовуючи перші i предметів і місткість w
    dp = np.zeros((n + 1, capacity + 1), dtype=int)
    keep = np.zeros((n + 1, capacity + 1), dtype=bool)

    for i in range(1, n + 1):
        w_i = int(weights[i - 1])
        v_i = int(values[i - 1])

        # спочатку копіюємо "не беремо предмет i"
        dp[i] = dp[i - 1]

        # для w >= w_i можемо спробувати "взяти предмет i"
        idx = np.arange(w_i, capacity + 1, dtype=int)
        candidate = dp[i - 1, idx - w_i] + v_i

        better = candidate > dp[i, idx]
        dp[i, idx[better]] = candidate[better]
        keep[i, idx[better]] = True

    # відновлюємо рішення
    chosen = np.zeros(n, dtype=bool)
    w = capacity
    for i in range(n, 0, -1):
        if keep[i, w]:
            chosen[i - 1] = True
            w -= int(weights[i - 1])
            if w <= 0:
                break

    max_value = int(dp[n, capacity])
    return max_value, chosen


def plot_items(
    weights: np.ndarray,
    values: np.ndarray,
    chosen: np.ndarray,
) -> None:
    """
    Візуалізація: всі предмети + виділені обрані.
    """
    plt.figure()
    plt.scatter(weights, values, alpha=0.4, label="All items")
    plt.scatter(
        weights[chosen],
        values[chosen],
        marker="x",
        s=80,
        label="Chosen (optimal)",
    )
    plt.xlabel("Weight")
    plt.ylabel("Value")
    plt.title("0/1 Knapsack items")
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.show()


def main() -> None:
    capacity = 150
    n_items = 100

    weights, values = generate_items(n_items)

    max_value, chosen = knapsack_exact_dp(capacity, weights, values)

    total_weight = int(weights[chosen].sum())
    total_value = int(values[chosen].sum())

    print(f"Capacity:      {capacity}")
    print(f"Items:         {n_items}")
    print(f"Optimal value: {max_value}")
    print(f"Total weight:  {total_weight}")
    print(f"Check value:   {total_value}")
    print(f"Chosen count:  {chosen.sum()}")

    plot_items(weights, values, chosen)


if __name__ == "__main__":
    main()
