use std::{io::{Read, Write}, os::unix::net::UnixStream, time::Instant};

use rapl_energy::{Probe, Rapl};

pub struct DynamicRegion {
    stream: UnixStream,
    rapl: Rapl,
    now: Instant,
}

impl DynamicRegion {
    pub fn init() -> Self {
        Self {
            stream: UnixStream::connect("/tmp/mtd_letterbox").unwrap(),
            rapl: Rapl::now(false).unwrap(),
            now: Instant::now(),
        }
    }

    /// First send a signal that we are at the start of a parallel region.
    /// We don't actually care about the thread-count that we receive back.
    pub fn region_start(&mut self) {
        let [i0, i1, i2, i3] = 0i32.to_ne_bytes();
        let [t0, t1, t2, t3] = 1i32.to_ne_bytes();
        let msg = [i0, i1, i2, i3, t0, t1, t2, t3];
        self.stream.write_all(&msg).unwrap();

        let mut buf = [0u8; 4];
        self.stream.read_exact(&mut buf).unwrap();

        self.rapl.reset();
        self.now = Instant::now();
    }

    /// Signal an end of the region and send runtime and energy results.
    pub fn region_end(&mut self) {
        let runtime = self.now.elapsed();
        let energy = self.rapl.elapsed();
        let msg = create_sample(runtime.as_secs_f32(), energy.values().sum());
        self.stream.write_all(&msg).unwrap();
    }
}

fn create_sample(runtime: f32, energy: f32) -> [u8; 16] {
    let [i0, i1, i2, i3] = 0i32.to_ne_bytes();
    let [r0, r1, r2, r3] = runtime.to_ne_bytes();
    let [u0, u1, u2, u3] = 0f32.to_ne_bytes();
    let [e0, e1, e2, e3] = energy.to_ne_bytes();
    [i0, i1, i2, i3,
     r0, r1, r2, r3,
     u0, u1, u2, u3,
     e0, e1, e2, e3]
}
