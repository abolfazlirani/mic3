
import Foundation

public final class MicrophonePitchDetector {
    private let engine = AudioEngine()
    private var tracker: PitchTap!

    public var didReceiveAudio = false
    private let didReceivedPitch: (Double) -> Void
    private let didReceiveAudioCallback: () -> Void

    public init(
        didReceivedPitch: @escaping (Double) -> Void,
        didReceiveAudioCallback: @escaping () -> Void
    ) {
        self.didReceivedPitch = didReceivedPitch
        self.didReceiveAudioCallback = didReceiveAudioCallback
    }

    @MainActor
    public func activate(debug: Bool = false) async {
        let startDate = Date()
        var intervalMS: UInt64 = 30

        while !didReceiveAudio {
            if debug {
                print("Waiting \(intervalMS * 2)ms")
            }
            try? await Task.sleep(nanoseconds: intervalMS * NSEC_PER_MSEC)
            self.setUpPitchTracking()
            try? await Task.sleep(nanoseconds: intervalMS * NSEC_PER_MSEC)
            start()
            intervalMS = min(intervalMS * 2, 180)
        }

        if debug {
            let duration = String(format: "%.2fs", -startDate.timeIntervalSinceNow)
            print("Took \(duration) to start")
        }
    }

    // MARK: - Private
    public func stop() throws{
           try engine.stop();
        }
    private func setUpPitchTracking() {
        tracker = PitchTap(engine.input, handler: { [weak self] pitch in
            guard let self else { return }
            self.didReceivedPitch(pitch)
        }, didReceiveAudio: { [weak self] in
            guard let self else { return }
            self.didReceiveAudioCallback()
        })
        start()
    }

    private func start() {
        do {
            try engine.start()
            tracker.start()
        } catch {
            // TODO: Handle error
        }
    }
}
