//
//  Item.swift
//  HiddenPlaces
//
//  Created by Gianfranco Rutili on 21/11/26.
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
