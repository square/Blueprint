//
//  ContentView.swift
//  SwiftUITest
//
//  Created by Kyle Van Essen on 6/27/20.
//  Copyright © 2020 Kyle Van Essen. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var isOn : Bool = true
    
    init(isOn : Bool) { // passing true
        self.isOn = isOn
        print(self.isOn) // prints true
        
        self.isOn = !isOn
        print(self.isOn) // also prints true
    }
    
    var body: some View {
        Toggle(isOn: $isOn) { Text("A String!") }
    }
}

struct PlayButton: View {
    @Binding var isPlaying: Bool
    
    var body: some View {
        Button(action: {
            self.isPlaying.toggle()
        }) {
            Image(systemName: isPlaying ? "pause.circle" : "play.circle")
        }
    }
}

