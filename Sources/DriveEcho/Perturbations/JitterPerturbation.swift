import Foundation

extension Perturbation {
    func applyJitter(to trace: Trace, sigmaMeters: Double, seed: UInt64) -> Trace {
        var rng = SplitMix64(seed: seed)
        let degreesPerMeter = 1.0 / 111_320.0

        var result = trace
        result.samples = trace.samples.map { sample in
            guard var loc = sample.location else { return sample }
            let (dx, dy) = gaussianPair(using: &rng)
            loc.lat += dx * sigmaMeters * degreesPerMeter
            let lonDegreesPerMeter = 1.0 / (111_320.0 * cos(loc.lat * .pi / 180))
            loc.lon += dy * sigmaMeters * lonDegreesPerMeter
            var modified = sample
            modified.location = loc
            return modified
        }
        return result
    }
}

// MARK: - Deterministic PRNG

/// A fast, deterministic pseudo-random number generator.
struct SplitMix64: Sendable {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e37_79b9_7f4a_7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58_476d_1ce4_e5b9
        z = (z ^ (z >> 27)) &* 0x94d0_49bb_1331_11eb
        z = z ^ (z >> 31)
        return z
    }

    mutating func nextDouble() -> Double {
        Double(next() >> 11) * 0x1.0p-53
    }
}

/// Generate a pair of Gaussian-distributed random numbers using the Box-Muller transform.
func gaussianPair(using rng: inout SplitMix64) -> (Double, Double) {
    let u1 = max(rng.nextDouble(), 1e-10)
    let u2 = rng.nextDouble()
    let mag = (-2.0 * log(u1)).squareRoot()
    return (mag * cos(2 * .pi * u2), mag * sin(2 * .pi * u2))
}
