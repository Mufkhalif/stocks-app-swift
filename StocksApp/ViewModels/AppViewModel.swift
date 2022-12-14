//
//  AppViewmODEL.swift
//  StocksApp
//
//  Created by mufkhalif on 07/12/22.
//

import Foundation
import StocksApi
import SwiftUI

@MainActor
class AppViewModel: ObservableObject {
    @Published var tickers: [Ticker] = [] {
        didSet { saveTickers() }
    }
    @Published var selectedTicker: Ticker?

    var titleText = "XCA Stocks"
    @Published var subtitleText: String
    var emptyTickersText = "Search & add symbol to see stock quotes"
    var attributionText = "Powered by Yahoo! finance API"

    private let subtitleDateFormat: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "d MM"
        return df
    }()

    let tickerRepository: TickerListRepository
    
    init(repository: TickerListRepository = TickerPlistRepository()) {
        self.tickerRepository = repository
        self.subtitleText = subtitleDateFormat.string(from: Date())
        
        loadTickers()
    }
    
    private func loadTickers() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                self.tickers = try await tickerRepository.load()
            } catch {
                print(error.localizedDescription)
                self.tickers = []
            }
        }
    }
    
    private func saveTickers() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await self.tickerRepository.save(self.tickers)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    func openYahooFinance() {
        let url = URL(string: "https://finance.yahoo.com")!
        guard UIApplication.shared.canOpenURL(url) else { return }
        UIApplication.shared.open(url)
    }
    
    func isAddedToMyTickers(ticker: Ticker) -> Bool {
        tickers.first { $0.symbol == ticker.symbol } != nil
    }
    
    func toggleTicker(_ ticker: Ticker) {
        isAddedToMyTickers(ticker: ticker)  ? removFromMyTickers(ticker: ticker) : addToMyTickers(ticker: ticker)
    }
    
    private func addToMyTickers(ticker: Ticker) {
        tickers.append(ticker)
    }
    
    func removFromMyTickers(ticker: Ticker) {
        guard let index = tickers.firstIndex(where: { $0.symbol == ticker.symbol}) else { return }
        tickers.remove(at: index)
    }
    
    func removeTickers(attOffset offsets: IndexSet) {
        tickers.remove(atOffsets: offsets)
    }
}
