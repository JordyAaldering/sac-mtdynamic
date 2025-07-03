use std::hint::black_box;

use ndarray::{Array2, Array3, Axis, s};
use rayon::prelude::*;

const D: usize = 64;

fn stabilise(x: &Array2<f32>) -> Array2<f32> {
    let max_vals = x.map_axis(Axis(1), |row| row.fold(f32::NEG_INFINITY, |a, &b| a.max(b)));
    x - &max_vals.insert_axis(Axis(1))
}

fn exp(x: &Array2<f32>) -> Array2<f32> {
    x.mapv(|v| v.exp())
}

fn scale(x: &Array2<f32>) -> Array2<f32> {
    let sum_vals = x.sum_axis(Axis(1));
    x / &sum_vals.insert_axis(Axis(1))
}

fn matmul_t(a: &Array2<f32>, b_t: &Array2<f32>) -> Array2<f32> {
    a.dot(&b_t.t())
}

fn flash_attention(
    q: &Array3<f32>, // shape: [Nd, d, d]
    k: &Array2<f32>, // shape: [N, d]
    v: &Array2<f32>, // shape: [N, d]
) -> Array3<f32> {
    let nd = q.len_of(Axis(0));
    let d = v.len_of(Axis(1));
    let v_t = v.t().to_owned();

    let results: Vec<Array2<f32>> = (0..nd).into_par_iter().map(|i| {
        let q_i = q.slice(s![i, .., ..]).to_owned();
        let qk = matmul_t(&q_i, k);
        let stable = stabilise(&qk);
        let softmax = scale(&exp(&stable));
        matmul_t(&softmax, &v_t)
    }).collect();

    // Stack into Array3
    let mut result = Array3::<f32>::zeros((nd, d, d));
    for (i, mat) in results.into_iter().enumerate() {
        result.slice_mut(s![i, .., ..]).assign(&mat);
    }

    result
}

fn main() {
    let (num_threads, iter, size) = shared::get_args();

    rayon::ThreadPoolBuilder::new().num_threads(num_threads).build_global().unwrap();

    let q = Array3::from_shape_fn((size / D, D, D), |(i, _, _)| 1.0 / (1.0 + i as f32));
    let k = Array2::from_elem((size, D), 1.0);
    let v = Array2::from_elem((size, D), 1.0);

    for _ in shared::MtdIterator::new(0..iter) {
        black_box(flash_attention(&q, &k, &v));
    }
}
