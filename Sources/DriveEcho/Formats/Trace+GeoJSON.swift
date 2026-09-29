import Foundation

extension Trace {
    /// Export the trace as a GeoJSON Feature with a LineString geometry.
    ///
    /// GeoJSON coordinates use `[longitude, latitude, altitude]` order
    /// per RFC 7946.
    public func geoJSON() throws -> Data {
        let coordinates: [[Double]] = samples.compactMap { sample in
            guard let loc = sample.location else { return nil }
            return [loc.lon, loc.lat, loc.alt]
        }

        let geoJSON: [String: Any] = [
            "type": "Feature",
            "geometry": [
                "type": "LineString",
                "coordinates": coordinates,
            ] as [String: Any],
            "properties": [
                "device": device,
                "recordedAt": ISO8601DateFormatter().string(from: recordedAt),
                "sampleCount": samples.count,
            ] as [String: Any],
        ]

        return try JSONSerialization.data(
            withJSONObject: geoJSON,
            options: [.prettyPrinted, .sortedKeys]
        )
    }
}
