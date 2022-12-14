//
//  QoutesViewModel.swift
//  StocksApp
//
//  Created by mufkhalif on 07/12/22.
//

import Foundation
import StocksApi


@MainActor
class QuotesViewModel: ObservableObject {
    @Published var quotesDict: [String: Quote] = [:]
    let stocksAPI: StocksAPI
    
    init(stocksAPI: StocksAPI = StocksApi()) {
        self.stocksAPI = stocksAPI
    }

    func fetchQuotes(tickers: [Ticker]) async {
        guard !tickers.isEmpty else { return }
        do {
            let symbols = tickers.map{ $0.symbol }.joined(separator: ",")
            let quotes = try await stocksAPI.fetchQuotes(symbols: symbols)
            var dict = [String: Quote]()
            quotes.forEach { dict[$0.symbol] = $0 }
            self.quotesDict = dict
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func priceForTicker(_ ticker: Ticker) -> PriceChange? {
        guard let quote = quotesDict[ticker.symbol],
              let price = quote.regularPriceText,
              let change = quote.regularDiffText
        else { return nil }
        return (price, change)
    }
    
}
