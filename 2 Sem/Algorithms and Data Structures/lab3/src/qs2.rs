fn median_of_three(a: usize, b: usize, c: usize) -> usize {
    if (a > b) ^ (a > c) {
        a
    } else if (b > a) ^ (b > c) {
        b
    } else {
        c
    }
}

fn sort_small(slice: &mut [usize], cmp: &mut usize) {
    for i in 0..slice.len() {
        for j in i + 1..slice.len() {
            *cmp += 1;
            if slice[i] > slice[j] {
                slice.swap(i, j);
            }
        }
    }
}

fn partition(slice: &mut [usize], cmp: &mut usize) -> usize {
    let len = slice.len();
    let mid = (len - 1) / 2;
    let piv_val = median_of_three(slice[0], slice[mid], slice[len - 1]);

    let piv_idx = if piv_val == slice[0] {
        0
    } else if piv_val == slice[mid] {
        mid
    } else {
        len - 1
    };

    slice.swap(piv_idx, len - 1);

    let pivot = slice[len - 1];
    let mut i = 0;

    for j in 0..len - 1 {
        *cmp += 1;
        if slice[j] <= pivot {
            slice.swap(i, j);
            i += 1;
        }
    }

    slice.swap(i, len - 1);
    i
}

pub fn sort(slice: &mut [usize]) -> usize {
    let mut cmp = 0;
    let len = slice.len();

    if len <= 3 {
        sort_small(slice, &mut cmp);
    } else {
        let p = partition(slice, &mut cmp);
        cmp += sort(&mut slice[..p]);
        cmp += sort(&mut slice[p + 1..]);
    }

    cmp
}
