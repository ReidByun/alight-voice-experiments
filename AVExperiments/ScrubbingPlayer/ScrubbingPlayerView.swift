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
                
                Spacer()
                
                Button {
                    print("play / pause")
                    viewStore.send(.playPauseTapped(viewStore.playerInfo))
                } label: {
                    //                ZStack {
                    //                    Color.blue
                    //                        .frame(
                    //                            width: 10,
                    //                            height: 35 * CGFloat(viewModel.meterLevel))
                    //                        .opacity(0.5)
                    //
                    viewStore.playerInfo.isPlaying ? Image.pause : Image.play
                    //                }
                }
                .frame(width: 40)
                .font(.system(size: 45))
                
                PlayerControlView
                    .padding(.bottom)
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
    
    
    private var PlayerControlView: some View {
        VStack {
            //            SliderBarView(value: $viewModel.playerProgress, isEditing: $viewModel.isScrubbing)
            //                .padding(.bottom, 8)
            //                .frame(height: 40)
            
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
                    //                viewStore.send(.playPauseTapped(viewStore.playerInfo))
                } label: {
                    //                ZStack {
                    //                    Color.blue
                    //                        .frame(
                    //                            width: 10,
                    //                            height: 35 * CGFloat(viewModel.meterLevel))
                    //                        .opacity(0.5)
                    //
                    //                    viewStore.playerInfo.isPlaying ? Image.pause : Image.play
                    //                }
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
