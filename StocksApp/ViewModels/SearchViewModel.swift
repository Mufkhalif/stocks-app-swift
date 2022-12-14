//
//  SearchViewModel.swift
//  StocksApp
//
//  Created by mufkhalif on 07/12/22.
//

import Foundation
import StocksApi
import Combine
import SwiftUI

@MainActor
class SearchViewModel: ObservableObject {
    @Published var query: String = ""
    @Published var phase: FetchPhase<[Ticker]> = .initial
    
    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var tickers: [Ticker] { phase.value ?? [] }
    var error: Error? { phase.error }
    var isSearching: Bool { !trimmedQuery.isEmpty }
    
    var emptyListText: String {
        "Symbols not found for\n\"\(query)\""
    }
    
    private var cancellables = Set<AnyCancellable>()
    private let stocksApi: StocksAPI
    
    init(query: String = "", stocksApi: StocksAPI = StocksApi()) {
        self.query = query
        self.stocksApi = stocksApi
        startObserving()
    }
    
    private func startObserving() {
        $query
            .debounce(for: 0.25, scheduler: DispatchQueue.main)
            .sink { _ in
                Task { [weak self] in await self?.searchTickers() }
            }
            .store(in: &cancellables)
        
        $query
            .filter { $0.isEmpty }
            .sink { [weak self] _ in self?.phase = .initial }
            .store(in: &cancellables)
    }
    
    func searchTickers() async {
        let searchQuery = trimmedQuery
        guard !searchQuery.isEmpty else  { return }
        phase = .fetching

        do {
            let tickers = try await stocksApi.searchTickers(query: searchQuery, isEquityTypeOnly: true)
            if searchQuery != trimmedQuery { return }
            if tickers.isEmpty {
                phase = .empty
            } else {
                phase = .success(tickers)
            }
        } catch {
            if searchQuery != trimmedQuery { return }
            print(error.localizedDescription)
            phase = .failure(error)
        }
    }
    
    
}
