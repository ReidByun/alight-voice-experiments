//
//  ScrubbingPlayerView.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/06/04.
//

import SwiftUI
import ComposableArchitecture

struct ScrubbingPlayerView: View {
  let store: Store<ScrubbingPlayerState, ScrubbingPlayerAction>
  @State var testOffset: CGPoint = .zero
  let timer = Timer.publish(every: 0.001, on: .main, in: .common).autoconnect()
  @State var press = false
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      VStack {
        Image.artwork
          .resizable()
          .aspectRatio(
            nil,
            contentMode: .fit)
          .padding()
          .layoutPriority(1)
        
        PlayerControlView
          .padding(.bottom)
      }
      .onAppear {
        viewStore.send(.onAppear)
      }
      .onDisappear() {
        viewStore.send(.onDisappear)
      }
    }
  }
  
  
  private var PlayerControlView: some View {
    WithViewStore(self.store) { viewStore in
      VStack {
        PlaybackScrollView(store: self.store, testOffset: $testOffset)
          .padding(.bottom)
        
        HStack {
          Text(viewStore.playerInfo.playerTime.elapsedText)
          
          Spacer()
          
          Text(viewStore.playerInfo.playerTime.remainingText)
        }
        .font(.system(size: 14, weight: .semibold))
        .padding()
        
        
        AudioControlButtonsView
        //.disabled(!viewModel.isPlayerReady)
          .padding(.bottom)
        
        StateButtonView(
          text: "Auto Scroll",
          action: { press in
            viewStore.send(.setScrubbing(on: press))
            self.press = press
          })
        .font(.system(size: 20))
        
      }
      .onReceive(timer) { _ in
        if press {
          if testOffset.x <= 390 {
            testOffset.x = testOffset.x + 0.085
          }
          else {
            testOffset.x = 0
          }
        }
      }
      //.padding(.horizontal)
    }
  }
  
  private var AudioControlButtonsView: some View {
    WithViewStore(self.store) { viewStore in
      HStack(spacing: 20) {
        Spacer()
        
        Button {
          //viewModel.skip(forwards: false)
          print("backward")
          viewStore.send(.seek(time: -10, relative: true))
        } label: {
          Image.backward
        }
        .font(.system(size: 32))
        
        Spacer()
        
        Button {
          print("play / pause")
          viewStore.send(.playPauseTapped(viewStore.playerInfo))
        } label: {
          viewStore.playerInfo.isPlaying ? Image.pause : Image.play
        }
        .frame(width: 40)
        .font(.system(size: 45))
        
        Spacer()
        
        Button {
          print("forward")
          viewStore.send(.seek(time: 10, relative: true))
        } label: {
          Image.forward
        }
        .font(.system(size: 32))
        
        Spacer()
      }
      .foregroundColor(.primary)
      .padding(.vertical, 20)
      .frame(height: 58)
      
      Spacer()
    }
  }
}

fileprivate struct SliderBarView: View {
  @Binding var value: Double
  //@State private var isEditing = false
  @Binding var isEditing: Bool
  
  
  var body: some View {
    VStack {
      Slider(
        value: $value,
        in: 0...100,
        onEditingChanged: { editing in
          isEditing = editing
          
        }
      )
      Text("\(value)")
        .foregroundColor(isEditing ? .red : .blue)
    }
  }
}

struct PlaybackScrollView: View {
  let store: Store<ScrubbingPlayerState, ScrubbingPlayerAction>
  
  @State private var contentOffset: CGPoint = .zero
  @State private var screenSize: CGRect = UIScreen.main.bounds
  @State private var orientation = UIDeviceOrientation.unknown
  
  @State var scrollVelocity: CGFloat = CGFloat(0)
  
  @State var nowScrubbing: Bool = false
  @Binding var testOffset: CGPoint
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      VStack {
        Text("off: \(Int(contentOffset.x))")
        ZStack {
          ScrollableView(
            self.$contentOffset,
            animationDuration: 0.5,
            axis: .horizontal,
            scrollVelocity: $scrollVelocity,
            beginDragging: { self.nowScrubbing = true },
            endDragging: {_ in self.nowScrubbing = false }) {
              ZStack {
                Color.clear
                  .frame(width: screenSize.width*2, height: 60)
                HStack(spacing: 0) {
                  Color.black
                    .frame(width: screenSize.width/2, height: 60)
                  Color.green
                    .frame(width: screenSize.width, height: 60)
                  Color.black
                    .frame(width: screenSize.width/2, height: 60)
                    .id(3)  //Set the Id
                }
              }
            }
          
          VStack(spacing: 0) {
            Color.black
              .frame(width: 3, height: 100)
          }
        }
      }
      .onRotate { newOrientation in
        orientation = newOrientation
        screenSize = UIScreen.main.bounds
        print("screen: \(screenSize)")
      }
      .onChange(of: viewStore.playerInfo.playerProgress) { currentProgress in
        if !nowScrubbing {
          self.contentOffset = CGPoint(x: progressToOffset(progress: currentProgress, width: screenSize.width), y: 0)
        }
      }
      .onChange(of: nowScrubbing) { newStateScrubbing in
        print("scrubbing: \(newStateScrubbing) \(viewStore.isScrubbingNow)")
        viewStore.send(.setScrubbing(on: newStateScrubbing))
        
        if newStateScrubbing && viewStore.playerInfo.isPlaying {
          viewStore.send(.playPauseTapped(viewStore.playerInfo))
        }
        
        let progress = offsetToProgress(offset: Double(contentOffset.x), width: screenSize.width)
        if viewStore.isScrubbingNow {
          self.contentOffset = CGPoint(x: progressToOffset(progress: progress, width: screenSize.width), y: 0)
        }
        
        if viewStore.isScrubbingNow != newStateScrubbing && !newStateScrubbing {
          let seekTime = progressToTime(progress: progress, totalTime: viewStore.playerInfo.audioLengthSeconds)
          print("seek time \(seekTime)")
          viewStore.send(.seek(time: seekTime, relative: false))
        }
      }
      .onChange(of: contentOffset) { offset in
        if viewStore.isScrubbingNow {
          let progress = offsetToProgress(offset: Double(contentOffset.x), width: screenSize.width)
          let frame = progressToFrame(progress: progress, totalFrame: Int(viewStore.playerInfo.audioLengthSamples))
          viewStore.send(.setScrubbingProperties(frame: frame, velocity: scrollVelocity))
        }
      }
      .onChange(of: testOffset) { offset in
        self.contentOffset = offset
      }
    }
  }
  
  func progressToOffset(progress: Double, width: Double)-> Double {
    return progress / 100.0 * width
  }
  
  func offsetToProgress(offset: Double, width: Double)-> Double {
    return offset / width * 100.0
  }
  
  func progressToTime(progress: Double, totalTime: Double)-> Double {
    return progress / 100.0 * totalTime
  }
  
  func progressToFrame(progress: Double, totalFrame: Int)-> Int {
    return Int(progress * Double(totalFrame) / 100.0)
  }
}


fileprivate struct StateButtonView: View {
  @State var press = false
  var text: String
  var action: (Bool)-> Void
  
  var body: some View {
    Button {
      press = !press
      action(press)
    } label: {
      Text(text)
    }
  }
}



fileprivate struct ProgressBarView: View {
  @Binding var value: Double
  
  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .leading) {
        Rectangle().frame(width: geometry.size.width , height: geometry.size.height)
          .foregroundColor(Color(UIColor.systemTeal))
        
        Rectangle().frame(width: min(CGFloat(self.value)*geometry.size.width, geometry.size.width), height: geometry.size.height)
          .foregroundColor(Color(UIColor.blue))
          .animation(.linear)
      }.cornerRadius(22)
    }
  }
}

//struct ScrubbingPlayerView_Previews: PreviewProvider {
//    static var previews: some View {
//        ScrubbingPlayerView()
//    }
//}
