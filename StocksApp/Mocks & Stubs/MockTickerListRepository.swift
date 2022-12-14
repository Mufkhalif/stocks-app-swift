//
//  MockTickerListRepository.swift
//  StocksApp
//
//  Created by mufkhalif on 07/12/22.
//

import Foundation
import StocksApi

#if DEBUG

struct MockTickerListRepository: TickerListRepository {
    
    var stubbedLoad: (() async throws -> [Ticker])!
    
    func save(_ current: [Ticker]) async throws {}
    
    func load() async throws -> [Ticker] { try await stubbedLoad() }
    
}

#endif
