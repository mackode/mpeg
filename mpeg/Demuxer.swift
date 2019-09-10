//
//  Demuxer.swift
//  mpeg
//
//  Created by Mackode - Bartlomiej Makowski on 06/09/2019.
//  Copyright © 2019 pl.mackode. All rights reserved.
//

import Foundation


/**

 */
enum StartCodes {
    static let pack: UInt8 = 0xBA
    static let end: UInt8 = 0xB9
    static let system: UInt8 = 0xBB
}

/**

 */
enum PacketTypes {
    static let priv: UInt8 = 0xBD
    static let audio1: UInt8 = 0xC0
    static let audio2: UInt8 = 0xC1
    static let audio3: UInt8 = 0xC2
    static let audio4: UInt8 = 0xC3
    static let video: UInt8 = 0xE0
}

/**

 */
class Demuxer {
    var buffer: Buffer
    var systemClockRef: Double = 0.0
    var hasPackHeader: Bool = false
    var hasSystemHeader: Bool = false
    var numAudioStreams: UInt8 = 0
    var numVideoStreams: UInt8 = 0
    var currentPacket: Packet? = nil
    var nextPacket: Packet? = nil

    /**

     */
    init(buffer: Buffer) {
        self.buffer = buffer

        if buffer.findStartCode(code: StartCodes.pack) != -1 {
            self.decodePackHeader()
        }

        if buffer.findStartCode(code: StartCodes.system) != -1 {
            self.decodeSystemHeader()
        }
    }

    /**

     */
    func decode() -> Packet? {
        if let length = currentPacket?.length {
            let bitsTillNextPacket = length << 3
            if self.buffer.has(length: bitsTillNextPacket) {
                return nil
            }

            self.buffer.skip(length: bitsTillNextPacket)
            self.currentPacket?.length = 0
        }

        if self.hasPackHeader {
            if buffer.findStartCode(code: StartCodes.pack) != -1 {
                self.decodePackHeader()
            } else {
                return nil
            }
        }

        if self.hasSystemHeader {
            if buffer.findStartCode(code: StartCodes.system) != -1 {
                self.decodeSystemHeader()
            } else {
                return nil
            }
        }

        // pending packet
        if self.nextPacket?.length != 0 {
            return getPacket()
        }

        var code: UInt8
        repeat {
            code = self.buffer.nextStartCode()
            if code == PacketTypes.priv || code == PacketTypes.video || (code >= PacketTypes.audio1 && code <= PacketTypes.audio4) {
                return self.decodePacket(code: code)
            }
        } while (code != -1)

        return nil
    }

    /**

     */
    func decodePacket(code: UInt8) -> Packet? {
        if !self.buffer.has(length: 8 << 3) {
            return nil
        }

        self.nextPacket?.type = code
        self.nextPacket?.length = UInt32(self.buffer.read(position: 16))
        self.nextPacket?.length -= self.buffer.skipBytes(length: 0xFF) // stuffing

        // skip P-STD
        if self.buffer.read(position: 2) == 0x01 {
            self.buffer.skip(length: 16)
            self.nextPacket?.length -= 2
        }

        let ptsDtsMarker = self.buffer.read(position: 2)
        if ptsDtsMarker == 0x03 {
            self.nextPacket?.pts = self.readTime()
            self.buffer.skip(length: 40) // skip dts
            self.nextPacket?.length -= 10
        } else if ptsDtsMarker == 0x02 {
            self.nextPacket?.pts = self.readTime()
            self.nextPacket?.length -= 5
        } else if ptsDtsMarker == 0x00 {
            self.nextPacket?.pts = 0
            self.buffer.skip(length: 4)
            self.nextPacket?.length -= 1
        } else {
            return nil // invalid
        }

        return self.getPacket();
    }

    /**

     */
    func getPacket() -> Packet? {
        if !self.buffer.has(length: (self.nextPacket?.length ?? 0 << 3)) {
            return nil
        }

        self.currentPacket?.data = self.buffer.bytes + ([self.buffer.bitIndex >> 3])
        self.currentPacket?.length = self.nextPacket!.length
        self.currentPacket?.type = self.nextPacket!.type
        self.currentPacket?.pts = self.nextPacket!.pts

        self.nextPacket?.length = 0
        return currentPacket
    }

    /**

     */
    func decodePackHeader() {
        if self.buffer.read(position: 4) != 0x02 {
            return // invalid
        }

        self.systemClockRef = self.readTime()
        self.buffer.skip(length: 1)
        self.buffer.skip(length: 22) // mux_rate * 50
        self.buffer.skip(length: 1)

        self.hasPackHeader = true
    }

    /**

     */
    func decodeSystemHeader() {
        self.buffer.skip(length: 16) // header_length
        self.buffer.skip(length: 24) // rate bound
        self.numAudioStreams = self.buffer.read(position: 6)
        self.buffer.skip(length: 5) // misc flags
        self.numVideoStreams = self.buffer.read(position: 5)

        self.hasSystemHeader = true
    }

    /**

     */
    func readTime() -> Double {
        var clock: Int64 = Int64(self.buffer.read(position: 3) << 30)
        self.buffer.skip(length: 1)
        clock |= Int64(self.buffer.read(position: 15) << 15)
        self.buffer.skip(length: 1)
        clock |= Int64(self.buffer.read(position: 15))
        self.buffer.skip(length: 1)
        return Double(clock) / 90000.0
    }

    /**
     
     */
    func rewind() {
        self.buffer.rewind()
    }

}
