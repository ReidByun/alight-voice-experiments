//
//  MusicAssetListView.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/07/22.
//

import SwiftUI
import ComposableArchitecture

struct MusicAssetListView: View {
  let store: Store<MusicAssetListState, MusicAssetListAction>
  @Binding var showView: Bool
  
  var body: some View {
    WithViewStore(self.store) { viewStore in
      List {
        ForEach(viewStore.musicAssets) { musicAsset in
          HStack {
            Image(musicAsset.imageName)
              .resizable()
              .frame(width: 20, height: 20)
            Text(musicAsset.title)
          }
          .onTapGesture {
            viewStore.send(.selecet(id: musicAsset.id))
            showView = false
          }
        }
      }
      .onAppear {
        viewStore.send(.load)
      }
    }
  }
}

struct MusicAssetItemView: View {
  
  var body: some View {
    Text("")
  }
}

struct MusicAssetListView_Previews: PreviewProvider {
    static var previews: some View {
      MusicAssetListView(
        store: .init(
          initialState: MusicAssetListState(),
          reducer: musicAssetListReducer,
          environment: .live(scheduler: .main)
        ), showView: .constant(true)
      )
    }
}
