import numpy as np
import matplotlib.pyplot as plt
from typing import List, Tuple

np.random.seed(1515)


class KnapsackGA:
    def __init__(
        self,
        n_items: int = 100,
        capacity: int = 150,
        pop_size: int = 100,
        max_iter: int = 1000,
        local_search_start_iter: int = 600,
    ):
        self.n_items = n_items
        self.capacity = capacity
        self.pop_size = pop_size
        self.max_iter = max_iter
        self.ls_start_iter = local_search_start_iter

        self.weights = np.random.randint(1, 6, size=n_items)
        self.values = np.random.randint(2, 11, size=n_items)

    def calculate_fitness(self, individual: np.ndarray) -> int:
        total_weight = np.sum(individual * self.weights)
        if total_weight > self.capacity:
            return 0
        return np.sum(individual * self.values)

    def init_population(self) -> np.ndarray:
        return np.eye(self.pop_size, M=self.n_items, dtype=int)

    def uniform_crossover(self, parent1: np.ndarray, parent2: np.ndarray) -> np.ndarray:
        mask = np.random.randint(0, 2, size=self.n_items).astype(bool)
        child = np.where(mask, parent1, parent2)
        return child

    def mutation_swap(self, individual: np.ndarray) -> np.ndarray:
        idx1, idx2 = np.random.choice(self.n_items, 2, replace=False)
        individual[idx1], individual[idx2] = individual[idx2], individual[idx1]
        return individual

    def hill_climbing(self, individual: np.ndarray) -> np.ndarray:
        current_fitness = self.calculate_fitness(individual)
        best_neighbor = individual.copy()

        for _ in range(10):
            neighbor = best_neighbor.copy()
            idx = np.random.randint(0, self.n_items)
            neighbor[idx] = 1 - neighbor[idx]
            neighbor_fitness = self.calculate_fitness(neighbor)

            if neighbor_fitness > current_fitness:
                best_neighbor = neighbor
                current_fitness = neighbor_fitness

        return best_neighbor

    def run(self) -> Tuple[List[int], List[int]]:
        population = self.init_population()
        history_fitness = []
        history_iters = []

        print(f"--- Старт ГА: Місткість={self.capacity}, Предметів={self.n_items} ---")

        for i in range(1, self.max_iter + 1):
            fitness_scores = np.array(
                [self.calculate_fitness(ind) for ind in population]
            )

            if i % 20 == 0:
                best_in_gen = np.max(fitness_scores)
                history_fitness.append(best_in_gen)
                history_iters.append(i)
                print(f"Ітерація {i:4d} | Найкраща якість: {best_in_gen}")

            # selection
            new_population = []
            for _ in range(self.pop_size):
                candidates_idx = np.random.choice(self.pop_size, 3, replace=False)
                winner_idx = candidates_idx[np.argmax(fitness_scores[candidates_idx])]
                new_population.append(population[winner_idx])

            new_population = np.array(new_population)
            next_gen = []

            # crossover + mutation
            for k in range(0, self.pop_size, 2):
                p1 = new_population[k]
                p2 = (
                    new_population[k + 1]
                    if k + 1 < self.pop_size
                    else new_population[0]
                )

                c1 = self.uniform_crossover(p1, p2)
                c2 = self.uniform_crossover(p2, p1)

                if np.random.rand() < 0.1:
                    c1 = self.mutation_swap(c1)
                if np.random.rand() < 0.1:
                    c2 = self.mutation_swap(c2)

                next_gen.extend([c1, c2])

            population = np.array(next_gen[: self.pop_size])

            # local search
            if i >= self.ls_start_iter:
                fitness_current = np.array(
                    [self.calculate_fitness(ind) for ind in population]
                )
                top_indices = np.argsort(fitness_current)[-10:]
                for idx in top_indices:
                    population[idx] = self.hill_climbing(population[idx])

        return history_iters, history_fitness


ga = KnapsackGA(max_iter=1000, local_search_start_iter=600)
iters, values = ga.run()

plt.figure(figsize=(10, 6))
plt.plot(
    iters,
    values,
    marker="o",
    linestyle="-",
    color="b",
    markersize=4,
    label="Best Fitness",
)
plt.axvline(x=600, color="r", linestyle="--", label="Start of Hill Climbing (Iter 600)")
plt.title("Залежність якості розв'язку від ітерацій")
plt.xlabel("Ітерація")
plt.ylabel("Цінність рюкзака")
plt.grid(True, linestyle="--", alpha=0.7)
plt.legend()
plt.tight_layout()
plt.show()
