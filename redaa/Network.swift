//
//  Network.swift
//  redaa
//
//  Created by Pierre on 2025/02/12.
//

import Foundation
import Apollo

class Network {
  static let shared = Network()

  private init() {}

  private(set) lazy var apollo = ApolloClient(url: URL(string: "https://graphql.anilist.co")!)
}
