//
//  DemoIdentityManager.swift
//  AccuTerraMapBoxDemo
//
// Created by Rudolf Kopřiva on 12/10/2025.
// Copyright (c) 2025 NeoTreks. All rights reserved.
//

import Foundation
import AccuTerraSDK

/**
 * DemoIdentityManager is a singleton class that conforms to the IIdentityProvider protocol
 * Use it to manage user identity in the demo application
 * Identity is used to store user-specific data on the AccuTerra server. For example trail likes or trip recordings.
 */
  class DemoIdentityManager : IIdentityProvider {

    private var currentUserId = "test driver uuid"

    public static var shared: DemoIdentityManager = {
        DemoIdentityManager()
    }()

    private init() {
    }

    func getUserId() -> String {
        return self.currentUserId
    }

    func setUserId(userId: String?) {
        self.currentUserId = userId ?? "test driver uuid"
    }
}
