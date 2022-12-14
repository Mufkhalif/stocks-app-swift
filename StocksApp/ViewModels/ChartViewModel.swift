//
//  ChartViewModel.swift
//  StocksApp
//
//  Created by mufkhalif on 12/12/22.
//

import Foundation
import StocksApi
import SwiftUI
import Charts

@MainActor
class ChartViewModel: ObservableObject {
    @Published var fetchPhase = FetchPhase<ChartViewData>.initial
    var chart: ChartViewData? { fetchPhase.value }
    
    let ticker: Ticker
    let stocksApi: StocksAPI
    
    @AppStorage("selectedRange") private var _range = ChartRange.oneDay.rawValue
    
    @Published var selectedRange = ChartRange.oneDay {
        didSet { _range = selectedRange.rawValue }
    }
    
    @Published var selectedX: (any Plottable)?
    
    var foregroundMarkColor: Color {
        (selectedX != nil) ? .cyan : (chart?.lineColor ?? .cyan)
    }
    
    private let dateFormatter = DateFormatter()
    
    private let selectedValueDateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
    
    var selectedXRuleMark: (value: Int, text: String)? {
        guard let selectedX = selectedX as? Int,
              let chart
        else { return nil }
        return (selectedX, chart.items[selectedX].value.roundedString)
    }
    
    init(ticker: Ticker, stocksApi: StocksAPI = StocksApi()) {
        self.ticker = ticker
        self.stocksApi = stocksApi
        self.selectedRange = ChartRange(rawValue: _range) ?? .oneDay
    }
    
    func fetchData() async {
        do {
            fetchPhase = .fetching
            let rangeType = self.selectedRange
            let chartData = try await stocksApi.fetchChartData(tickerSymbol: ticker.symbol, range: rangeType)
            
            guard rangeType == self.selectedRange else { return }
            if let chartData {
                fetchPhase = .success(transformChartViewData(chartData))
            } else {
                fetchPhase = .empty
            }
        } catch {
            fetchPhase = .failure(error)
        }
    }
    
    func transformChartViewData(_ data: ChartData) -> ChartViewData {
        let (xAxisChartData, items) = xAxisChartDataAndItems(data)
        let yAxisChartData = yAxisChartData(data)
        return ChartViewData(
            xAxisData: xAxisChartData,
            yAxisData: yAxisChartData,
            items: items,
            lineColor: getLineColor(data: data),
            previousCloseRuleMarkValue: previousCloseRuleMarkValue(data: data, yAxisData: yAxisChartData)
        )
    }
    
    func xAxisChartDataAndItems(_ data: ChartData) -> (ChartAxisData, [ChartViewItem]) {
        let timezone = TimeZone(secondsFromGMT: data.meta.gmtOffset) ?? .gmt
        dateFormatter.timeZone = timezone
        selectedValueDateFormatter.timeZone = timezone
        dateFormatter.dateFormat = selectedRange.dateFormat
        
        var xAxisDataComponents = Set<DateComponents>()
        if let startTimestamp = data.indicators.first?.timestamp {
            if selectedRange == .oneDay {
                xAxisDataComponents = selectedRange.getDateComponents(startDate: startTimestamp, endDate: data.meta.regularTradingPeriodEndDate, timezone: timezone)
            } else if let endTimeStamp = data.indicators.last?.timestamp {
                xAxisDataComponents = selectedRange.getDateComponents(startDate: startTimestamp, endDate: endTimeStamp, timezone: timezone)
            }
        }
        
        var map = [String: String]()
        var axisEnd: Int
        
        var items = [ChartViewItem]()
        
        for(index, value) in data.indicators.enumerated() {
            let dc = value.timestamp.dateComponents(timeZone: timezone, rangeType: selectedRange)
            if xAxisDataComponents.contains(dc) {
                map[String(index)] = dateFormatter.string(from: value.timestamp)
                xAxisDataComponents.remove(dc)
            }
            
            items.append(ChartViewItem(timestamp: value.timestamp, value: value.close))
        }
        
        axisEnd = items.count - 1
        
        if selectedRange == .oneDay,
           var date = items.last?.timestamp,
           date >= data.meta.regularTradingPeriodStartDate && date < data.meta.regularTradingPeriodEndDate {
            while date < data.meta.regularTradingPeriodEndDate {
                axisEnd += 1
                date = Calendar.current.date(byAdding: .minute,value: 2, to: date)!
                let dc = date.dateComponents(timeZone: timezone, rangeType: selectedRange)
                if xAxisDataComponents.contains(dc) {
                    map[String(axisEnd)] = dateFormatter.string(from: date)
                    xAxisDataComponents.remove(dc)
                }
            }
        }
        
        let xAxisData = ChartAxisData(axisStart: 0, axisEnd: Double(max(0, axisEnd)), strideBy: 1, map: map)
        return (xAxisData, items)
    }
    
    func yAxisChartData(_ data: ChartData) ->  ChartAxisData {
        let closes = data.indicators.map { $0.close }
        var lowest  = closes.min() ?? 0
        var highest = closes.max() ?? 0
        
        if let prevClose = data.meta.previousClose, selectedRange == .oneDay {
            if prevClose < lowest {
                lowest = prevClose
            } else if prevClose > highest {
                highest = prevClose
            }
        }
        
        // 2
        let diff = highest - lowest
        
        //3
        let numberOfLines: Double = 4
        let shouldCeilIncrement: Bool
        let strideBy: Double
        
        if diff < (numberOfLines * 2) {
            // 4A
            shouldCeilIncrement = false
            strideBy = 0.01
        } else {
            // 4B
            shouldCeilIncrement = true
            lowest = floor(lowest)
            highest = ceil(highest)
            strideBy = 1.0
        }
        
        //5
        let increment = ((highest - lowest) / (numberOfLines) )
        var map = [String: String]()
        map[highest.roundedString] = formatYAxisValueLabel(value: highest, shouldCeilIncrement: shouldCeilIncrement)
        
        var current = lowest
        (0..<Int(numberOfLines) - 1).forEach { i in
            current += increment
            map[(shouldCeilIncrement ? ceil(current) : current).roundedString] = formatYAxisValueLabel(value: current, shouldCeilIncrement: shouldCeilIncrement)
        }
        
        return ChartAxisData(
            axisStart: lowest - 0.01,
            axisEnd: highest + 0.01,
            strideBy: strideBy,
            map: map)
    }
    
    private func formatYAxisValueLabel(value: Double, shouldCeilIncrement: Bool) -> String {
        if shouldCeilIncrement {
            return String(Int(ceil(value)))
        } else {
            return Utils.numberFormater.string(from: NSNumber(value: value)) ?? value.roundedString
        }
    }
    
    func previousCloseRuleMarkValue(data: ChartData, yAxisData: ChartAxisData) -> Double? {
        guard let previousClose = data.meta.previousClose, selectedRange == .oneDay else {
            return nil
        }
        return (yAxisData.axisStart <= previousClose && previousClose <= yAxisData.axisEnd) ? previousClose : nil
    }
    
    func getLineColor(data: ChartData) -> Color {
        if let last = data.indicators.last?.close {
            if selectedRange == .oneDay, let prevClose = data.meta.previousClose {
                return last >= prevClose ? .green : .red
            } else if let first = data.indicators.first?.close {
                return last >= first ? .green : .red
            }
        }
        return .blue
    }
    
}
