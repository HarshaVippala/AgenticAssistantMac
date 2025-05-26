//
//  AudioStreamer.swift
//  AgenticAssistantMac
//
//  Created by Harsha Vippala on 5/25/25.
//

import Foundation
import AVFoundation
import os // For logging

// Define a struct for the SESSION_START message payload
// This should align with what your backend expects.
struct SessionStartMessage: Codable {
    let type: String = "session_start" // Matches MessageType.SESSION_START
    let timestamp: TimeInterval = Date().timeIntervalSince1970 * 1000 // Milliseconds
    let sessionId: String
    let config: StreamConfig
}

struct StreamConfig: Codable {
    let metadata: AudioStreamMetadata
    // Add other config fields if your backend expects them (e.g., speechRecognition, processing)
}

struct AudioStreamMetadata: Codable {
    let format: String // e.g., "PCM"
    let sampleRate: Double
    let channels: Int
    let bitDepth: Int
}

@available(macOS 10.15, *)
class AudioStreamer: NSObject, ObservableObject {

    // MARK: - Properties
    
    // Audio Engine
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioFormat: AVAudioFormat?
    
    // WebSocket
    private var webSocketTask: URLSessionWebSocketTask?
    private let webSocketURL = URL(string: "ws://localhost:8080/ws")!
    private var sessionId: String?

    // State
    @Published var isStreaming = false
    @Published var selectedDeviceName: String? // Store the name of the selected device for logging
    @Published var availableInputDevices: [AudioDeviceItem] = []

    // Logger
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.example.AgenticAssistantMac", category: "AudioStreamer")

    // Aggregate device name - REPLACE THIS WITH YOUR ACTUAL DEVICE NAME
    private let targetDeviceName = "MicPlusSystemAudio" // IMPORTANT: Update this

    // MARK: - Initialization
    override init() {
        super.init()
        setupAudioSession()
        enumerateInputDevices()
    }

    // MARK: - Public Methods

    func startStreaming() {
        guard !isStreaming else {
            logger.info("Streaming is already active.")
            return
        }

        logger.log("Attempting to start streaming...")
        
        // 1. Ensure an input device (preferably the target one) is identified.
        if self.selectedDeviceName == nil {
            selectTargetDevice()
        }
        
        if let selectedName = self.selectedDeviceName {
            logger.info("Selected audio device for monitoring: \(selectedName). Note: AVAudioEngine will use system default input.")
        } else {
            logger.warning("No specific audio device was pre-selected or matched target name. AVAudioEngine will use system default input.")
        }

        // 2. Setup and start audio engine
        setupAudioEngine() 
        
        guard let audioEngine = audioEngine, let inputNode = inputNode, let audioFormat = audioFormat else {
            logger.error("Audio engine or input node not initialized. Cannot start streaming.")
            return
        }

        do {
            // 3. Install tap for audio data with proper format conversion
            // Request Int16 format for the tap to match Deepgram's expectations
            let outputFormat = AVAudioFormat(commonFormat: .pcmFormatInt16,
                                           sampleRate: audioFormat.sampleRate,
                                           channels: 2, // Force stereo output
                                           interleaved: true)!
            
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: outputFormat) { [weak self] (buffer, when) in
                guard let self = self, self.isStreaming else { return }
                
                let audioData = self.convertPCMBufferToData(buffer: buffer)
                
                if !audioData.isEmpty {
                    self.sendAudioData(audioData)
                }
            }
            
            try audioEngine.start()
            logger.info("Audio engine started successfully (using system default input).")

            // 4. Connect WebSocket and send SESSION_START
            connectWebSocketAndStartSession(format: outputFormat)
            
            DispatchQueue.main.async {
                self.isStreaming = true
            }
            logger.info("Streaming started.")

        } catch {
            logger.error("Error starting audio engine: \(error.localizedDescription)")
            cleanupAudioEngine() 
        }
    }

    func stopStreaming() {
        guard isStreaming else {
            logger.info("Streaming is not active.")
            return
        }
        
        logger.log("Stopping streaming...")

        audioEngine?.stop()
        inputNode?.removeTap(onBus: 0)
        logger.info("Audio engine stopped and tap removed.")
        
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        logger.info("WebSocket connection closed.")
        
        DispatchQueue.main.async {
            self.isStreaming = false
        }
        sessionId = nil
        cleanupAudioEngine()
        logger.info("Streaming stopped.")
    }
    
    // MARK: - Audio Device Enumeration & Selection

    struct AudioDeviceItem: Identifiable, Hashable {
        let id: String // UID
        let name: String
    }

    private func setupAudioSession() {
        logger.debug("Audio session setup check (macOS specific handling).")
    }
    
    func enumerateInputDevices() {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.microphone, .external],
                                                                mediaType: .audio, position: .unspecified)
        let devices: [AudioDeviceItem] = discoverySession.devices.map { device in
            AudioDeviceItem(id: device.uniqueID, name: device.localizedName)
        }
        
        DispatchQueue.main.async {
            self.availableInputDevices = devices
        }
        logger.info("Available input devices: \(devices.map { $0.name }.joined(separator: ", "))")

        selectTargetDevice()
    }

    private func selectTargetDevice() {
        // Print all device names with quotes for debugging
        for dev in self.availableInputDevices {
            logger.info("Available device: '\(dev.name)'")
        }
        // Use trimmed, case-insensitive compare for robust matching
        if let device = self.availableInputDevices.first(where: {
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines).caseInsensitiveCompare(self.targetDeviceName) == .orderedSame
        }) {
            DispatchQueue.main.async {
                self.selectedDeviceName = device.name
            }
            self.logger.info("Target aggregate device '\(self.targetDeviceName)' found in available devices: \(device.name). Ensure it's set as system default for capture.")
        } else {
            self.logger.warning("Target aggregate device named '\(self.targetDeviceName)' not found among available devices. Please check the name. Streaming will use system default input.")
            if let firstDevice = self.availableInputDevices.first {
                 self.logger.warning("First available device is: \(firstDevice.name). Ensure system default is correctly set.")
                 DispatchQueue.main.async {
                    self.selectedDeviceName = firstDevice.name
                 }
            } else {
                self.logger.error("No input devices found at all.")
            }
        }
    }

    // MARK: - AVAudioEngine Setup & Handling

    private func setupAudioEngine() {
        cleanupAudioEngine() 

        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else {
            logger.error("Failed to create AVAudioEngine instance.")
            return
        }
        
        inputNode = audioEngine.inputNode
        guard let inputNode = inputNode else {
            logger.error("AVAudioEngine input node is nil.")
            self.audioEngine = nil
            return
        }
        
        logger.info("AVAudioEngine will use the system's default audio input device.")
        logger.info("Please ensure your aggregate device '\(self.targetDeviceName)' is set as the system default input for it to be used.")

        let nativeInputFormat = inputNode.outputFormat(forBus: 0)
        self.audioFormat = nativeInputFormat

        // Log details of the native format
        logger.info("System default input node's native format: \(nativeInputFormat.description)")
        logger.info("Native format details - SampleRate: \(nativeInputFormat.sampleRate), Channels: \(nativeInputFormat.channelCount), Interleaved: \(nativeInputFormat.isInterleaved), CommonFormat: \(nativeInputFormat.commonFormat.rawValue)")

        audioEngine.prepare()
    }
    
    private func convertPCMBufferToData(buffer: AVAudioPCMBuffer) -> Data {
        let format = buffer.format
        
        // Since we're requesting int16 format in the tap, this should always be true
        if format.commonFormat == .pcmFormatInt16 {
            guard let channelData = buffer.int16ChannelData else {
                logger.error("Failed to get int16ChannelData from buffer.")
                return Data()
            }
            
            let channelCount = Int(format.channelCount)
            let frameLength = Int(buffer.frameLength)
            let dataSize = frameLength * channelCount * MemoryLayout<Int16>.size
            var audioData = Data(capacity: dataSize)

            // Always create interleaved data for streaming
            for frame in 0..<frameLength {
                for channel in 0..<channelCount {
                    let sample = channelData[channel][frame]
                    // Little-endian encoding as required by Deepgram
                    audioData.append(UInt8(sample & 0xFF))
                    audioData.append(UInt8((sample >> 8) & 0xFF))
                }
            }
            
            return audioData
        } else {
            logger.error("Unexpected audio format in buffer: \(format.commonFormat.rawValue)")
            return Data()
        }
    }

    private func cleanupAudioEngine() {
        audioEngine?.stop()
        audioEngine = nil
        inputNode = nil
        audioFormat = nil
    }

    // MARK: - WebSocket Communication

    private func connectWebSocketAndStartSession(format: AVAudioFormat) {
        guard webSocketTask == nil else {
            logger.info("WebSocket task already exists or connection attempt in progress.")
            return
        }
        
        let urlSession = URLSession(configuration: .default, delegate: self, delegateQueue: OperationQueue())
        webSocketTask = urlSession.webSocketTask(with: self.webSocketURL)
        
        self.sessionId = UUID().uuidString 
        
        webSocketTask?.resume() 
        logger.info("WebSocket connection initiated to \(self.webSocketURL). Session ID: \(self.sessionId ?? "N/A")")
        
        receiveWebSocketMessages()
    }

    private func sendSessionStartMessage(payload: SessionStartMessage) {
        guard let webSocketTask = webSocketTask, webSocketTask.state == .running else {
            logger.error("WebSocket not connected or task is nil. Cannot send SESSION_START.")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(payload)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                logger.info("Sending SESSION_START: \(jsonString)")
                webSocketTask.send(.string(jsonString)) { [weak self] error in
                    if let error = error {
                        self?.logger.error("Error sending SESSION_START message: \(error.localizedDescription)")
                    } else {
                        self?.logger.info("SESSION_START message sent successfully.")
                    }
                }
            }
        } catch {
            logger.error("Failed to encode SESSION_START message: \(error.localizedDescription)")
        }
    }
    
    private func sendAudioData(_ data: Data) {
        guard let webSocketTask = webSocketTask, webSocketTask.state == .running, isStreaming else {
            return
        }
        
        webSocketTask.send(.data(data)) { [weak self] error in
            if let error = error {
                self?.logger.error("Error sending audio data: \(error.localizedDescription)")
            }
        }
    }

    private func receiveWebSocketMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                self.logger.error("WebSocket receive error: \(error.localizedDescription)")
                if self.isStreaming { 
                    DispatchQueue.main.async { self.stopStreaming() }
                }
            case .success(let message):
                switch message {
                case .string(let text):
                    self.logger.info("WebSocket received string: \(text)")
                case .data(let data):
                    self.logger.info("WebSocket received data: \(data.count) bytes")
                @unknown default:
                    self.logger.warning("WebSocket received unknown message type.")
                }
                if self.webSocketTask?.state == .running {
                    self.receiveWebSocketMessages()
                }
            }
        }
    }
    
    deinit {
        logger.info("AudioStreamer deinitialized.")
        stopStreaming() 
    }
}

// MARK: - URLSessionWebSocketDelegate
@available(macOS 10.15, *)
extension AudioStreamer: URLSessionWebSocketDelegate {
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        logger.info("WebSocket connection opened successfully.")
        
        guard let audioFormat = self.audioFormat, let sessionId = self.sessionId else {
            logger.error("Cannot send SESSION_START: audio format or session ID not available at didOpen.")
            return
        }

        // Always send 16-bit depth since we're converting to int16
        let metadata = AudioStreamMetadata(
            format: "pcm", // lowercase to match Deepgram expectations
            sampleRate: audioFormat.sampleRate,
            channels: 2, // We're always sending stereo
            bitDepth: 16 // Always 16-bit for Deepgram
        )
        let config = StreamConfig(metadata: metadata)
        let sessionStartPayload = SessionStartMessage(sessionId: sessionId, config: config)
        
        sendSessionStartMessage(payload: sessionStartPayload)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "No reason"
        logger.info("WebSocket connection closed: code \(closeCode.rawValue), reason: \(reasonString)")
        
        if isStreaming { 
            DispatchQueue.main.async {
                self.isStreaming = false
            }
        }
    }
}
