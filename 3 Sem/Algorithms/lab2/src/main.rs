use std::cmp::Ordering;
use std::time::{SystemTime, UNIX_EPOCH};

const BOARD_SIZE: usize = 8;
const HILL_CLIMBING_MAX_RESTARTS: u32 = 1000;
const HILL_CLIMBING_SIDEWAYS_LIMIT: u32 = 100;

// Кількість сусідів, яку ми генеруємо за один крок (8 колонок * 7 рядків)
const NEIGHBORS_PER_STEP: usize = BOARD_SIZE * (BOARD_SIZE - 1);

#[derive(Debug, Default, Clone, Copy)]
struct SearchMetrics {
    generated_total: usize,
    stored_samples_sum: usize,
    steps: usize,
}

impl SearchMetrics {
    fn avg_stored(&self) -> f64 {
        if self.steps == 0 {
            0.0
        } else {
            self.stored_samples_sum as f64 / self.steps as f64
        }
    }
}

#[derive(Debug, Clone)]
struct HCState {
    board: [usize; BOARD_SIZE],
    g: usize,
    h: usize,
}

#[derive(Debug, Clone, Eq)]
struct Node {
    board: [usize; BOARD_SIZE],
    g: usize, // cost
    h: usize, // heuristic
    f: usize, // g + h
}

impl Ord for Node {
    fn cmp(&self, other: &Self) -> Ordering {
        self.f.cmp(&other.f)
    }
}

impl PartialOrd for Node {
    fn partial_cmp(&self, other: &Self) -> Option<Ordering> {
        Some(self.cmp(other))
    }
}

impl PartialEq for Node {
    fn eq(&self, other: &Self) -> bool {
        self.f == other.f
    }
}

fn heuristic(board: &[usize; BOARD_SIZE]) -> usize {
    let mut conflicts = 0;
    for i in 0..BOARD_SIZE {
        for j in (i + 1)..BOARD_SIZE {
            // horizontal (same row) and diagonal conflicts
            if board[i] == board[j]
                || (i as isize - j as isize).abs() == (board[i] as isize - board[j] as isize).abs()
            {
                conflicts += 1;
            }
        }
    }

    conflicts
}

// fn heuristic(board: &[usize; BOARD_SIZE]) -> usize {
//     let mut conflicts = 0;

//     for i in 0..BOARD_SIZE {
//         for j in (i + 1)..BOARD_SIZE {
//             let r1 = board[i] as isize;
//             let r2 = board[j] as isize;
//             let c1 = i as isize;
//             let c2 = j as isize;

//             // same row
//             let same_row = r1 == r2;
//             // same diagonal
//             let same_diag = (r1 - r2).abs() == (c1 - c2).abs();

//             if !same_row && !same_diag {
//                 continue;
//             }

//             // direction of movement
//             let dr = (r2 - r1).signum();
//             let dc = (c2 - c1).signum(); // j>1 so 1 or 0

//             // walk from (c1, r1) towards (c2, r2), check if someone blocks the line
//             let mut blocked = false;
//             let mut rr = r1 + dr;
//             let mut cc = c1 + dc;

//             while cc != c2 {
//                 let col = cc as usize;

//                 if board[col] as isize == rr {
//                     blocked = true;
//                     break;
//                 }

//                 rr += dr;
//                 cc += dc;
//             }

//             if !blocked {
//                 conflicts += 1;
//             }
//         }
//     }

//     conflicts
// }

fn print_board(title: &str, board: &[usize; BOARD_SIZE]) {
    println!("\n--- {} ---", title);

    for row in 0..BOARD_SIZE {
        for col in 0..BOARD_SIZE {
            if board[col] == row {
                print!("Q ");
            } else {
                print!(". ");
            }
        }

        println!();
    }
}

// ===== RNG Helper =====

struct SimpleRng {
    seed: u64,
}

impl SimpleRng {
    fn new() -> Self {
        let seed = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .unwrap()
            .as_secs();

        Self {
            seed: seed.wrapping_add(0xDEADBEEF),
        }
    }

    fn next_u64(&mut self) -> u64 {
        self.seed = self
            .seed
            .wrapping_mul(6364136223846793005)
            .wrapping_add(1442695040888963407);

        self.seed
    }

    fn gen_range(&mut self, range: std::ops::Range<usize>) -> usize {
        range.start + (self.next_u64() as usize % (range.end - range.start))
    }
}

fn generate_random_board(rng: &mut SimpleRng) -> [usize; BOARD_SIZE] {
    let mut board = [0; BOARD_SIZE];

    for col in 0..BOARD_SIZE {
        board[col] = rng.gen_range(0..BOARD_SIZE);
    }

    board
}

// ===== Hill Climbing =====

fn generate_random_hc_state(rng: &mut SimpleRng) -> HCState {
    let board = generate_random_board(rng);
    let h = heuristic(&board);
    HCState { board, g: 0, h }
}

fn find_best_neighbors(current: &HCState) -> Vec<HCState> {
    let mut best_neighbors = Vec::new();
    let mut min_h = current.h;

    // for each column...
    for col in 0..BOARD_SIZE {
        let original_row = current.board[col];

        // ...try moving the queen to every other row
        for row in 0..BOARD_SIZE {
            if row == original_row {
                continue;
            }

            let mut temp_board = current.board;
            temp_board[col] = row;
            let temp_h = heuristic(&temp_board);

            // found a better neighbor so previous are pretty much useless
            if temp_h < min_h {
                min_h = temp_h;

                best_neighbors.clear();
                best_neighbors.push(HCState {
                    board: temp_board,
                    g: current.g + 1,
                    h: temp_h,
                });
            } else if temp_h == min_h {
                best_neighbors.push(HCState {
                    board: temp_board,
                    g: current.g + 1,
                    h: temp_h,
                });
            }
        }
    }
    best_neighbors
}

fn hill_climbing_solver(rng: &mut SimpleRng) -> (Option<HCState>, SearchMetrics) {
    let mut metrics = SearchMetrics::default();

    for _restart_num in 0..HILL_CLIMBING_MAX_RESTARTS {
        let mut current_state = generate_random_hc_state(rng);
        let mut sideways_moves = 0;

        while sideways_moves <= HILL_CLIMBING_SIDEWAYS_LIMIT {
            if current_state.h == 0 {
                // println!("HC Solution found at restart #{}", restart_num + 1);
                return (Some(current_state), metrics);
            }

            let best_neighbors = find_best_neighbors(&current_state);

            metrics.generated_total += NEIGHBORS_PER_STEP;
            metrics.steps += 1;

            // in-mem - current + neighbors
            metrics.stored_samples_sum += 1 + best_neighbors.len();

            if best_neighbors.is_empty() {
                break;
            }

            let chosen_neighbor = &best_neighbors[rng.gen_range(0..best_neighbors.len())];

            if chosen_neighbor.h < current_state.h {
                sideways_moves = 0;
            } else if chosen_neighbor.h == current_state.h {
                sideways_moves += 1;
            } else {
                break;
            }

            current_state = chosen_neighbor.clone();
        }
    }

    (None, metrics)
}

// ===== RBFS =====

fn generate_rbfs_successors(node: &Node) -> Vec<Node> {
    let mut successors = Vec::new();

    // for each column...
    for col in 0..BOARD_SIZE {
        let current_row = node.board[col];

        // ...try moving the queen to every other row
        for row in 0..BOARD_SIZE {
            if row == current_row {
                continue;
            }

            let mut new_board = node.board;
            new_board[col] = row;

            // cost of move; full heuristic
            let g = node.g + 1;
            let h = heuristic(&new_board);

            successors.push(Node {
                board: new_board,
                g,
                h,
                f: g + h,
            });
        }
    }
    successors
}

fn rbfs(
    node: Node,
    f_limit: usize,
    metrics: &mut SearchMetrics,
    depth: usize,
) -> Result<Node, usize> {
    if node.h == 0 {
        return Ok(node);
    }

    let mut successors = generate_rbfs_successors(&node);

    metrics.generated_total += successors.len();
    metrics.steps += 1;
    // each recursion level stores all successors
    metrics.stored_samples_sum += (depth + 1) * NEIGHBORS_PER_STEP;

    if successors.is_empty() {
        return Err(usize::MAX);
    }

    // sort by f-val
    successors.sort();

    loop {
        let best = &successors[0];

        if best.f > f_limit {
            return Err(best.f);
        }

        // the second (if exists) one is the alternative
        let alternative_f = if successors.len() > 1 {
            successors[1].f
        } else {
            usize::MAX
        };

        // limit should be minimal
        let result = rbfs(best.clone(), f_limit.min(alternative_f), metrics, depth + 1);

        match result {
            Ok(solution) => return Ok(solution),
            Err(new_f) => {
                // the real cost appears to be higher so we update it and go to alternative
                successors[0].f = new_f;
                successors.sort();
            }
        }
    }
}

fn rbfs_solver(rng: &mut SimpleRng) -> (Result<Node, usize>, SearchMetrics) {
    let initial_board = generate_random_board(rng);
    let initial_h = heuristic(&initial_board);

    let root = Node {
        board: initial_board,
        g: 0,
        h: initial_h,
        f: initial_h,
    };

    let mut metrics = SearchMetrics::default();

    (rbfs(root, usize::MAX, &mut metrics, 0), metrics)
}

// ===== MAIN =====

struct BenchData {
    success: bool,
    generated: usize,
    avg_stored: f64,
}

fn bench() -> Vec<(BenchData, BenchData)> {
    let mut rng = SimpleRng::new();

    (0..20)
        .map(|_| {
            let (r_res, r_met) = rbfs_solver(&mut rng);
            let r_data = BenchData {
                success: r_res.is_ok(),
                generated: r_met.generated_total,
                avg_stored: r_met.avg_stored(),
            };

            let (h_res, h_met) = hill_climbing_solver(&mut rng);
            let h_data = BenchData {
                success: h_res.is_some(),
                generated: h_met.generated_total,
                avg_stored: h_met.avg_stored(),
            };

            (r_data, h_data)
        })
        .collect()
}

fn run() {
    let mut rng = SimpleRng::new();

    println!("RBFS...");
    match rbfs_solver(&mut rng) {
        (Ok(node), ..) => {
            print_board("RBFS Success", &node.board);
            println!("Moves (Depth): {}", node.g);
        }
        (Err(_), ..) => println!("\nRBFS Failed"),
    }

    println!("\nHill Climbing...");
    match hill_climbing_solver(&mut rng) {
        (Some(state), ..) => {
            print_board("HC Success", &state.board);
            println!("Moves (Depth): {}", state.g);
        }
        (None, ..) => println!("\nHC Failed ({} restarts)", HILL_CLIMBING_MAX_RESTARTS),
    }
}

fn main() {
    run();
    print!("\n\n\n");

    let b = bench();

    println!(
        "  {:<10} | {:<21} | {:<21}",
        "Test #", "RBFS (Gen / Stored)", "HC (Gen / Stored)"
    );
    println!("{:-<58}", "");

    let mut total_rbfs_gen = 0;
    let mut total_rbfs_stored = 0.0;
    let mut total_hc_gen = 0;
    let mut total_hc_stored = 0.0;

    for (i, (r, h)) in b.iter().enumerate() {
        println!(
            "{} {:<10} | {:<8} / {:<10.2} | {:<8} / {:<10.2}",
            if r.success && h.success { "✓" } else { "✗" },
            i + 1,
            r.generated,
            r.avg_stored,
            h.generated,
            h.avg_stored
        );

        total_rbfs_gen += r.generated;
        total_rbfs_stored += r.avg_stored;
        total_hc_gen += h.generated;
        total_hc_stored += h.avg_stored;
    }

    println!("{:-<58}", "");
    println!(
        "  AVERAGE    | {:<8} / {:<10.2} | {:<8} / {:<10.2}",
        total_rbfs_gen / 20,
        total_rbfs_stored / 20.0,
        total_hc_gen / 20,
        total_hc_stored / 20.0
    );

    println!()
}
