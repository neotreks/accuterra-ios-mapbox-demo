//
//  ViewController.swift
//  AccuTerraMapBoxDemo
//
// Created by Rudolf Kopřiva on 12/10/2025.
// Copyright (c) 2025 NeoTreks. All rights reserved.
//

import UIKit
import MapboxMaps
import AccuTerraSDK

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MapView!
    @IBOutlet weak var initializeSDKButton: UIButton!
    @IBOutlet weak var addTrailsButton: UIButton!
    @IBOutlet weak var removeTrailsButton: UIButton!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    private var trailPathsManager: TrailPathsManager?
    private let denver = CLLocationCoordinate2D(latitude: 39.7392, longitude: -104.9903)

    override func viewDidLoad() {
        super.viewDidLoad()

        let cameraOptions = CameraOptions(center:
                                            denver,
                                          zoom: 7, bearing: 0, pitch: 0)
        mapView.mapboxMap.setCamera(to: cameraOptions)

        // Add AccuTerra Map Style
        mapView.mapboxMap.styleURI = StyleURI(url: getAccuTerraStyleURL())
    }

    @IBAction func initializeAccuTerraSDK() {
        if !FileManager.default.fileExists(atPath: AccuTerraFiles.AccuTerraLibraryDirectory.path()) {
            showMessage(title: "First SDK Initialization", message: "First SDK initialization can take a while. Check log for progress.")
        }
        self.initializeSDKButton.isEnabled = false
        self.loadingIndicator.startAnimating()
        SdkManager.shared.initSdkAsync(config: demoAppSdkConfig, accessProvider: DemoCredentialsAccessManager.shared, identityProvider: DemoIdentityManager.shared, delegate: self, dbEncryptConfigProvider: nil)
    }

    @IBAction func addTrailsLayer() {
        self.addTrailsButton.isEnabled = false

        self.trailPathsManager = TrailPathsManager(mapView: self.mapView)

        Task {
            let trailService = ServiceFactory.getTrailService()
            // As example we create filter for trails within 100 km of Denver
            let filter = TrailMapSearchCriteria(
                mapCenter: MapLocation(latitude: denver.latitude, longitude: denver.longitude),
                distanceRadius: try DistanceSearchCriteriaBuilder.build(distance: 100000), // 100 km
                nameSearchCriteria: nil,
                techRating: nil,
                userRating: nil,
                tags: nil,
                groups: nil,
                length: nil,
                driveTime: nil,
                favorite: nil,
                hasWaypointPhotos: nil,
                hasMapCache: nil,
                orderBy: OrderByBuilder.build(),
                limit: try QueryLimitBuilder.build(limit: 1000)
            )
            let trails = try trailService.findTrails(byMapCriteria: filter)
            // The array contains only basic trail info. To get full info call `trailService.getTrailById`

            try await self.trailPathsManager?.addToMap()
            try await self.trailPathsManager?.showTrailsFromFeatures(trails: trails)
            await MainActor.run {
                self.loadingIndicator.stopAnimating()
                self.removeTrailsButton.isEnabled = true
            }
        }
    }

    @IBAction func removeTrailsLayer() {
        try? self.trailPathsManager?.removeFromMap()
        self.trailPathsManager = nil
        self.addTrailsButton.isEnabled = true
        self.removeTrailsButton.isEnabled = false
    }

    private func showMessage(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension ViewController: SdkInitDelegate {
    func onStateChanged(state: AccuTerraSDK.SdkInitState, detail: AccuTerraSDK.SdkInitStateDetail?) {
        print("SDK Init State changed to: \(state), detail: \(String(describing: detail))")
        switch state {
        case .FAILED(error: let error):
            let errorMessage = error?.localizedDescription ?? "unknown error"
            print("SDK Init Failed with error: \(errorMessage)")
            Task { @MainActor in
                self.initializeSDKButton.isEnabled = true
                self.loadingIndicator.stopAnimating()
                self.showMessage(title: "Error", message: "SDK Failed to initialize, check log.")
            }
        case .COMPLETED:
            Task { @MainActor in
                self.loadingIndicator.stopAnimating()
                self.addTrailsButton.isEnabled = true
            }
        default:
            print("SDK Init State: \(state)")
        }
    }

    func onProgressChanged(progress: Int) {
        print("SDK Init Progress: \(progress)%")
    }
}
