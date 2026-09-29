import Foundation

extension Trace {
    /// Import a trace from a GPX file. Only location data is imported (no motion).
    /// - Parameter gpxURL: URL to a GPX file.
    public init(gpxURL url: URL) throws {
        let data = try Data(contentsOf: url)
        let parser = GPXParser(data: data)
        let points = try parser.parse()

        guard !points.isEmpty else {
            self.init(device: "GPX Import", recordedAt: .now, samples: [])
            return
        }

        let baseDate = points.first?.time ?? Date()
        let samples = points.enumerated().map { index, point in
            let t: TimeInterval
            if let time = point.time {
                t = time.timeIntervalSince(baseDate)
            } else {
                t = Double(index)
            }
            return Sample(
                t: t,
                location: LocationSample(
                    lat: point.lat,
                    lon: point.lon,
                    alt: point.elevation ?? 0,
                    hAcc: point.hdop.map { $0 * 5.0 } ?? 10.0,
                    speed: 0,
                    course: 0
                ),
                motion: nil
            )
        }

        self.init(device: "GPX Import", recordedAt: baseDate, samples: samples)
    }
}

// MARK: - GPX Parser

struct GPXPoint {
    var lat: Double
    var lon: Double
    var elevation: Double?
    var time: Date?
    var hdop: Double?
}

/// Minimal GPX parser using Foundation's XMLParser.
final class GPXParser: NSObject, XMLParserDelegate {
    private let data: Data
    private var points: [GPXPoint] = []
    private var currentElement: String = ""
    private var currentText: String = ""
    private var currentLat: Double?
    private var currentLon: Double?
    private var currentElevation: Double?
    private var currentTime: Date?
    private var currentHdop: Double?
    private var inTrackPoint = false
    private var parseError: Error?

    private static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let dateFormatterNoFrac: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    init(data: Data) {
        self.data = data
    }

    func parse() throws -> [GPXPoint] {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        if let error = parseError ?? parser.parserError {
            throw error
        }
        return points
    }

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes: [String: String]
    ) {
        currentElement = elementName
        currentText = ""

        if elementName == "trkpt" || elementName == "wpt" || elementName == "rtept" {
            inTrackPoint = true
            currentLat = attributes["lat"].flatMap(Double.init)
            currentLon = attributes["lon"].flatMap(Double.init)
            currentElevation = nil
            currentTime = nil
            currentHdop = nil
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        guard inTrackPoint else { return }

        let text = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        switch elementName {
        case "ele":
            currentElevation = Double(text)
        case "time":
            currentTime = Self.dateFormatter.date(from: text)
                ?? Self.dateFormatterNoFrac.date(from: text)
        case "hdop":
            currentHdop = Double(text)
        case "trkpt", "wpt", "rtept":
            if let lat = currentLat, let lon = currentLon {
                points.append(GPXPoint(
                    lat: lat,
                    lon: lon,
                    elevation: currentElevation,
                    time: currentTime,
                    hdop: currentHdop
                ))
            }
            inTrackPoint = false
        default:
            break
        }
    }
}
