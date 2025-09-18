fn partition(slice: &mut [usize], cmp: &mut usize) -> usize {
    let len = slice.len();
    let pivot = slice[len - 1];
    let mut i = 0;

    for j in 0..len - 1 {
        *cmp += 1;
        if slice[j] < pivot {
            slice.swap(i, j);
            i += 1;
        }
    }

    slice.swap(i, len - 1);
    i
}

pub fn sort(slice: &mut [usize]) -> usize {
    let mut cmp = 0;

    if !slice.is_empty() {
        let partition_index = partition(slice, &mut cmp);
        let len = slice.len();

        cmp += sort(&mut slice[0..partition_index]);
        cmp += sort(&mut slice[partition_index + 1..len]);
    }

    cmp
}
