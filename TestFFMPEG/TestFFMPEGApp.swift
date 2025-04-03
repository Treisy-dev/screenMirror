//
//  TestFFMPEGApp.swift
//  TestFFMPEG
//
//  Created by Кирилл Щёлоков on 12.03.2025.
//

import SwiftUI
import GoogleCast

@main
struct TestFFMPEGApp: App {

    init() {
        let discoveryCriteria = GCKDiscoveryCriteria(applicationID: "C621D9F8") // Custom app
//        let discoveryCriteria = GCKDiscoveryCriteria(applicationID: "CC1AD845")
        let options = GCKCastOptions(discoveryCriteria: discoveryCriteria)
        GCKCastContext.setSharedInstanceWith(options)
    }

    var body: some Scene {
        WindowGroup {
            StreamView()
        }
    }
}
