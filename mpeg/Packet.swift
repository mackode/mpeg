//
//  Packet.swift
//  mpeg
//
//  Created by Mackode - Bartlomiej Makowski on 09/09/2019.
//  Copyright © 2019 pl.mackode. All rights reserved.
//

import Foundation

/**
 
 */
struct Packet {
    var data: [UInt8]
    var length: UInt32
    var type: UInt8
    var pts: Double
}
