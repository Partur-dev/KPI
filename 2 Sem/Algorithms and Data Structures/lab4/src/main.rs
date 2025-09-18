use std::env;
use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;

fn tarry_traversal(adj_matrix: &[Vec<u8>], start: usize, end: usize) -> Option<Vec<usize>> {
    let n = adj_matrix.len();
    if start >= n || end >= n {
        return None;
    }

    let mut edge_mark = vec![vec![false; n]; n];
    let mut path = Vec::new();

    fn dfs(
        u: usize,
        end: usize,
        adj: &[Vec<u8>],
        edge_mark: &mut Vec<Vec<bool>>,
        path: &mut Vec<usize>,
    ) -> bool {
        path.push(u);
        if u == end {
            return true;
        }

        let n = adj.len();
        for v in 0..n {
            if adj[u][v] == 1 && !edge_mark[u][v] {
                edge_mark[u][v] = true;
                edge_mark[v][u] = true;

                if dfs(v, end, adj, edge_mark, path) {
                    return true;
                }
            }
        }

        path.pop();
        false
    }

    if dfs(start, end, adj_matrix, &mut edge_mark, &mut path) {
        Some(path)
    } else {
        None
    }
}

fn main() {
    let args: Vec<String> = env::args().collect();
    let (start, end) = get_start_and_end(&args).unwrap();

    let path = "data.txt";
    let mut adj_matrix = Vec::new();
    if let Ok(lines) = read_lines(path) {
        for line in lines.flatten() {
            let row: Vec<u8> = line
                .split_whitespace()
                .filter_map(|s| s.parse::<u8>().ok())
                .collect();

            adj_matrix.push(row);
        }
    } else {
        println!("Failed to open file: {}", path);
        return;
    }

    if let Some(path) = tarry_traversal(&adj_matrix, start - 1, end - 1) {
        println!(
            "Path found: {:?}",
            path.iter().map(|x| x + 1).collect::<Vec<_>>()
        );
    } else {
        println!("No path found.");
    }
}

fn get_start_and_end(args: &[String]) -> Result<(usize, usize), String> {
    if args.len() >= 3 {
        Ok((
            args[1]
                .parse::<usize>()
                .map_err(|_| "Invalid start index".to_string())?,
            args[2]
                .parse::<usize>()
                .map_err(|_| "Invalid end index".to_string())?,
        ))
    } else {
        Err("Usage: <program> <start> <end>".to_string())
    }
}

fn read_lines<P>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>>
where
    P: AsRef<Path>,
{
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}
