use std::{
    fs::OpenOptions,
    io::{Read, Write},
    os::unix::net::UnixStream,
    sync::atomic::AtomicI32,
    time::Instant,
};

use controller::{Request, Sample};
use rapl_energy::{Probe, Rapl};

static COUNTER: AtomicI32 = AtomicI32::new(0);

pub struct MtdIterator<I: Iterator> {
    inner: I,
    stream: Option<UnixStream>,
    region_uid: i32,
    region_start: Option<(Instant, Rapl)>,
}

impl<I: Iterator> MtdIterator<I> {
    pub fn new(inner: I) -> Self {
        let counter = COUNTER.fetch_add(1, std::sync::atomic::Ordering::Relaxed);

        let stream = UnixStream::connect("/tmp/mtd_letterbox").ok();
        if stream.is_none() {
            eprintln!("WARN: no resource controller is running: using a fixed power limit")
        }

        Self {
            inner,
            stream,
            region_uid: counter,
            region_start: None,
        }
    }

    /// First send a signal that we are at the start of a parallel region.
    /// We don't actually care about the thread-count that we receive back.
    fn region_start(&mut self) -> (Instant, Rapl) {
        if let Some(stream) = &mut self.stream {
            stream.write_all(&Request {
                region_uid: self.region_uid,
                problem_size: 0,
            }.to_bytes()).unwrap();

            let mut buf = [0u8; 4];
            stream.read_exact(&mut buf).unwrap();
        }

        let rapl = Rapl::now(false).unwrap();
        let now = Instant::now();
        (now, rapl)
    }

    /// Signal an end of the region and send runtime and energy results.
    fn region_stop(&mut self, (now, rapl): (Instant, Rapl)) {
        let runtime = now.elapsed();
        let energy = rapl.elapsed();
        let runtime = runtime.as_secs_f32();
        let energy = energy.values().sum();
        let powercap = get_powercap();

        if let Some(stream) = &mut self.stream {
            stream.write_all(&Sample {
                region_uid: self.region_uid,
                runtime,
                usertime: 0.0,
                energy,
            }.to_bytes()).unwrap();
        }

        println!("{} {:.9} {:.9}", powercap, runtime, energy);
    }
}

impl<I: Iterator> Iterator for MtdIterator<I> {
    type Item = I::Item;

    fn next(&mut self) -> Option<Self::Item> {
        let item = self.inner.next();

        if item.is_some() {
            if let Some(region_start) = self.region_start.take() {
                // Send results of the previous region
                self.region_stop(region_start);
            } else {
                // First element; do nothing
            }

            self.region_start = Some(self.region_start());
        } else if let Some(stream) = &mut self.stream {
            // Last element; close connection
            stream.shutdown(std::net::Shutdown::Both).unwrap();
        }

        item
    }
}

fn get_powercap() -> u64 {
    const PATH: &str = "/sys/class/powercap/intel-rapl/intel-rapl:0/constraint_0_power_limit_uw";
    if let Ok(mut file) = OpenOptions::new().read(true).open(PATH) {
        let mut buf = String::new();
        file.read_to_string(&mut buf).unwrap();
        buf.trim().parse().unwrap()
    } else {
        0
    }
}
