//
//  StocksAppApp.swift
//  StocksApp
//
//  Created by mufkhalif on 05/12/22.
//

import SwiftUI
import StocksApi

@main
struct StocksAppApp: App {
    
     @StateObject var appVM = AppViewModel()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                MainListView()
            }
            .environmentObject(appVM)
        }
    }
}
