import Foundation

extension Trace {
    /// Apply a sequence of perturbations and return a new trace.
    ///
    /// Perturbations are applied in order, so each one operates on the
    /// result of the previous one.
    public func perturbed(with perturbations: [Perturbation]) -> Trace {
        perturbations.reduce(self) { trace, perturbation in
            perturbation.apply(to: trace)
        }
    }
}

extension Perturbation {
    func apply(to trace: Trace) -> Trace {
        switch self {
        case .tunnel(let start, let duration):
            return applyTunnel(to: trace, start: start, duration: duration)
        case .drift(let meters, let over):
            return applyDrift(to: trace, meters: meters, over: over)
        case .jitter(let sigma, let seed):
            return applyJitter(to: trace, sigmaMeters: sigma, seed: seed)
        }
    }
}

// MARK: - Duration Helpers

extension Duration {
    /// Convert to `TimeInterval` (seconds as `Double`).
    var timeInterval: TimeInterval {
        let (seconds, attoseconds) = self.components
        return Double(seconds) + Double(attoseconds) / 1e18
    }
}
