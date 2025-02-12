//
//  Item.swift
//  redaa
//
//  Created by Pierre on 2025/02/12.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
