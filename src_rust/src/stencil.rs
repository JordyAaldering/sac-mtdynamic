use rayon::prelude::*;

pub struct Matrix {
    rows: usize,
    cols: usize,
    data: Vec<f64>,
}

impl Matrix {
    pub fn iota(rows: usize, cols: usize) -> Self {
        let data = (0..(rows * cols)).map(|x| x as f64).collect();
        Self { rows, cols, data }
    }

    fn stencil(self) -> Matrix {
        let rows = self.rows;
        let cols = self.cols;

        let data = (0..rows).into_par_iter().flat_map(|row_idx| {
            (0..cols).map(|col_idx| {
                let mut sum = 0.0;

                for dy in -1..=1 {
                    for dx in -1..=1 {
                        let x = ((row_idx as isize + dx + rows as isize) as usize) % rows;
                        let y = ((col_idx as isize + dy + cols as isize) as usize) % cols;
                        sum += self.data[x + y * rows];
                    }
                }

                sum / 9.0
            }).collect::<Vec<f64>>()
        }).collect();

        Matrix { rows, cols, data }
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let iter: usize = args[1].parse().unwrap();
    let size: usize = args[2].parse().unwrap();
    let num_threads: usize = args[3].parse().unwrap();

    rayon::ThreadPoolBuilder::new().num_threads(num_threads).build_global().unwrap();

    let mut arr = Matrix::iota(size, size);

    for _ in 0..iter {
        let mtd_start = shared::region_start();

        arr = arr.stencil();

        shared::region_stop(mtd_start);
    }
}
