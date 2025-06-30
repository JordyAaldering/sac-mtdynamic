use rayon::prelude::*;
use shared::MtdIterator;

pub struct Matrix {
    rows: usize,
    cols: usize,
    data: Vec<Vec<f64>>,
}

impl Matrix {
    pub fn iota(rows: usize, cols: usize) -> Self {
        let data = (0..cols).map(|y| {
            (0..rows).map(|x| (x + y * rows) as f64).collect()
        }).collect();
        Self { rows, cols, data }
    }

    /// { [i,j] -> b[j,i] | [i,j] < [n,k] }
    pub fn transpose(&self) -> Self {
        let data = (0..self.cols).map(|x| {
            (0..self.rows).map(|y| {
                self.data[y][x]
            }).collect()
        }).collect();
        Self { rows: self.cols, cols: self.rows, data }
    }

    /// { [i,j] -> sum(a[i] * bT[j]) | [i,j] < [m,n] }
    pub fn mul(self, other: &Self) -> Self {
        let mut data = vec![vec![0.0; self.rows]; other.rows];

        data.par_iter_mut().for_each(|row| {
            for y in 0..other.rows {
                let other_row = &other.data[y];
                for i in 0..self.cols {
                    row[y] += row[i] * other_row[i];
                }
            }
        });

        Self { rows: self.rows, cols: other.cols, data }
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let iter: usize = args[1].parse().unwrap();
    let size: usize = args[2].parse().unwrap();
    let num_threads: usize = args[3].parse().unwrap();

    rayon::ThreadPoolBuilder::new().num_threads(num_threads).build_global().unwrap();

    let mut x = Matrix::iota(size, size);
    let y = Matrix::iota(size, size);
    // We only want to measure/control the multiplication part, so transpose beforehand
    let y_t = y.transpose();

    for _ in MtdIterator::new(0..iter) {
        x = x.mul(&y_t);
    }
}
