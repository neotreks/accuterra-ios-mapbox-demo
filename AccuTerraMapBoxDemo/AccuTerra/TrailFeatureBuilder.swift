//
// Created by Rudolf Kopřiva on 12/10/2025.
// Copyright (c) 2025 NeoTreks. All rights reserved.
//

import Foundation
import MapboxMaps
import AccuTerraSDK
import MapLibre

/// Build geoJson with trail paths features
class TrailFeatureBuilder {

    static let difficultyLevelPropertyKey = "difficulty-level"
    private var trailService: ITrailService
    private let decoder = JSONDecoder()

    init() {
        self.trailService = ServiceFactory.getTrailService()
    }

    func buildFeatureCollection(trails: Array<TrailBasicInfo>) async throws -> FeatureCollection {
        let ids = trails.map { $0.id }
        let trailsPaths = try trailService.getTrailsPaths(trailLoadFilter: TrailLoadFilter(trailIds: Array(ids)))
        // The geometry here is the best available geometry for the trail.
        // To get higher resolution geometry, consider using `trailService.downloadFullTrailPath` method.
        let features = try trailsPaths.map { path in
            try parseTrailFeature(trailPath: path, trail: trails.first { $0.id == path.trailId })
        }
        let featureCollection = FeatureCollection(features: features)
        return featureCollection
    }

    private func parseTrailFeature(trailPath: TrailPath, trail: TrailBasicInfo?) throws -> Feature {
        guard let data = trailPath.geojson.data(using: .utf8) else {
            throw "Cannot parse trail Feature from GeoJson: \(trailPath.geojson)".toError()
        }

        var decoded = try decoder.decode(Feature.self, from: data)
        var properties = decoded.properties ?? JSONObject()
        properties["trailId"] = .number(.init(trailPath.trailId))

        if let trail = trail {
            properties["name"] = .string(trail.name)
            properties[Self.difficultyLevelPropertyKey] = .string(trail.techRatingHigh.code)
            // ...
        }
        decoded.properties = properties

        return decoded
    }

}
