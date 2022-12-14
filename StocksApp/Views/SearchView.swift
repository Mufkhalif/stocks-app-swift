//
//  SearchView.swift
//  StocksApp
//
//  Created by mufkhalif on 11/12/22.
//

import SwiftUI
import StocksApi


@MainActor
struct SearchView: View {
    
    @EnvironmentObject var appVM: AppViewModel
    @StateObject var quotesVM = QuotesViewModel()
    @ObservedObject var searchVM: SearchViewModel

    var body: some View {
        List(searchVM.tickers) { ticker in
            TicketListRowView(
                data: .init(
                    symbol: ticker.symbol,
                    name: ticker.shortname,
                    price: quotesVM.priceForTicker(ticker),
                    type: .search(isSaved: appVM.isAddedToMyTickers(ticker: ticker), onButtonTapped: {
                        appVM.toggleTicker(ticker)
                    })
                )
            )
        }
        .listStyle(.plain)
        .refreshable { await quotesVM.fetchQuotes(tickers: searchVM.tickers) }
        .task(id: searchVM.tickers) { await quotesVM.fetchQuotes(tickers: searchVM.tickers) }
        .overlay { listSearchOverlay }
    }
    
    
    @ViewBuilder
    private var listSearchOverlay: some View {
        switch searchVM.phase {
        case .failure(let error):
            ErrorStateView(error: error.localizedDescription) {
                Task { await searchVM.searchTickers() }
            }
        case .empty:
            EmptyStateView(text: searchVM.emptyListText)
        case .fetching:
            LoadingStateView()
        default: EmptyView()
        }
    }
    
}

struct SearchView_Previews: PreviewProvider {
    @StateObject static var stubbedSearchVM: SearchViewModel = {
        var mock = MockStocksAPI()
        mock.stubbedSearchTickersCallback = { Ticker.stubs }
        return SearchViewModel(query: "Apple", stocksApi: mock)
    }()
    
    @StateObject static var emptySearchVm: SearchViewModel = {
        var mock = MockStocksAPI()
        mock.stubbedSearchTickersCallback = { [] }
        return SearchViewModel(query: "Surya", stocksApi: mock)
    }()
    
    @StateObject static var loadingSearchVm: SearchViewModel = {
        var mock = MockStocksAPI()
        mock.stubbedSearchTickersCallback = { await withCheckedContinuation { _ in } }
        return SearchViewModel(query: "Surya", stocksApi: mock)
    }()
    
    @StateObject static var errorSearchVm: SearchViewModel = {
        var mock = MockStocksAPI()
        mock.stubbedSearchTickersCallback = { throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "An error has been occured"]) }
        return SearchViewModel(query: "Surya", stocksApi: mock)
    }()
    
    @StateObject static var appVm: AppViewModel = {
        let vm = AppViewModel()
        vm.tickers = Ticker.stubs
        return vm
    }()

    static var quotesVm: QuotesViewModel = {
        var mock = MockStocksAPI()
        mock.stubbedFetchQuotesCallback = { Quote.stubs }
        return QuotesViewModel(stocksAPI: mock)
    }()
    
    static var previews: some View {
        Group {
            NavigationStack {
                SearchView(quotesVM: quotesVm, searchVM: stubbedSearchVM)
            }
            .searchable(text: $stubbedSearchVM.query)
            .previewDisplayName("Results")
            
            
            NavigationStack {
                SearchView(quotesVM: quotesVm, searchVM: emptySearchVm)
            }
            .searchable(text: $stubbedSearchVM.query)
            .previewDisplayName("Empty Results")
            
            NavigationStack {
                SearchView(quotesVM: quotesVm, searchVM: loadingSearchVm)
            }
            .searchable(text: $stubbedSearchVM.query)
            .previewDisplayName("Loading Results")
            
            NavigationStack {
                SearchView(quotesVM: quotesVm, searchVM: errorSearchVm)
            }
            .searchable(text: $stubbedSearchVM.query)
            .previewDisplayName("Error Results")

            
        }
        .environmentObject(appVm)
    }
}
