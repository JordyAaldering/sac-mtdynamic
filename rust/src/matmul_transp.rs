use std::hint::black_box;

use rayon::prelude::*;

pub struct Matrix {
    rows: usize,
    cols: usize,
    data: Vec<Vec<f64>>,
}

impl Matrix {
    pub fn iota(rows: usize, cols: usize) -> Matrix {
        let data = (0..cols).map(|y| {
            (0..rows).map(|x| (x + y * rows) as f64).collect()
        }).collect();
        Matrix { rows, cols, data }
    }

    /// { [i,j] -> b[j,i] | [i,j] < [n,k] }
    pub fn transpose(self) -> Matrix {
        let data = (0..self.cols).map(|x| {
            (0..self.rows).map(|y| {
                self.data[y][x]
            }).collect()
        }).collect();
        Matrix { rows: self.cols, cols: self.rows, data }
    }

    /// { [i,j] -> sum(a[i] * bT[j]) | [i,j] < [m,n] }
    pub fn mul(&self, other: &Matrix) -> Matrix {
        let mut data = vec![vec![0.0; self.rows]; other.rows];

        data.par_iter_mut().for_each(|row| {
            for y in 0..other.rows {
                let other_row = &other.data[y];
                for i in 0..self.cols {
                    row[y] += row[i] * other_row[i];
                }
            }
        });

        Matrix { rows: self.rows, cols: other.cols, data }
    }
}

fn main() {
    let (num_threads, iter, size) = shared::get_args();

    rayon::ThreadPoolBuilder::new().num_threads(num_threads).build_global().unwrap();

    let x = Matrix::iota(size, size);
    // We only want to measure/control the multiplication part, so transpose beforehand
    let y_t = Matrix::iota(size, size).transpose();

    for _ in shared::MtdIterator::new(0..iter) {
        black_box(x.mul(&y_t));
    }
}
