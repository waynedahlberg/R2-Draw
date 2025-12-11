//
//  Item.swift
//  r2draw
//
//  Created by Wayne Dahlberg on 12/11/25.
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
