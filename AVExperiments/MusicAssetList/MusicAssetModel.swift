//
//  MusicAssetModel.swift
//  AVExperiments
//
//  Created by Reid Byun on 2022/07/22.
//

import Foundation


struct MusicAssetModel: Equatable, Identifiable {
  var id: Int = 0
  var imageName: String = ""
  var path: String = ""
  var url: URL {
    URL(fileURLWithPath: self.path)
  }
  var title: String {
    (self.path as NSString).lastPathComponent
  }
}
