use colored::Colorize;
use rand::seq::SliceRandom;

const SIZES: &[usize] = &[10, 100, 1000, 5000, 10000, 20000, 50000];

struct Metrics {
    pub comparisons: usize,
    pub swaps: usize,
}

fn bubble_sort<T: Ord>(data: &mut [T], metrics: &mut Metrics) {
    let n = data.len();
    if n < 2 {
        return;
    }

    for i in 0..n {
        for j in 0..(n - i - 1) {
            metrics.comparisons += 1;
            if data[j] > data[j + 1] {
                metrics.swaps += 1;
                data.swap(j, j + 1);
            }
        }
    }
}

fn modified_bubble_sort<T: Ord>(data: &mut [T], metrics: &mut Metrics) {
    let mut n = data.len();
    if n < 2 {
        return;
    }

    while n > 1 {
        let mut last_swap = 0;

        for i in 1..n {
            metrics.comparisons += 1;
            if data[i - 1] > data[i] {
                data.swap(i - 1, i);
                metrics.swaps += 1;
                last_swap = i;
            }
        }

        if last_swap == 0 {
            break;
        }

        n = last_swap;
    }
}

fn shell_sort<T: Ord + Copy>(data: &mut [T], metrics: &mut Metrics) {
    let n = data.len();

    let gaps = (0..n)
        .map(|i| ((9f64 * (9f64 / 4f64).powi(i as i32) - 4f64) / 5f64).ceil() as usize)
        .rev()
        .collect::<Vec<usize>>();

    for &gap in &gaps {
        for i in gap..n {
            let temp = data[i];
            let mut j = i;
            while j >= gap {
                metrics.comparisons += 1;
                if data[j - gap] > temp {
                    data[j] = data[j - gap];
                    metrics.swaps += 1;
                    j -= gap;
                } else {
                    break;
                }
            }
            data[j] = temp;
        }
    }
}

fn run_alg<T: Ord, F: FnOnce(&mut [T], &mut Metrics)>(name: &str, arr: &mut [T], f: F) {
    let mut metrics = Metrics {
        comparisons: 0,
        swaps: 0,
    };

    let start = std::time::Instant::now();
    f(arr, &mut metrics);
    let elapsed = start.elapsed();

    println!(
        " {:<10} | Time: {} | Comparisons: {:<10} | Swaps: {:<10}",
        name,
        format!("{:>12?}", elapsed).green(),
        metrics.comparisons.to_string().green(),
        metrics.swaps.to_string().green()
    );
}

fn run_bench<F: Fn(&mut [usize], &mut Metrics)>(f: F) {
    for size in SIZES {
        let arr = (0..*size).collect::<Vec<_>>();

        let cases = [
            ("Sorted", arr.clone()),
            ("Reversed", arr.clone().into_iter().rev().collect()),
            ("Random", {
                let mut arr = arr.clone();
                arr.shuffle(&mut rand::rng());
                arr
            }),
        ];

        println!("\n{:^80}", format!("Array size: {}", arr.len()).yellow());
        println!("{}", "=".repeat(80).bright_black());

        for (case_name, mut data) in cases {
            run_alg(case_name, &mut data, &f);
        }

        println!("{}", "=".repeat(80).bright_black());
    }
}

fn run_tests() {
    for size in SIZES {
        let arr = {
            let mut v = (0..*size).collect::<Vec<_>>();
            v.shuffle(&mut rand::rng());
            v
        };

        println!("\n{:^80}", format!("Array size: {}", arr.len()).yellow());
        println!("{}", format!("{:=^80}", "").bright_black());

        run_alg("Bubble", &mut arr.clone(), bubble_sort);
        run_alg("Mod Bubble", &mut arr.clone(), modified_bubble_sort);
        run_alg("Shell", &mut arr.clone(), shell_sort);
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    if args.len() < 2 {
        eprintln!("Usage: {} <algorithm>", args[0]);
        std::process::exit(1);
    }

    let algorithm = &args[1];
    match algorithm.as_str() {
        "bubble" => run_bench(bubble_sort),
        "bubble-mod" => run_bench(modified_bubble_sort),
        "shell" => run_bench(shell_sort),
        "test" => run_tests(),
        _ => {
            eprintln!("Unknown algorithm: {}", algorithm);
            std::process::exit(1);
        }
    }
}
