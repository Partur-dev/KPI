use std::io::BufRead;

mod qs1;
mod qs2;

fn main() {
    let file_path = "./data/input_03_10.txt";
    let file = std::fs::File::open(file_path).expect("Unable to open file");
    let reader = std::io::BufReader::new(file);
    let data: Vec<_> = reader
        .lines()
        .skip(1)
        .filter_map(|line| line.ok())
        .filter_map(|line| line.parse::<usize>().ok())
        .collect();

    let comp1 = qs1::sort(&mut data.clone());
    let comp2 = qs2::sort(&mut data.clone());

    println!("{} {}", comp1, comp2);
}
