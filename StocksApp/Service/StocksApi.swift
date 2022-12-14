//
//  StocksApi.swift
//  StocksApp
//
//  Created by mufkhalif on 09/12/22.
//

import Foundation
import StocksApi

protocol StocksAPI {
    func searchTickers(query: String, isEquityTypeOnly: Bool) async throws -> [Ticker]
    func fetchQuotes(symbols: String) async throws -> [Quote]
    func fetchChartData(tickerSymbol: String, range: ChartRange) async throws -> ChartData?
}

extension StocksApi: StocksAPI {}

