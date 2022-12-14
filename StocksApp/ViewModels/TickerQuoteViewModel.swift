//
//  TickerQuoteViewModel.swift
//  StocksApp
//
//  Created by mufkhalif on 12/12/22.
//

import Foundation
import StocksApi

class TickerQuoteViewModel: ObservableObject {
    @Published var phase = FetchPhase<Quote>.initial
    var quote: Quote? { phase.value }
    var error: Error? { phase.error }
    
    let ticker: Ticker
    let stocksApi: StocksAPI
    
    init(ticker: Ticker, stocksApi: StocksAPI = StocksApi()) {
        self.ticker = ticker
        self.stocksApi = stocksApi
    }
    
    func fetchQuote() async {
        phase = .fetching
        
        do {
            let response = try await stocksApi.fetchQuotes(symbols: ticker.symbol)
            if let quote = response.first {
                phase = .success(quote)
            } else {
                phase = .empty
            }
        } catch {
            print(error.localizedDescription)
            phase = .failure(error)
        }
    }
}
