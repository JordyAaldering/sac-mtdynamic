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

    /// { [i,j] -> sum({ [p] -> a[i,p] * b[p,j] }) }
    pub fn mul(&self, other: &Matrix) -> Matrix {
        let mut data = vec![vec![0.0; self.rows]; other.cols];

        data.par_iter_mut().enumerate().for_each(|(x, row)| {
            for y in 0..other.cols {
                for i in 0..self.cols {
                    row[y] += self.data[x][i] * other.data[i][y];
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
    let y = Matrix::iota(size, size);

    for _ in shared::MtdIterator::new(0..iter) {
        black_box(x.mul(&y));
    }
}
