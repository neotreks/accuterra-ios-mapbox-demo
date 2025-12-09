//
//  AccuTerraStyleURL.swift
//  AccuTerraMapBoxDemo
//
// Created by Rudolf Kopřiva on 12/10/2025.
// Copyright (c) 2025 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK
import MapboxMaps

/**
 * Function returns AccuTerra Mapbox style URL constructed from Info.plist configuration
 */
func getAccuTerraStyleURL() -> URL {
    guard let ACCUTERRA_MAP_STYLE_URL = Bundle(for: AppDelegate.self).infoDictionary?["ACCUTERRA_MAP_STYLE_URL"] as? String, ACCUTERRA_MAP_STYLE_URL.count > 0 else {
        fatalError("ACCUTERRA_MAP_STYLE_URL is missing or not configured in Info.plist")
    }
    guard let ACCUTERRA_MAP_API_KEY = Bundle(for: AppDelegate.self).infoDictionary?["ACCUTERRA_MAP_API_KEY"] as? String, ACCUTERRA_MAP_API_KEY.count > 0 else {
        fatalError("ACCUTERRA_MAP_API_KEY is missing or not configured in Info.plist")
    }
    return URL(string: "\(ACCUTERRA_MAP_STYLE_URL)?key=\(ACCUTERRA_MAP_API_KEY)")!
}
