import random
import matplotlib.pyplot as plt
import time

random.seed(42)


def generate_graph(num_vertices=300, min_deg=2, max_deg=30):
    adj = {i: set() for i in range(num_vertices)}

    # ring edges to ensure min_deg
    indices = list(range(num_vertices))
    random.shuffle(indices)
    for i in range(num_vertices):
        u, v = indices[i], indices[(i + 1) % num_vertices]
        adj[u].add(v)
        adj[v].add(u)

    # add random edges until we reach target edge count
    attempts = 0
    target_edges = num_vertices * 4  # approx 4 edges per vertex
    current_edges = num_vertices

    while current_edges < target_edges and attempts < num_vertices * 100:
        u = random.randint(0, num_vertices - 1)
        v = random.randint(0, num_vertices - 1)

        if u != v and v not in adj[u]:
            if len(adj[u]) < max_deg and len(adj[v]) < max_deg:
                adj[u].add(v)
                adj[v].add(u)
                current_edges += 1
            else:
                attempts += 1
        else:
            attempts += 1

    return adj


def is_valid_cover(graph, cover_set):
    for u in graph:
        for v in graph[u]:
            if u not in cover_set and v not in cover_set:
                return False
    return True


def repair_solution(graph, cover_set):
    sol = set(cover_set)

    # since the graph is undirected, check u < v to avoid duplication

    uncovered_nodes = [node for node in graph if node not in sol]

    # check neighbors of uncovered nodes
    # if neighbor also not in sol, then edge (u, neighbor) is uncovered
    for u in uncovered_nodes:
        if u in sol:
            continue

        for v in graph[u]:
            if v not in sol:
                # (u,v) isn't covered
                # add the vertex with a higher degree
                if len(graph[u]) > len(graph[v]):
                    sol.add(u)
                else:
                    sol.add(v)
                if u in sol:
                    break

    return sol


def generate_random_solution(graph):
    # randomly select approx half of the nodes
    # then repair to ensure coverage
    nodes = list(graph.keys())
    initial_selection = set(random.sample(nodes, k=len(nodes) // 2))
    return repair_solution(graph, initial_selection)


def fitness(solution):
    return len(solution)


class BeeColonyVertexCover:
    def __init__(self, graph, num_sites, num_bees, limit, max_iter):
        self.graph = graph
        self.num_sites = num_sites
        self.num_employed = num_sites

        self.num_onlookers = max(0, num_bees - num_sites)
        self.limit = limit
        self.max_iter = max_iter

        self.population = []  # list of solution sets
        self.trials = []  # trial counters for each site
        self.best_solution = None
        self.best_size = float("inf")
        self.history = []

    def initialize(self):
        self.population = []
        self.trials = []
        for _ in range(self.num_sites):
            sol = generate_random_solution(self.graph)
            self.population.append(sol)
            self.trials.append(0)

            f = fitness(sol)
            if f < self.best_size:
                self.best_size = f
                self.best_solution = set(sol)

    def mutate(self, solution):
        new_sol = set(solution)
        if not new_sol:
            return new_sol

        node_to_remove = random.choice(list(new_sol))
        new_sol.remove(node_to_remove)

        return repair_solution(self.graph, new_sol)

    def run(self):
        self.initialize()

        for it in range(self.max_iter):
            # 1. employed bees
            for i in range(self.num_employed):
                current_sol = self.population[i]
                new_sol = self.mutate(current_sol)

                current_fit = fitness(current_sol)
                new_fit = fitness(new_sol)

                if new_fit <= current_fit:  # minimize
                    self.population[i] = new_sol
                    self.trials[i] = 0
                    if new_fit < current_fit:
                        # found better solution
                        pass
                else:
                    self.trials[i] += 1

            # 2. onlooker bees
            fitness_vals = [fitness(sol) for sol in self.population]

            inv_fitness = [1.0 / f for f in fitness_vals]
            total_inv = sum(inv_fitness)
            probs = [f / total_inv for f in inv_fitness]

            # cumulative probabilities
            cum_probs = []
            s = 0
            for p in probs:
                s += p
                cum_probs.append(s)

            for _ in range(self.num_onlookers):
                r = random.random()
                selected_idx = 0
                for idx, cp in enumerate(cum_probs):
                    if r <= cp:
                        selected_idx = idx
                        break

                # try to improve selected solution
                current_sol = self.population[selected_idx]
                new_sol = self.mutate(current_sol)

                if fitness(new_sol) <= fitness(current_sol):
                    self.population[selected_idx] = new_sol
                    self.trials[selected_idx] = 0
                else:
                    self.trials[selected_idx] += 1

            # 3. update global best
            for sol in self.population:
                f = fitness(sol)
                if f < self.best_size:
                    self.best_size = f
                    self.best_solution = set(sol)

            # 4. scout bees
            for i in range(self.num_sites):
                if self.trials[i] > self.limit:
                    self.population[i] = generate_random_solution(self.graph)
                    self.trials[i] = 0

            self.history.append(self.best_size)

        return self.best_size


def optimize_parameters(graph):
    current_params = {
        "num_sites": 20,
        "num_bees": 50,
    }

    ranges = {"num_sites": [5, 10, 20, 30, 50], "num_bees": [20, 50, 75, 100, 150]}

    limit = 20
    max_iter = 50

    changed = True
    loop_count = 0

    print(
        f"{'Phase':<10} | {'Fix Param':<15} | {'Var Param':<15} | {'Val':<5} | {'Result':<6}"
    )
    print("-" * 65)

    while changed and loop_count < 3:
        changed = False
        loop_count += 1

        # 1. pin num_sites, vary num_bees
        best_sites = current_params["num_sites"]
        best_val_for_step = float("inf")

        for val in ranges["num_sites"]:
            # num_sites can't be > num_bees
            if val > current_params["num_bees"]:
                continue

            # run multiple times for avg
            runs = 3
            avg_res = 0
            for _ in range(runs):
                abc = BeeColonyVertexCover(
                    graph, val, current_params["num_bees"], limit, max_iter
                )
                avg_res += abc.run()
            avg_res /= runs

            print(
                f"Loop {loop_count:<5} | Bees={current_params['num_bees']:<10} | Sites={val:<10} | {val:<5} | {avg_res:.2f}"
            )

            if avg_res < best_val_for_step:
                best_val_for_step = avg_res
                if best_sites != val:
                    best_sites = val
                    changed = True

        current_params["num_sites"] = best_sites
        print(f">>> Selected Best Sites: {best_sites}")
        print("-" * 65)

        # 2. pin num_sites, vary num_bees
        best_bees = current_params["num_bees"]
        best_val_for_step = float("inf")

        for val in ranges["num_bees"]:
            if val < current_params["num_sites"]:
                continue

            runs = 3
            avg_res = 0
            for _ in range(runs):
                abc = BeeColonyVertexCover(
                    graph, current_params["num_sites"], val, limit, max_iter
                )
                avg_res += abc.run()
            avg_res /= runs

            print(
                f"Loop {loop_count:<5} | Sites={current_params['num_sites']:<9} | Bees={val:<11} | {val:<5} | {avg_res:.2f}"
            )

            if avg_res < best_val_for_step:
                best_val_for_step = avg_res
                if best_bees != val:
                    best_bees = val
                    changed = True

        current_params["num_bees"] = best_bees
        print(f">>> Selected Best Bees: {best_bees}")
        print("-" * 65)

    return current_params


if __name__ == "__main__":
    print("1. Generating Graph (300 nodes)...")
    G = generate_graph(300, min_deg=2, max_deg=30)

    print("\n2. Starting Parameter Optimization...")
    best_params = optimize_parameters(G)

    print(f"\nOptimal Parameters found: {best_params}")

    print("\n3. Running Final Algorithm with Optimal Parameters...")

    final_abc = BeeColonyVertexCover(G, limit=50, max_iter=200, **best_params)
    start_time = time.time()
    final_result = final_abc.run()
    end_time = time.time()

    print(f"Best Vertex Cover Size: {final_result}")
    print(f"Time taken: {end_time - start_time:.4f}s")
    print("Valid cover:", is_valid_cover(G, final_abc.best_solution))

    # plotting
    plt.figure(figsize=(10, 6))
    plt.plot(final_abc.history, label="Best Solution Size")
    plt.title(
        f'ABC Convergence (Sites={best_params["num_sites"]}, Bees={best_params["num_bees"]})'
    )
    plt.xlabel("Iteration")
    plt.ylabel("Vertex Cover Size")
    plt.grid(True)
    plt.legend()
    plt.show()
