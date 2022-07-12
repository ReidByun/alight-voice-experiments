//
//  GenScrubbingSourceNode.swift
//  AudioExperiments
//
//  Created by Reid Byun on 2022/06/15.
//

import Foundation
import AVFoundation

class GenScrubbingSourceNode: Equatable {
  
  private var sourceNode: AVAudioSourceNode? = nil
  private var audioFile: AVAudioFile? = nil
  private var buffer: AVAudioPCMBuffer? = nil
  private var acc = 0
  var isScrubbing = true
  
  init() {}
  
  convenience init(file: AVAudioFile, pcmBuffer: AVAudioPCMBuffer) {
    self.init()
    audioFile = file
    buffer = pcmBuffer
  }
  
  func getSourceNode()-> AVAudioSourceNode? {
    sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
      let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
      self.processScrubbing(ablPointer: ablPointer, frameCount: Int(frameCount))
      return noErr
    }
    
    return sourceNode
  }
  
  func processScrubbing(ablPointer: UnsafeMutableAudioBufferListPointer, frameCount: Int) {
    for frame in 0..<Int(frameCount) {
      var channel = 0
      for bufferBlock in ablPointer {
        let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(bufferBlock)
        if let buffer = self.buffer, self.isScrubbing {
          buf[frame] = buffer.floatChannelData?[channel][frame + self.acc] ?? 0
        }
        else {
          buf[frame] = 0
        }
        
        channel = channel + 1
      }
    }
    acc = acc + frameCount
  }
  
  static func == (lhs: GenScrubbingSourceNode, rhs: GenScrubbingSourceNode) -> Bool {
    return lhs.audioFile == rhs.audioFile
  }
}

extension GenScrubbingSourceNode {
  static func live() -> GenScrubbingSourceNode {
    return .init()
  }
}
