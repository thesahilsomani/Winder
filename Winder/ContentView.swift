//
//  ContentView.swift
//  Winder
//
//  Created by Sahil Somani on 1/27/23.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            Color.blue
                .ignoresSafeArea()
            
            VStack {
                Text("Winder")
                    .padding(.bottom, 30)
                Image(systemName: "figure.walk")
                        .foregroundColor(.white)
            }
            .bold()
            .font(.system(size: 50))
            .foregroundColor(.white)
            .padding(.bottom, 300)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
