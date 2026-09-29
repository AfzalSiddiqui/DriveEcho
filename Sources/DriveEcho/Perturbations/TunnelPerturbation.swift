import Foundation

extension Perturbation {
    func applyTunnel(to trace: Trace, start: Duration, duration: Duration) -> Trace {
        let startSeconds = start.timeInterval
        let endSeconds = startSeconds + duration.timeInterval

        var result = trace
        result.samples = trace.samples.map { sample in
            if sample.t >= startSeconds && sample.t < endSeconds {
                var modified = sample
                modified.location = nil
                return modified
            }
            return sample
        }
        return result
    }
}
