//
//  AudioEngineClient+Live.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/06/25.
//

import AVFoundation
import ComposableArchitecture
import StoreKit

extension AudioEngineClient {
    static var livePlayerClient: Self {
        var delegate: AudioEngineClientWrapper?
        print("init AudioPlayeClient Live ttt")
        return Self(
            setSession: {
                do {
                    try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback, options: AVAudioSession.CategoryOptions.mixWithOthers)
                    NSLog("Playback OK")
                    //try AVAudioSession.sharedInstance().setPreferredSampleRate(48000.0)
                    //sampleRateHz  = 48000.0
                    let duration = 1.00 * (960/48000.0)
                    //let duration = 1.00 * (44100/48000.0)
                    try AVAudioSession.sharedInstance().setPreferredIOBufferDuration(duration)
                    try AVAudioSession.sharedInstance().setActive(true)
                } catch {
                    NSLog("ERROR: CANNOT PLAY MUSIC IN BACKGROUND. Message from code: \"\(error)\"")
                }
            },
            openUrl: { url in
                    .future { callback in // 구독을 시작하면 클로저가 호출됨.
                        delegate?.pause()
                        delegate = nil
                        do {
                            delegate = try AudioEngineClientWrapper(
                                url: url
                            )
                            
                            guard let audioInfo = delegate?.audioInfo else {
                                callback(.failure(.failedToOpenFile))
                                return
                            }
                            
                            callback(.success(audioInfo))
                        } catch {
                            callback(.failure(.failedToOpenFile))
                        }
                    }
            },
            play: {
                .future { callback in
                    guard let playerDelegate = delegate else {
                        callback(.failure(.couldntCreateAudioPlayer))
                        return
                    }
                    //if playerDelegate.didFinishPlaying == nil {
                        playerDelegate.didFinishPlaying = { flag in
                            print("finish playing audio.")
                            delegate?.pause()
                            callback(.success(.didFinishPlaying(successfully: flag)))
                        }
                    //}
                    //if playerDelegate.decodeErrorDidOccur == nil {
                        playerDelegate.decodeErrorDidOccur = { _ in
                            callback(.failure(.decodeErrorDidOccur))
                        }
                    //}
                    
                    playerDelegate.play()
                }
            },
            pause: {
                .fireAndForget {
                    delegate?.pause()
                    //delegate?.player.stop()
                }
            },
            stop: {
                .fireAndForget {
                    delegate?.stop()
                    //delegate?.player.stop()
                }
            },
            currentFrame: {
                .future {callback in
                    guard let delegate = delegate else {
                        callback(.success(0))
                        return
                    }
                    
                    callback(.success(delegate.currentFrame))

                }
            },
            playbackPosition: {
                guard let delegate = delegate else {
                    return 0
                }

                return delegate.currentFrame
            },
            seek: { seekFrame in
                .future { callback in
                    guard let playerDelegate = delegate else {
                        callback(.failure(.couldntCreateAudioPlayer))
                        return
                    }
                    
                    playerDelegate.seek(to: seekFrame) { success in
                        if success {
                            callback(.success(true))
                        }
                        else {
                            callback(.failure(.decodeErrorDidOccur))
                        }
                        
                    }
                }
            }

        )
    }
}

private class AudioEngineClientWrapper: NSObject {
    var didFinishPlaying: ((Bool) -> Void)? = nil
    var decodeErrorDidOccur: ((Error?) -> Void)? = nil
    
    let engine: AVAudioEngine
    let player: AVAudioPlayerNode
    private(set) var audioInfo: ScrubbingPlayerModel
    private(set) var needsFileScheduled = true
    private(set) var url: URL?
    
    private var isSeekingNow = false
    
    var currentFrame: AVAudioFramePosition {
        guard
            let lastRenderTime = player.lastRenderTime,
            let playerTime = player.playerTime(forNodeTime: lastRenderTime)
        else {
            return 0
        }
        //print("last Render(\(lastRenderTime)), playerTime(\(playerTime))")
        return playerTime.sampleTime
    }
    
    init(
        url: URL
    ) throws {
        self.url = url
        self.engine = AVAudioEngine()
        self.audioInfo = ScrubbingPlayerModel()
        self.player = AVAudioPlayerNode()
        super.init()
        
        setupAudioWithBuffer()
    }
    
    private func setupAudioWithBuffer() {
        guard let fileURL = self.url else {
            return
        }
        
        do {
            let file = try AVAudioFile(forReading: fileURL)
            audioInfo.buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))
            try file.read(into: audioInfo.buffer)
            let format = file.processingFormat
            
            audioInfo.audioLengthSamples = file.length
            audioInfo.audioSampleRate = format.sampleRate
            audioInfo.audioChannelCount = format.channelCount
            audioInfo.audioLengthSeconds = Double(audioInfo.audioLengthSamples) / audioInfo.audioSampleRate
            audioInfo.seekFrame = 0
            
            audioInfo.audioFile = file
            
            //sampleRateHz = buffer.format.sampleRate
            //FxScrubbingAudioUnit.getBufferList(from: buffer)
            
            configureEngineWithBuffer(with: audioInfo.buffer)
        } catch {
            print("Error reading the audio file: \(error.localizedDescription)")
        }
    }
    
    private func configureEngineWithBuffer(with buffer: AVAudioPCMBuffer) {
        engine.attach(player)
        //engine.attach(self.myAUNode!)
        guard let file = audioInfo.audioFile else {
            return
        }
        audioInfo.scrubbingSourceNode = GenScrubbingSourceNode(file: file, pcmBuffer: audioInfo.buffer)
        guard let srcNode = audioInfo.scrubbingSourceNode.getSourceNode() else {
           return
        }
        
        engine.attach(srcNode)
        
        engine.connect(
            player,
            to: engine.mainMixerNode,
            format: buffer.format)
        
//        engine.connect(
//            srcNode,
//            to: engine.mainMixerNode,
//            format: buffer.format)
        
        //writeAudioToFile()
        
        engine.prepare()
        
        do {
            try engine.start()
            
            scheduleAudioBuffer()
            audioInfo.isPlayerReady = true
        } catch {
            print("Error starting the player: \(error.localizedDescription)")
        }
    }
    
    private func scheduleAudioBuffer() {
        guard needsFileScheduled else {
            return
        }
        
        needsFileScheduled = false
        
        player.scheduleBuffer(audioInfo.buffer, at: nil, options: [.interruptsAtLoop]) {
        //player.scheduleBuffer(self.buffer) {
            print("play done.!!!")

            if !self.isSeekingNow {
                self.needsFileScheduled = true
                self.didFinishPlaying?(true)
            }
        }
    }
    
    func play() {
        if player.isPlaying == true {
            player.pause()
        }
        
        if needsFileScheduled {
            scheduleAudioBuffer()
        }
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    
    func stop() {
        player.stop()
    }
    
    func seek(to seekFramePosition: AVAudioFramePosition, completion: @escaping (Bool)->Void ) {
        guard let audioFile = audioInfo.audioFile else {
            completion(false)
            return
        }
        
        if seekFramePosition < audioInfo.audioLengthSamples {
            isSeekingNow = true
            
            let wasPlaying = player.isPlaying
            player.stop()
            
            needsFileScheduled = false
            
            let frameCount = AVAudioFrameCount(audioInfo.audioLengthSamples - seekFramePosition)
            print("\(audioInfo.audioLengthSamples), <- \(frameCount) + \(seekFramePosition)")
            
            let test = AVAudioFramePosition(Double(seekFramePosition) + (44100 * 30))
            
            player.scheduleSegment(
                audioFile,
                startingFrame: seekFramePosition,
                frameCount: frameCount,
                at: nil
            ) {
                print("seek done from ScheduleSegment")
                self.needsFileScheduled = true
                //self.player.play()
                //self.scheduleAudioBuffer()
            }
            
////            let seekTime = AVAudioTime(hostTime: mach_absolute_time(), sampleTime: seekFramePosition, atRate: audioInfo.audioSampleRate)
//            let seekTime = AVAudioTime(sampleTime: seekFramePosition, atRate: audioInfo.audioSampleRate)
//
//            print("seek-> \(seekTime) -> (\(Double(seekFramePosition) / audioInfo.audioSampleRate)) ")
//            player.scheduleBuffer(audioInfo.buffer, at: seekTime, options: [.interruptsAtLoop]) {
//                print("play done from seek")
////                if !self.isSeekingNow {
////                    self.needsFileScheduled = true
////                    self.didFinishPlaying?(true)
////                }
//            }
            
            if wasPlaying {
                print("seek play again")
                self.player.play()
            }
            
            print("seek call completion")
            isSeekingNow = false
            completion(true)
        }
        else {
            completion(true)
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if !isSeekingNow {
            self.didFinishPlaying?(flag)
        }
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        self.decodeErrorDidOccur?(error)
    }
}

