import Foundation

extension Trace {
    /// Encoder configured for the DriveEcho JSON format.
    static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    /// Decoder configured for the DriveEcho JSON format.
    static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    /// Load a trace from a JSON file on disk.
    public init(contentsOf url: URL) throws {
        let data = try Data(contentsOf: url)
        self = try Self.jsonDecoder.decode(Trace.self, from: data)
    }

    /// Load a trace from in-memory JSON data.
    public init(jsonData: Data) throws {
        self = try Self.jsonDecoder.decode(Trace.self, from: jsonData)
    }

    /// Serialize to JSON data.
    public func jsonData() throws -> Data {
        try Self.jsonEncoder.encode(self)
    }

    /// Write the trace to a JSON file on disk.
    public func write(to url: URL) throws {
        let data = try jsonData()
        try data.write(to: url, options: .atomic)
    }
}
