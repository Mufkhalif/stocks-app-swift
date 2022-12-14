//
//  EmptyStateView.swift
//  StocksApp
//
//  Created by mufkhalif on 06/12/22.
//

import SwiftUI

struct EmptyStateView: View {
    let text: String
    
    var body: some View {
        HStack{
            Spacer()
            Text(text)
                .font(.headline)
                .foregroundColor(Color(uiColor: .secondaryLabel))
            Spacer()
        }
        .padding(64)
        .lineLimit(3)
        .multilineTextAlignment(.center)
    }
}

struct EmptyStateView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyStateView(text: "No data available")
    }
}
