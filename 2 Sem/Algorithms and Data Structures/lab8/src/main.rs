use std::fmt;

#[derive(Debug)]
enum TspError {
    EmptyGraph,
    InvalidStartCity,
    NoValidPath,
    InvalidDistanceMatrix,
}

impl fmt::Display for TspError {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        match self {
            TspError::EmptyGraph => write!(f, "Empty graph provided"),
            TspError::InvalidStartCity => write!(f, "Invalid start city index"),
            TspError::NoValidPath => write!(f, "No valid path found"),
            TspError::InvalidDistanceMatrix => write!(f, "Invalid distance matrix"),
        }
    }
}

fn validate_distance_matrix(dist: &[Vec<u32>]) -> Result<(), TspError> {
    if dist.is_empty() {
        return Err(TspError::EmptyGraph);
    }

    let n = dist.len();
    for row in dist {
        if row.len() != n {
            return Err(TspError::InvalidDistanceMatrix);
        }
    }

    // symmetric and diagonal == zero
    for i in 0..n {
        if dist[i][i] != 0 {
            return Err(TspError::InvalidDistanceMatrix);
        }
        for j in 0..n {
            if dist[i][j] != dist[j][i] {
                return Err(TspError::InvalidDistanceMatrix);
            }
        }
    }

    Ok(())
}

fn find_nearest_neighbor_tour(
    dist: &[Vec<u32>],
    start: usize,
) -> Result<(Vec<usize>, u32), TspError> {
    validate_distance_matrix(dist)?;

    let n = dist.len();
    if start >= n {
        return Err(TspError::InvalidStartCity);
    }

    let mut visited = vec![false; n];
    let mut tour = Vec::with_capacity(n + 1);
    let mut total_dist = 0u32;

    let mut current = start;
    visited[current] = true;
    tour.push(current);

    for _ in 1..n {
        let mut next_city = None;
        let mut best_distance = u32::MAX;

        for (j, &is_visited) in visited.iter().enumerate() {
            if !is_visited && dist[current][j] > 0 && dist[current][j] < best_distance {
                best_distance = dist[current][j];
                next_city = Some(j);
            }
        }

        let next = next_city.ok_or(TspError::NoValidPath)?;
        visited[next] = true;
        total_dist = total_dist
            .checked_add(best_distance)
            .ok_or(TspError::NoValidPath)?;
        tour.push(next);
        current = next;
    }

    if dist[current][start] == 0 {
        return Err(TspError::NoValidPath);
    }

    total_dist = total_dist
        .checked_add(dist[current][start])
        .ok_or(TspError::NoValidPath)?;
    tour.push(start);

    Ok((tour, total_dist))
}

fn main() {
    let cities = vec![
        "Amsterdam",
        "Rotterdam",
        "Den Haag",
        "Utrecht",
        "Eindhoven",
        "Tilburg",
        "Groningen",
        "Breda",
        "Nijmegen",
        "Enschede",
        "Apeldoorn",
        "Haarlem",
        "Arnhem",
        "Amersfoort",
        "Maastricht",
    ];

    #[rustfmt::skip]
    let dist: Vec<Vec<u32>> = vec![
        //    Ams   Rot   DHA   Utr   Eind  Tilb  Gron  Breda  Nijm  Ens   Apel   Haar   Arn   Amfs  Maast
        vec![  0,   80,   60,   45,   125,  115,  180,  120,   130,  170,   100,   20,   130,   75,   215 ], // Amsterdam
        vec![  80,  0,    25,   65,   115,   95,  255,   55,   115,  215,   150,  100,   185,  120,   185 ], // Rotterdam
        vec![  60,  25,    0,   75,   130,  110,  270,   75,   135,  230,   160,   65,   180,  130,   195 ], // Den Haag
        vec![  45,  65,   75,    0,   115,  100,  200,  110,    90,  150,    50,   65,    75,   20,   180 ], // Utrecht
        vec![ 125, 115,  130,  115,     0,   25,  240,   65,    80,  165,   140,  185,   125,  135,    80 ], // Eindhoven
        vec![ 115,  95,  110,  100,    25,    0,  260,   35,   115,  195,   155,  150,   145,  140,    95 ], // Tilburg
        vec![ 180, 255,  270,  200,   240,  260,    0,  300,   190,  175,   170,  210,   180,  170,   345 ], // Groningen
        vec![ 120,  55,   75,  110,    65,   35,  300,    0,   105,  205,   165,  115,   155,  130,   120 ], // Breda
        vec![ 130, 115,  135,   90,    80,  115,  190,  105,     0,  120,    95,  170,    25,  105,   160 ], // Nijmegen
        vec![ 170, 215,  230,  150,   165,  195,  175,  205,   120,    0,   115,  195,   145,  130,   265 ], // Enschede
        vec![ 100, 150,  160,   50,   140,  155,  170,  165,    95,  115,     0,  115,    60,   55,   200 ], // Apeldoorn
        vec![  20, 100,   65,   65,   185,  150,  210,  115,   170,  195,   115,    0,   145,   85,   225 ], // Haarlem
        vec![ 130, 185,  180,   75,   125,  145,  180,  155,    25,  145,    60,  145,     0,   65,   180 ], // Arnhem
        vec![  75, 120,  130,   20,   135,  140,  170,  130,   105,  130,    55,   85,    65,    0,   175 ], // Amersfoort
        vec![ 215, 185,  195,  180,    80,   95,  345,  120,   160,  265,   200,  225,   180,  175,     0 ], // Maastricht
    ];

    match find_nearest_neighbor_tour(&dist, 0) {
        Ok((tour, total_dist)) => {
            print!("Path: ");
            for (i, &idx) in tour.iter().enumerate() {
                if i > 0 {
                    print!(" → ");
                }
                print!("{}", cities[idx]);
            }
            println!(", Length: {} km", total_dist);
        }
        Err(e) => {
            eprintln!("Error: {}", e);
        }
    }
}
