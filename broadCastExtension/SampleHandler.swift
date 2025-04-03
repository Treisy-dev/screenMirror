import ReplayKit

class SampleHandler: RPBroadcastSampleHandler {

    private let screencaster = ScreenCaster()

    override func broadcastStarted(withSetupInfo setupInfo: [String: NSObject]?) {
        print("server started")
        screencaster.startServer()
    }

    override func broadcastPaused() {
        // User has requested to pause the broadcast. Samples will stop being delivered.
    }

    override func broadcastResumed() {
        // User has requested to resume the broadcast. Samples delivery will resume.
    }

    override func broadcastFinished() {
        // User has requested to finish the broadcast.
    }

    override func processSampleBuffer(_ sampleBuffer: CMSampleBuffer, with sampleBufferType: RPSampleBufferType) {
        switch sampleBufferType {
        case RPSampleBufferType.video:
            if CMSampleBufferDataIsReady(sampleBuffer), sampleBuffer.isValid {
                screencaster.proccessBuffer(sampleBuffer)
            }
        case RPSampleBufferType.audioApp:
            // Handle audio sample buffer for app audio
            break
        case RPSampleBufferType.audioMic:
            // Handle audio sample buffer for mic audio
            break
        @unknown default:
            // Handle other sample buffer types
            fatalError("Unknown type of sample buffer")
        }
    }
}
