//
//  TrailPathsManager.swift
//  AccuTerraSDK
//
// Created by Rudolf Kopřiva on 12/10/2025.
// Copyright (c) 2025 NeoTreks. All rights reserved.
//

import Foundation
import MapboxMaps
import AccuTerraSDK
import UIKit

///
/// An asynchronous task for initialization of a trails heads layer from a given source.
///
class TrailPathsManager {
    private var mapView: MapView
    private var trailService: ITrailService
    private let trailPathSource = "trails"
    private let trailPathLayer = "trail-paths"

    init(mapView: MapView) {
        self.mapView = mapView
        self.trailService = ServiceFactory.getTrailService()
    }

    func addToMap() async throws {
        var source = GeoJSONSource(id: trailPathSource)

        //Creating layer for trails overlay
        var lineLayer = LineLayer(id: trailPathLayer, source: trailPathSource)
        lineLayer.filter = Exp(.eq) {
            "$type"
            "LineString"
        }
        let difficulties = try ServiceFactory.getEnumService().getTechRatings().sorted { a, b in
            a.level < b.level
        }
        lineLayer.lineColor = .expression(
            Exp(.match) {
                Exp(.get) { TrailFeatureBuilder.difficultyLevelPropertyKey }
                difficulties[0].code
                UIColor.magenta
                difficulties[1].code
                UIColor.blue
                difficulties[2].code
                UIColor.orange
                difficulties[3].code
                UIColor.red
                difficulties[4].code
                UIColor.black // fallback color
                UIColor.darkGray // fallback color
            }
        )

        //lineLayer.lineColor = .constant(StyleColor(.red))
        lineLayer.lineWidth = .constant(2)

        // Create empty collection, update it later with showTrails or showAllTrails
        source.data = .featureCollection(FeatureCollection(features: []))

        try await MainActor.run {
            try self.mapView.mapboxMap.addSource(source)
            try self.mapView.mapboxMap.addLayer(lineLayer)
        }
    }

    func showTrailsFromFeatures(trails: Array<TrailBasicInfo>) async throws {
        let featureBuilder = TrailFeatureBuilder()
        let featureCollection = try await featureBuilder.buildFeatureCollection(trails: trails)

        // Update the source on the map
        await MainActor.run {
            self.mapView.mapboxMap.updateGeoJSONSource(withId: trailPathSource, geoJSON: .featureCollection(featureCollection))
        }
    }

    func showAllTrailsFromSDKCache() async throws {
        /// SDK is creating JSON file with all cached trail path Features. It can be used to quickly load trails
        let accuterraFileCacheDir = AccuTerraFiles.AccuTerraLibraryDirectory.appendingPathComponent("Files", isDirectory: true)
        if !FileManager.default.fileExists(atPath: accuterraFileCacheDir.path) {
            return
        }
        let accuterraTrailPathsCache = accuterraFileCacheDir.appendingPathComponent("accuterra-all-trail-paths-cache.json", isDirectory: false)
        if FileManager.default.fileExists(atPath: accuterraTrailPathsCache.path()) {
            // Update the source on the map
            await MainActor.run {
                self.mapView.mapboxMap.updateGeoJSONSource(withId: trailPathSource, data: .url(accuterraTrailPathsCache))
            }
        }
    }

    func removeFromMap() throws {
        try self.mapView.mapboxMap.removeLayer(withId: trailPathLayer)
        try self.mapView.mapboxMap.removeSource(withId: trailPathSource)
    }
}
