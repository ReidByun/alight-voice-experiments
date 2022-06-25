//
//  ScrubbingPlayerModel.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/06/04.
//

import Foundation
import AVFoundation

struct ScrubbingPlayerModel: Equatable {
    
    // initial info.
    var buffer: AVAudioPCMBuffer!
    var audioLengthSamples: AVAudioFramePosition = 0
    var audioFile: AVAudioFile?
    var audioSampleRate: Double = 0
    var audioLengthSeconds: Double = 0
    var audioChannelCount: AVAudioChannelCount = 0
    
    
    var isPlayerReady = false
    var playerTime: PlayerTime = .zero
    
    private var scrubbingInPlaying = false
    
    var isPlaying = false
    var playerProgress: Double = 0
    
    var scrubbingSourceNode: GenScrubbingSourceNode!
    
    
    var seekFrame: AVAudioFramePosition = 0
    
    
    //    var playbackMode = PlaybackMode.notPlaying
    //    enum PlaybackMode: Equatable {
    //        case notPlaying
    //        case playing(progress: Double)
    //
    //        var isPlaying: Bool {
    //            if case .playing = self { return true }
    //            return false
    //        }
    //
    //        var progress: Double? {
    //            if case let .playing(progress) = self { return progress }
    //            return nil
    //        }
    //    }
}

extension ScrubbingPlayerModel: Identifiable {
    var id: Int { Int.random(in: 0..<100) }
}
