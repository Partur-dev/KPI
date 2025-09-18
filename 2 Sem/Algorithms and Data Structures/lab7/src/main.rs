use rand::{Rng, distr::Alphanumeric};

fn pjw_hash(s: &str) -> u64 {
    let mut hash = 0;

    for c in s.chars() {
        hash = (hash << 4) + (c as u64);
        let test = hash & 0xF0000000;
        if test != 0 {
            hash ^= test >> 24;
            hash &= !test;
        }
    }

    hash
}

#[derive(Clone, Debug)]
struct Entry {
    key: String,
    value: String,
}

#[derive(Debug)]
pub struct HashTable {
    buckets: Vec<Option<Entry>>,
    size: usize,
}

impl HashTable {
    pub fn new(capacity: usize) -> Self {
        HashTable {
            buckets: vec![None; capacity],
            size: capacity,
        }
    }

    fn h1(&self, key: &str) -> usize {
        (pjw_hash(key) as usize) & (self.size - 1)
    }

    fn h2(&self, key: &str) -> usize {
        1 + ((pjw_hash(key) as usize) % (self.size - 1))
    }

    pub fn insert(&mut self, key: String, value: String) {
        let mut idx = self.h1(&key);
        let step = self.h2(&key);

        loop {
            match &mut self.buckets[idx] {
                Some(entry) if entry.key == key => {
                    entry.value = value;
                    return;
                }
                None => {
                    self.buckets[idx] = Some(Entry { key, value });
                    return;
                }
                _ => {
                    idx = (idx + step) % self.size;
                }
            }
        }
    }

    pub fn search(&self, key: &str) -> (Option<&str>, usize) {
        let mut comparisons = 0;
        let mut idx = self.h1(key);
        let step = self.h2(key);

        loop {
            comparisons += 1;
            match &self.buckets[idx] {
                Some(entry) if entry.key == key => {
                    return (Some(&entry.value), comparisons);
                }
                Some(_) => {
                    idx = (idx + step) % self.size;
                }
                None => {
                    return (None, comparisons);
                }
            }
        }
    }
}

fn generate_random_string(length: usize) -> String {
    rand::rng()
        .sample_iter(&Alphanumeric)
        .take(length)
        .map(char::from)
        .collect()
}

fn main() {
    let len = 1_000_000;
    let mut ht = HashTable::new(len * 5);

    for i in 0..len {
        let key = format!("key_{}", i);
        let value = generate_random_string(5);
        ht.insert(key, value);
    }

    let key = "key_42";
    let (res, comps) = ht.search(key);
    match res {
        Some(val) => {
            println!("Found `{}`: \"{}\" (comparisons: {})", key, val, comps);
        }
        None => {
            println!("Key `{}` not found (comparisons: {})", key, comps);
        }
    }
}
