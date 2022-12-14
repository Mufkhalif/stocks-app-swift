//
//  MainListView.swift
//  StocksApp
//
//  Created by mufkhalif on 07/12/22.
//

import SwiftUI
import StocksApi

struct MainListView: View {
    
    @EnvironmentObject var appVm: AppViewModel
    @StateObject var quotesVM = QuotesViewModel()
    @StateObject var searchVM = SearchViewModel()
    
    var body: some View {
        tickerListView
            .listStyle(.plain)
            .overlay { overlayView }
            .toolbar {
                titleToolbar
                attributionToolbar
            }
            .searchable(text: $searchVM.query)
            .refreshable { await quotesVM.fetchQuotes(tickers: appVm.tickers) }
            .sheet(item: $appVm.selectedTicker) {
                StockTickerView(chartVM: ChartViewModel(ticker: $0, stocksApi: quotesVM.stocksAPI), quoteVM: .init(ticker: $0, stocksApi: quotesVM.stocksAPI))
                    .presentationDetents([.height(560)])
            }
            .task(id: appVm.tickers) { await quotesVM.fetchQuotes(tickers: appVm.tickers)}
            
    }
    
    private var tickerListView: some View {
        List {
            ForEach(appVm.tickers) { ticker in
                TicketListRowView(
                    data: .init(
                        symbol: ticker.symbol,
                        name: ticker.shortname,
                        price: quotesVM.priceForTicker(ticker),
                        type: .main
                    )
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    appVm.selectedTicker = ticker
                }
            }
            .onDelete { appVm.removeTickers(attOffset: $0) }
        }
        .opacity(searchVM.isSearching ? 0 : 1)
    }
    
    @ViewBuilder
    private var overlayView: some View {
        if appVm.tickers.isEmpty {
            EmptyStateView(text: appVm.emptyTickersText)
        }
        
        if searchVM.isSearching {
            SearchView(searchVM: searchVM)
        }
        
    }
    
    private var titleToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            VStack(alignment: .leading, spacing: -4) {
                Text(appVm.titleText)
                Text(appVm.subtitleText).foregroundColor(Color(uiColor: .secondaryLabel))
            }.font(.title2.weight(.heavy))
                .padding(.bottom)
        }
    }
    
    private var attributionToolbar: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            HStack {
                Button {
                    appVm.openYahooFinance()
                } label: {
                    Text(appVm.attributionText)
                        .font(.caption.weight(.heavy))
                        .foregroundColor(Color(uiColor: .secondaryLabel))
                }
                .buttonStyle(.plain)
                Spacer()
            }
        }
    }
    
    
}

struct MainListView_Previews: PreviewProvider {
    
    @StateObject static var appVm: AppViewModel = {
        let vm = AppViewModel()
        vm.tickers = Ticker.stubs
        return vm
    }()
    
    @StateObject static var emptyAppVm: AppViewModel = {
        let vm = AppViewModel()
        vm.tickers = []
        return vm
    }()
    
    static var quotesVm: QuotesViewModel = {
        var mock = MockStocksAPI()
        mock.stubbedFetchQuotesCallback = { Quote.stubs }
        return QuotesViewModel(stocksAPI: mock)
    }()
    
    @StateObject static var searchVm: SearchViewModel = {
        var mock = MockStocksAPI()
        mock.stubbedSearchTickersCallback = { Ticker.stubs }
        return SearchViewModel(query: "Apple", stocksApi: mock)
    }()
    
    
    static var previews: some View {
        Group {
            NavigationStack {
                MainListView(quotesVM: quotesVm, searchVM: searchVm)
            }
            .environmentObject(appVm)
            .previewDisplayName("With Tickers")
            .preferredColorScheme(.dark)
            
//            NavigationStack {
//                MainListView(quotesVM: quotesVm, searchVM: searchVM)
//            }
//            .environmentObject(emptyAppVm)
//            .previewDisplayName("With empty Tickers")
        }
    }
}
