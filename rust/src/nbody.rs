use std::f64;
use std::hint::black_box;
use std::ops::{Add, Sub, Mul, AddAssign, SubAssign};

use rayon::prelude::*;
use shared::MtdIterator;

#[derive(Clone, Debug)]
struct Body {
    pos: Vec3d,
    vel: Vec3d,
    mass: f64,
}

#[derive(Copy, Clone, Debug)]
struct Vec3d(f64, f64, f64);

impl Add for Vec3d {
    type Output = Vec3d;
    fn add(self, rhs: Self) -> Self::Output {
        Vec3d(
            self.0 + rhs.0,
            self.1 + rhs.1,
            self.2 + rhs.2
        )
    }
}

impl Sub for Vec3d {
    type Output = Vec3d;
    fn sub(self, rhs: Self) -> Self::Output {
        Vec3d(
            self.0 - rhs.0,
            self.1 - rhs.1,
            self.2 - rhs.2
        )
    }
}

impl Mul<f64> for Vec3d {
    type Output = Vec3d;
    fn mul(self, rhs: f64) -> Self::Output {
        Vec3d(
            self.0 * rhs,
            self.1 * rhs,
            self.2 * rhs
        )
    }
}

impl AddAssign for Vec3d {
    fn add_assign(&mut self, rhs: Self) {
        self.0 += rhs.0;
        self.1 += rhs.1;
        self.2 += rhs.2;
    }
}

impl SubAssign for Vec3d {
    fn sub_assign(&mut self, rhs: Self) {
        self.0 -= rhs.0;
        self.1 -= rhs.1;
        self.2 -= rhs.2;
    }
}

fn pow3(x: f64) -> f64 {
    x * x * x
}

fn l2norm(v: Vec3d) -> f64 {
    (v.0 * v.0 + v.1 * v.1 + v.2 * v.2).sqrt()
}

fn acc(b: &Body, b2: &Body) -> Vec3d {
    let dir = b2.pos - b.pos;
    let norm = l2norm(dir);
    dir * (b2.mass / pow3(f64::EPSILON + norm))
}

fn time_step(bodies: &mut Vec<Body>, dt: f64) {
    let acc = bodies.par_iter()
        .map(|b| {
            bodies.iter()
                .filter(|&b2| !std::ptr::eq(b, b2))
                .map(|b2| acc(b, b2))
                .fold(Vec3d(0.0, 0.0, 0.0), |a, b| a + b)
        }).collect::<Vec<_>>();

    bodies.par_iter_mut()
        .zip(acc)
        .for_each(|(body, acc)| {
            body.vel += acc * dt;
            body.pos += body.vel * dt;
        });
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let iter: usize = args[1].parse().unwrap();
    let size: usize = args[2].parse().unwrap();
    let num_threads: usize = args[3].parse().unwrap();

    rayon::ThreadPoolBuilder::new().num_threads(num_threads).build_global().unwrap();

    let mut bodies = (0..size).map(|i| {
        Body {
            pos: Vec3d(i as f64, (i * 2) as f64, (i * 3) as f64),
            vel: Vec3d(0.0, 0.0, 0.0),
            mass: 1.0,
        }
    }).collect();

    for _ in MtdIterator::new(0..iter) {
        black_box(time_step(&mut bodies, 0.01));
    }
}
