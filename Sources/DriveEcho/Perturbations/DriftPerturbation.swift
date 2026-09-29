import Foundation

extension Perturbation {
    func applyDrift(to trace: Trace, meters: Double, over: Duration) -> Trace {
        let overSeconds = over.timeInterval
        let degreesPerMeter = 1.0 / 111_320.0

        var result = trace
        result.samples = trace.samples.map { sample in
            guard var loc = sample.location else { return sample }
            let progress = overSeconds > 0 ? min(sample.t / overSeconds, 1.0) : 1.0
            loc.lat += meters * degreesPerMeter * progress
            var modified = sample
            modified.location = loc
            return modified
        }
        return result
    }
}
