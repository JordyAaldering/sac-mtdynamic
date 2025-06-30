use std::hint::black_box;
use std::ops::{Add, Sub, Mul, AddAssign, SubAssign};

use shared::MtdIterator;

#[derive(Clone, Debug)]
struct Body {
    position: Vec3D,
    velocity: Vec3D,
    mass: f64,
}

#[derive(Clone, Debug)]
struct Vec3D(f64, f64, f64);

impl Vec3D {
    fn sum_squares(&self) -> f64 {
        self.0 * self.0
            + self.1 * self.1
            + self.2 * self.2
    }

    fn magnitude(&self, dt: f64) -> f64 {
        let sum = self.sum_squares();
        dt / (sum * sum.sqrt())
    }
}

impl Add for &Vec3D {
    type Output = Vec3D;
    fn add(self, rhs: Self) -> Self::Output {
        Vec3D(
            self.0 + rhs.0,
            self.1 + rhs.1,
            self.2 + rhs.2
        )
    }
}

impl Sub for &Vec3D {
    type Output = Vec3D;
    fn sub(self, rhs: Self) -> Self::Output {
        Vec3D(
            self.0 - rhs.0,
            self.1 - rhs.1,
            self.2 - rhs.2
        )
    }
}

impl Mul<f64> for &Vec3D {
    type Output = Vec3D;
    fn mul(self, rhs: f64) -> Self::Output {
        Vec3D(
            self.0 * rhs,
            self.1 * rhs,
            self.2 * rhs
        )
    }
}

impl AddAssign for Vec3D {
    fn add_assign(&mut self, rhs: Self) {
        self.0 += rhs.0;
        self.1 += rhs.1;
        self.2 += rhs.2;
    }
}

impl SubAssign for Vec3D {
    fn sub_assign(&mut self, rhs: Self) {
        self.0 -= rhs.0;
        self.1 -= rhs.1;
        self.2 -= rhs.2;
    }
}

/// Steps the simulation forward by one time-step.
fn advance(bodies: &mut Vec<Body>, dt: f64) {
    let interactions = bodies.len() * (bodies.len() - 1) / 2;
    let mut d_positions = vec![Vec3D(0.0, 0.0, 0.0); interactions];
    let mut magnitudes = vec![0.0; interactions];

    // Vectors between each pair of bodies.
    let mut k = 0;
    for (i, body1) in bodies.iter().enumerate() {
        for body2 in &bodies[i + 1..] {
            d_positions[k] = &body1.position - &body2.position;
            k += 1;
        }
    }

    // Magnitude between each pair of bodies.
    for (mag, d_pos) in magnitudes.iter_mut().zip(d_positions.iter()) {
        *mag = d_pos.magnitude(dt);
    };

    // Apply every other body's gravitation to each body's velocity.
    let mut k = 0;
    for i in 0..bodies.len() - 1 {
        let (body1, rest) = bodies[i..].split_first_mut().unwrap();
        for body2 in rest {
            let d_pos = &d_positions[k];
            let mag = magnitudes[k];
            body1.velocity -= d_pos * (body2.mass * mag);
            body2.velocity += d_pos * (body1.mass * mag);
            k += 1;
        }
    }

    // Update positions
    for body in bodies.iter_mut() {
        body.position += &body.velocity * dt;
    }
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let iter: usize = args[1].parse().unwrap();
    let size: usize = args[2].parse().unwrap();
    let num_threads: usize = args[3].parse().unwrap();

    rayon::ThreadPoolBuilder::new().num_threads(num_threads).build_global().unwrap();

    let mut bodies = (0..size).map(|i| {
        Body {
            position: Vec3D(i as f64, (i * 2) as f64, (i * 3) as f64),
            velocity: Vec3D(0.0, 0.0, 0.0),
            mass: 1.0,
        }
    }).collect();

    for _ in MtdIterator::new(0..iter) {
        black_box(advance(&mut bodies, 0.01));
    }
}
