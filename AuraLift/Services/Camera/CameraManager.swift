import Foundation
import AVFoundation
import Combine

// MARK: - CameraError

enum CameraError: Error, LocalizedError {
    case permissionDenied
    case deviceNotFound
    case configurationFailed

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Camera access was denied. Please enable it in Settings."
        case .deviceNotFound:
            return "No compatible camera device found."
        case .configurationFailed:
            return "Failed to configure the camera session."
        }
    }
}

// MARK: - CameraManager

/// Manages AVCaptureSession for real-time camera input with pose detection.
final class CameraManager: NSObject, ObservableObject, ServiceProtocol {

    // MARK: - Published State

    @Published var isRunning = false
    @Published var permissionGranted = false
    @Published var permissionDenied = false
    @Published var currentCameraPosition: AVCaptureDevice.Position = .back

    // MARK: - ServiceProtocol

    var isAvailable: Bool { permissionGranted }

    // MARK: - Internal

    let captureSession = AVCaptureSession()
    private var videoDeviceInput: AVCaptureDeviceInput?
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.aurea.camera.session")
    private let dataOutputQueue = DispatchQueue(label: "com.aurea.camera.dataOutput")

    // MARK: - Frame Callback

    var onFrameCaptured: ((CMSampleBuffer) -> Void)?

    // MARK: - Cleanup

    deinit {
        onFrameCaptured = nil
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }

    // MARK: - Initialize

    func initialize() async throws {
        let granted = await checkPermission()
        await MainActor.run {
            self.permissionGranted = granted
            self.permissionDenied = !granted
        }

        guard granted else { throw CameraError.permissionDenied }

        try configureSession()
    }

    // MARK: - Permission

    private func checkPermission() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            return true
        case .notDetermined:
            return await AVCaptureDevice.requestAccess(for: .video)
        default:
            return false
        }
    }

    // MARK: - Session Configuration

    private func configureSession() throws {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }

        captureSession.sessionPreset = .hd1280x720

        // Add camera input
        guard let device = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: .video,
            position: currentCameraPosition
        ) else {
            throw CameraError.deviceNotFound
        }

        let input = try AVCaptureDeviceInput(device: device)
        guard captureSession.canAddInput(input) else {
            throw CameraError.configurationFailed
        }
        captureSession.addInput(input)
        videoDeviceInput = input

        // Add video data output
        videoDataOutput.alwaysDiscardsLateVideoFrames = true
        videoDataOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
        ]
        videoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)

        guard captureSession.canAddOutput(videoDataOutput) else {
            throw CameraError.configurationFailed
        }
        captureSession.addOutput(videoDataOutput)

        // Set portrait orientation
        if let connection = videoDataOutput.connection(with: .video) {
            if connection.isVideoRotationAngleSupported(90) {
                connection.videoRotationAngle = 90
            }
        }
    }

    // MARK: - Session Control

    func startSession() {
        sessionQueue.async { [weak self] in
            guard let self, !self.captureSession.isRunning else { return }
            self.captureSession.startRunning()
            DispatchQueue.main.async { [weak self] in
                self?.isRunning = true
            }
        }
    }

    func stopSession() {
        sessionQueue.async { [weak self] in
            guard let self, self.captureSession.isRunning else { return }
            self.captureSession.stopRunning()
            DispatchQueue.main.async { [weak self] in
                self?.isRunning = false
            }
        }
    }

    // MARK: - Camera Toggle

    func toggleCamera() {
        sessionQueue.async { [weak self] in
            guard let self else { return }

            let newPosition: AVCaptureDevice.Position =
                (self.currentCameraPosition == .back) ? .front : .back

            guard let newDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: .video,
                position: newPosition
            ) else { return }

            self.captureSession.beginConfiguration()
            defer { self.captureSession.commitConfiguration() }

            // Remove existing input
            if let currentInput = self.videoDeviceInput {
                self.captureSession.removeInput(currentInput)
            }

            // Add new input
            do {
                let newInput = try AVCaptureDeviceInput(device: newDevice)
                if self.captureSession.canAddInput(newInput) {
                    self.captureSession.addInput(newInput)
                    self.videoDeviceInput = newInput

                    // Re-apply orientation
                    if let connection = self.videoDataOutput.connection(with: .video) {
                        if connection.isVideoRotationAngleSupported(90) {
                            connection.videoRotationAngle = 90
                        }
                    }

                    DispatchQueue.main.async { [weak self] in
                        self?.currentCameraPosition = newPosition
                    }
                }
            } catch {
                // Re-add old input if swap fails
                if let oldInput = self.videoDeviceInput,
                   self.captureSession.canAddInput(oldInput) {
                    self.captureSession.addInput(oldInput)
                }
            }
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        onFrameCaptured?(sampleBuffer)
    }
}
