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
        }
    }
    
    
    private var PlayerControlView: some View {
        WithViewStore(self.store) { viewStore in
            VStack {
                //            SliderBarView(value: $viewModel.playerProgress, isEditing: $viewModel.isScrubbing)
                //                .padding(.bottom, 8)
                //                .frame(height: 40)
                PlaybackScrollView(progress: viewStore.playerInfo.playerProgress)
                    .padding(.bottom)
                    
                
                HStack {
                    //Text(viewModel.playerTime.elapsedText)
                    
                    Spacer()
                    
                    //Text(viewModel.playerTime.remainingText)
                }
                .font(.system(size: 14, weight: .semibold))
                
                
                AudioControlButtonsView
                //.disabled(!viewModel.isPlayerReady)
                    .padding(.bottom)
                
            }
            .padding(.horizontal)
        }
    }
    
    private var AudioControlButtonsView: some View {
        WithViewStore(self.store) { viewStore in
            HStack(spacing: 20) {
                Spacer()
                
                Button {
                    //viewModel.skip(forwards: false)
                    print("backward")
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
                } label: {
                    Image.forward
                }
                .font(.system(size: 32))
                
                Spacer()
            }
            .foregroundColor(.primary)
            .padding(.vertical, 20)
            .frame(height: 58)
        }
    }
    //}
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
    @State private var contentOffset: CGPoint = .zero
    @State private var screenSize: CGRect = UIScreen.main.bounds
    @State private var orientation = UIDeviceOrientation.unknown
    @State var scrollVelocity: CGFloat = CGFloat(0)
    var progress: Double
    
    var test: Bool = false

    var body: some View {
        let dragging = DragGesture(minimumDistance: 0, coordinateSpace: .global).onChanged { value in
//            isDragging = true
//            dragLocation = value.location
//            guard let xPos = dragLocation?.x else {
//                isDragging = false
//                return
//            }
//
//            playingBarPos = rectSize.width - calibrateXpos(xPos)
//            timeInDragging = Double(calcTime(from: xPos))
            print("dragging")
        }
        
        VStack {
            Text("off: \(Int(contentOffset.x))")
            ZStack {
                ScrollableView(self.$contentOffset, animationDuration: 0.5, axis: .horizontal, scrollVelocity: $scrollVelocity) {
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
        .ignoresSafeArea()
        .onRotate { newOrientation in
            orientation = newOrientation
            screenSize = UIScreen.main.bounds
        }
        .onChange(of: progress) { currentProgress in
            self.contentOffset = CGPoint(x: progressToOffset(progress: currentProgress, width: screenSize.width), y: 0)
        }
        
        
    }
    
    func progressToOffset(progress: Double, width: Double)-> Double {
        return progress / 100.0 * width
    }
    
    func offsetToProgress(offset: Double, width: Double)-> Double {
        return offset / width * 100.0
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
