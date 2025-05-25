//
//  ContentView.swift
//  AgenticAssistantMac
//
//  Created by Harsha Vippala on 5/25/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var audioStreamer = AudioStreamer()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Agentic Assistant Audio Streamer")
                .font(.headline)
            Text(audioStreamer.isStreaming ? "Streaming: ON" : "Streaming: OFF")
                .foregroundColor(audioStreamer.isStreaming ? .green : .red)
            
            HStack {
                Button("Start") {
                    audioStreamer.startStreaming()
                }
                .disabled(audioStreamer.isStreaming)
                .padding()
                
                Button("Stop") {
                    audioStreamer.stopStreaming()
                }
                .disabled(!audioStreamer.isStreaming)
                .padding()
            }
        }
        .frame(minWidth: 400, minHeight: 200)
        .padding()
    }
}
