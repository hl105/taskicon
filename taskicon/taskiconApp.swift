//
//  taskiconApp.swift
//  taskicon
//
//  Created by Hoonsun Lee on 5/31/25.
//

import SwiftUI

@main
struct taskiconApp: App {
    var body: some Scene {
        MenuBarExtra {
            ContentView()
        } label: {
            Image(systemName: "tortoise.fill")
        }
        .menuBarExtraStyle(.window)
    }
}
