//
//  ScrubbingPlayerModel.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/06/04.
//

import Foundation


struct ScrubbingPlayerModel: Equatable {
    var isPlayerReady = false
    var playerTime: PlayerTime = .zero
    
    private var scrubbingInPlaying = false
    
    
    var isPlaying = false
    var playerProgress: Double = 0
    
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
