//
//  ErrorStateView.swift
//  StocksApp
//
//  Created by mufkhalif on 06/12/22.
//

import SwiftUI

struct ErrorStateView: View {
    
    let error: String
    var retryCallback: (() -> ())? = nil
    
    var body: some View {
        HStack{
            Spacer()
            VStack {
                Text(error)
                if let retryCallback {
                    Button("Retry", action: retryCallback)
                        .buttonStyle(.borderedProminent)
                }
            }
            Spacer()
        }
    }
}

struct ErrorStateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ErrorStateView(error: "An Error Ocurred") {}
                .previewDisplayName("With Retry Button")
            
            ErrorStateView(error: "An Error Ocurred")
                .previewDisplayName("Without Retry Button")
        }
    }
}
