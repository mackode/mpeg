//
//  Buffer.swift
//  mpeg
//
//  Created by Mackode - Bartlomiej Makowski on 06/09/2019.
//  Copyright © 2019 pl.mackode. All rights reserved.
//

import Foundation

class Buffer {

    var bytes: [UInt8] = []
    var bitIndex: UInt8 = 0
    var capacity: UInt32 = 0
    var length: UInt32 = 0

    /**

     */
    func findStartCode(code: UInt8) -> Int8 {
        return -1
    }

    /**

     */
    func has(length: UInt32) -> Bool {
        return true
    }

    /**

     */
    func skip(length: UInt32) {
    }

    /**

     */
    func skipBytes(length: UInt32) -> UInt32 {
        return 0
    }

    /**
     
     */
    func nextStartCode() -> UInt8 {
        return 0
    }

    /**
     
     */
    func read(position: UInt32) -> UInt8 {
        return 0
    }

    func rewind() {

    }

}
