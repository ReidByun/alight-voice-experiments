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
  
  private var isScrubbing = false
  private var velocity = 0.0
  private var lastScrubbingStartFrame = 0
  
  private var scrubbingFrame = 0
  private var prevScrubbingFrame = 0
  private var scrubbingStoppedFrame = 0
  private var isForwardScrubbing = true
  
  
  init() {}
  
  convenience init(file: AVAudioFile, pcmBuffer: AVAudioPCMBuffer) {
    self.init()
    audioFile = file
    buffer = pcmBuffer
  }
  
  func getSourceNode(renew: Bool = false)-> AVAudioSourceNode? {
    if sourceNode == nil || renew {
      sourceNode = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
        let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
        self.processScrubbing(ablPointer: ablPointer, frameCount: Int(frameCount))
        return noErr
      }
    }
    
    return sourceNode
  }
  
  func processScrubbing(ablPointer: UnsafeMutableAudioBufferListPointer, frameCount: Int) {
    if let buffer = self.buffer, self.isScrubbing {
      var targetFrame = self.scrubbingFrame
      let currentScrubbingFrame = targetFrame
      
      if prevScrubbingFrame != currentScrubbingFrame {
        scrubbingStoppedFrame = 0
        if prevScrubbingFrame - currentScrubbingFrame < 0 {
          isForwardScrubbing = true
        }
        else {
          isForwardScrubbing = false
        }
      }
      
      let maximumFrameCount = Int(buffer.frameLength)
      if targetFrame == lastScrubbingStartFrame || prevScrubbingFrame == currentScrubbingFrame {
        scrubbingStoppedFrame += frameCount
        if Double(scrubbingStoppedFrame) < (buffer.format.sampleRate / 5.0) { // 200ms
          // using velocity.
          let velocity = self.velocity / 100.0
          if isForwardScrubbing {
            targetFrame = lastScrubbingStartFrame + Int(Double(frameCount) * velocity)
            
            if targetFrame >= maximumFrameCount {
              targetFrame = maximumFrameCount - 1
            }
          }
          else {
            targetFrame = lastScrubbingStartFrame - Int(Double(frameCount) * velocity)
            if (targetFrame < 0) {
              targetFrame = 0
            }
          }
        }
        else {
          // or mute.
          targetFrame = lastScrubbingStartFrame
        }
      }
      
      prevScrubbingFrame = currentScrubbingFrame
      let diff = Double(targetFrame) - Double(lastScrubbingStartFrame)
      var lastOutFrame = 0
      
      if targetFrame != lastScrubbingStartFrame {
        for frameIndex in 0..<Int(frameCount) {
          var inputFrameOffset = Int(Double(lastScrubbingStartFrame) + Double(frameIndex) * diff / Double(frameCount-1))
          //Int inputFrameOffset = floor(lastScrubbingStartFrame + Double(frameIndex * diff) / Double(frameCount-1))
          var inputFrameNextOffset = Int(ceil(Double(lastScrubbingStartFrame) + Double(frameIndex) * diff / Double(frameCount-1)))
          if (inputFrameOffset >= maximumFrameCount) {
            inputFrameOffset = maximumFrameCount
          }
          if inputFrameNextOffset >= maximumFrameCount {
            inputFrameNextOffset = inputFrameOffset
          }
          
          var channel = 0
          for bufferBlock in ablPointer {
            let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(bufferBlock)
            if (diff > 0 && inputFrameOffset <= targetFrame) ||  (diff < 0 && inputFrameOffset >= targetFrame) {
              // MARK: Sample Processing
              buf[frameIndex] = buffer.floatChannelData?[channel][inputFrameOffset] ?? 0
              lastOutFrame = inputFrameOffset
            }
            else {
              buf[frameIndex] = 0
            }
            
            channel = channel + 1
          }
        }
        
        if lastOutFrame != 0 && lastOutFrame != targetFrame {
          lastScrubbingStartFrame = lastOutFrame
        }
        else {
          lastScrubbingStartFrame = targetFrame
        }
      }
      else {
        for bufferBlock in ablPointer {
          let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(bufferBlock)
          _ = (0..<frameCount).map { buf[$0] = 0 }
          //buf.initializeFrom(Repeat(count: frameCount, repeatedValue: 0))
        }
        lastScrubbingStartFrame = targetFrame
      }
      
    }
  }
  
  func updateSource(file: AVAudioFile, pcmBuffer: AVAudioPCMBuffer) {
    audioFile = file
    buffer = pcmBuffer
  }
  
  func setIsScrubbing(on: Bool) {
    self.isScrubbing = on
  }
  
  func setCurrentPlayingFrame(frame: AVAudioFramePosition) {
    self.lastScrubbingStartFrame = Int(frame)
  }
  
  func setScrubbingInfo(frame: AVAudioFramePosition, velocity: Double) {
    self.scrubbingFrame = Int(frame)
    self.velocity = velocity
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
