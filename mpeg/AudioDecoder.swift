//
//  AudioDecoder.swift
//  mpeg
//
//  Created by Mackode - Bartlomiej Makowski on 06/09/2019.
//  Copyright © 2019 pl.mackode. All rights reserved.
//

// Based on kjmp2 by Martin J. Fiedler
// http://keyj.emphy.de/kjmp2/
import Foundation

/**

 */
enum FrameTypes {
    static let sync: UInt16 = 0x7ff
}

/**

 */
enum MpegVersion {
    static let v2_5: UInt8 = 0x0
    static let v2: UInt8 = 0x2
    static let v1: UInt8 = 0x3
}

/**

 */
enum AudioLayer {
    static let layer3: UInt8 = 0x1
    static let layer2: UInt8 = 0x2
    static let layer1: UInt8 = 0x3
}

/**

 */
enum AudioMode {
    static let stereo: UInt8 = 0x0
    static let jointStereo: UInt8 = 0x1
    static let dualChannel: UInt8 = 0x2
    static let mono: UInt8 = 0x3
}

/**
 * Quantizer lookup, step 2: bitrate class, sample rate -> B2 table idx, sblimit
 */
enum QuantTab {
    static let a: UInt8 = (27 | 64)   // Table 3-B.2a: high-rate, sblimit = 27
    static let b: UInt8 = (30 | 64)   // Table 3-B.2b: high-rate, sblimit = 30
    static let c: UInt8 = 8           // Table 3-B.2c:  low-rate, sblimit =  8
    static let d: UInt8 = 12          // Table 3-B.2d:  low-rate, sblimit = 12
}

/**

 */
struct QuantizerSpec {
    var levels: Int32
    var group: UInt8
    var bits: UInt8
}

/**

 */
class AudioConsts {
    /**

     */
    static let sampleRate: [UInt16] = [
        44100, 48000, 32000, 0, // MPEG-1
        22050, 24000, 16000, 0  // MPEG-2
    ]

    /**

     */
    static let bitRate: [Int16] = [
        32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384, // MPEG-1
         8, 16, 24, 32, 40, 48,  56,  64,  80,  96, 112, 128, 144, 160  // MPEG-2
    ]

    /**

     */
    static let scalefactorBase: [Int] = [
        0x02000000, 0x01965FEA, 0x01428A30
    ]

    /**

     */
    static let synthesisWindow: [Float] = [
             0.0,     -0.5,     -0.5,     -0.5,     -0.5,     -0.5,
            -0.5,     -1.0,     -1.0,     -1.0,     -1.0,     -1.5,
            -1.5,     -2.0,     -2.0,     -2.5,     -2.5,     -3.0,
            -3.5,     -3.5,     -4.0,     -4.5,     -5.0,     -5.5,
            -6.5,     -7.0,     -8.0,     -8.5,     -9.5,    -10.5,
           -12.0,    -13.0,    -14.5,    -15.5,    -17.5,    -19.0,
           -20.5,    -22.5,    -24.5,    -26.5,    -29.0,    -31.5,
           -34.0,    -36.5,    -39.5,    -42.5,    -45.5,    -48.5,
           -52.0,    -55.5,    -58.5,    -62.5,    -66.0,    -69.5,
           -73.5,    -77.0,    -80.5,    -84.5,    -88.0,    -91.5,
           -95.0,    -98.0,   -101.0,   -104.0,    106.5,    109.0,
           111.0,    112.5,    113.5,    114.0,    114.0,    113.5,
           112.0,    110.5,    107.5,    104.0,    100.0,     94.5,
            88.5,     81.5,     73.0,     63.5,     53.0,     41.5,
            28.5,     14.5,     -1.0,    -18.0,    -36.0,    -55.5,
           -76.5,    -98.5,   -122.0,   -147.0,   -173.5,   -200.5,
          -229.5,   -259.5,   -290.5,   -322.5,   -355.5,   -389.5,
          -424.0,   -459.5,   -495.5,   -532.0,   -568.5,   -605.0,
          -641.5,   -678.0,   -714.0,   -749.0,   -783.5,   -817.0,
          -849.0,   -879.5,   -908.5,   -935.0,   -959.5,   -981.0,
         -1000.5,  -1016.0,  -1028.5,  -1037.5,  -1042.5,  -1043.5,
         -1040.0,  -1031.5,   1018.5,   1000.0,    976.0,    946.5,
           911.0,    869.5,    822.0,    767.5,    707.0,    640.0,
           565.5,    485.0,    397.0,    302.5,    201.0,     92.5,
           -22.5,   -144.0,   -272.5,   -407.0,   -547.5,   -694.0,
          -846.0,  -1003.0,  -1165.0,  -1331.5,  -1502.0,  -1675.5,
         -1852.5,  -2031.5,  -2212.5,  -2394.0,  -2576.5,  -2758.5,
         -2939.5,  -3118.5,  -3294.5,  -3467.5,  -3635.5,  -3798.5,
         -3955.0,  -4104.5,  -4245.5,  -4377.5,  -4499.0,  -4609.5,
         -4708.0,  -4792.5,  -4863.5,  -4919.0,  -4958.0,  -4979.5,
         -4983.0,  -4967.5,  -4931.5,  -4875.0,  -4796.0,  -4694.5,
         -4569.5,  -4420.0,  -4246.0,  -4046.0,  -3820.0,  -3567.0,
          3287.0,   2979.5,   2644.0,   2280.5,   1888.0,   1467.5,
          1018.5,    541.0,     35.0,   -499.0,  -1061.0,  -1650.0,
         -2266.5,  -2909.0,  -3577.0,  -4270.0,  -4987.5,  -5727.5,
         -6490.0,  -7274.0,  -8077.5,  -8899.5,  -9739.0, -10594.5,
        -11464.5, -12347.0, -13241.0, -14144.5, -15056.0, -15973.5,
        -16895.5, -17820.0, -18744.5, -19668.0, -20588.0, -21503.0,
        -22410.5, -23308.5, -24195.0, -25068.5, -25926.5, -26767.0,
        -27589.0, -28389.0, -29166.5, -29919.0, -30644.5, -31342.0,
        -32009.5, -32645.0, -33247.0, -33814.5, -34346.0, -34839.5,
        -35295.0, -35710.0, -36084.5, -36417.5, -36707.5, -36954.0,
        -37156.5, -37315.0, -37428.0, -37496.0,  37519.0,  37496.0,
         37428.0,  37315.0,  37156.5,  36954.0,  36707.5,  36417.5,
         36084.5,  35710.0,  35295.0,  34839.5,  34346.0,  33814.5,
         33247.0,  32645.0,  32009.5,  31342.0,  30644.5,  29919.0,
         29166.5,  28389.0,  27589.0,  26767.0,  25926.5,  25068.5,
         24195.0,  23308.5,  22410.5,  21503.0,  20588.0,  19668.0,
         18744.5,  17820.0,  16895.5,  15973.5,  15056.0,  14144.5,
         13241.0,  12347.0,  11464.5,  10594.5,   9739.0,   8899.5,
          8077.5,   7274.0,   6490.0,   5727.5,   4987.5,   4270.0,
          3577.0,   2909.0,   2266.5,   1650.0,   1061.0,    499.0,
           -35.0,   -541.0,  -1018.5,  -1467.5,  -1888.0,  -2280.5,
         -2644.0,  -2979.5,   3287.0,   3567.0,   3820.0,   4046.0,
          4246.0,   4420.0,   4569.5,   4694.5,   4796.0,   4875.0,
          4931.5,   4967.5,   4983.0,   4979.5,   4958.0,   4919.0,
          4863.5,   4792.5,   4708.0,   4609.5,   4499.0,   4377.5,
          4245.5,   4104.5,   3955.0,   3798.5,   3635.5,   3467.5,
          3294.5,   3118.5,   2939.5,   2758.5,   2576.5,   2394.0,
          2212.5,   2031.5,   1852.5,   1675.5,   1502.0,   1331.5,
          1165.0,   1003.0,    846.0,    694.0,    547.5,    407.0,
           272.5,    144.0,     22.5,    -92.5,   -201.0,   -302.5,
          -397.0,   -485.0,   -565.5,   -640.0,   -707.0,   -767.5,
          -822.0,   -869.5,   -911.0,   -946.5,   -976.0,  -1000.0,
          1018.5,   1031.5,   1040.0,   1043.5,   1042.5,   1037.5,
          1028.5,   1016.0,   1000.5,    981.0,    959.5,    935.0,
           908.5,    879.5,    849.0,    817.0,    783.5,    749.0,
           714.0,    678.0,    641.5,    605.0,    568.5,    532.0,
           495.5,    459.5,    424.0,    389.5,    355.5,    322.5,
           290.5,    259.5,    229.5,    200.5,    173.5,    147.0,
           122.0,     98.5,     76.5,     55.5,     36.0,     18.0,
            1.0,    -14.5,    -28.5,    -41.5,    -53.0,    -63.5,
           -73.0,    -81.5,    -88.5,    -94.5,   -100.0,   -104.0,
          -107.5,   -110.5,   -112.0,   -113.5,   -114.0,   -114.0,
          -113.5,   -112.5,   -111.0,   -109.0,    106.5,    104.0,
           101.0,     98.0,     95.0,     91.5,     88.0,     84.5,
            80.5,     77.0,     73.5,     69.5,     66.0,     62.5,
            58.5,     55.5,     52.0,     48.5,     45.5,     42.5,
            39.5,     36.5,     34.0,     31.5,     29.0,     26.5,
            24.5,     22.5,     20.5,     19.0,     17.5,     15.5,
            14.5,     13.0,     12.0,     10.5,      9.5,      8.5,
             8.0,      7.0,      6.5,      5.5,      5.0,      4.5,
             4.0,      3.5,      3.5,      3.0,      2.5,      2.5,
             2.0,      2.0,      1.5,      1.5,      1.0,      1.0,
             1.0,      1.0,      0.5,      0.5,      0.5,      0.5,
             0.5,      0.5
    ]

    /**
     * Quantizer lookup, step 1: bitrate classes
     */
    static let quantLUTstep1: [[UInt8]] = [
        // 32, 48, 56, 64, 80, 96,112,128,160,192,224,256,320,384 <- bitrate
        [ 0,  0,  1,  1,  1,  2,  2,  2,  2,  2,  2,  2,  2,  2 ], // mono
        // 16, 24, 28, 32, 40, 48, 56, 64, 80, 96,112,128,160,192 <- bitrate / chan
        [ 0,  0,  0,  0,  0,  0,  1,  1,  1,  2,  2,  2,  2,  2 ] // stereo
    ]

    /**
     */
    static let quantLUTstep2: [[UInt8]] = [
        // 44.1 kHz,  48 kHz,     32 kHz
        [ QuantTab.c, QuantTab.c, QuantTab.d ], // 32 - 48 kbit/sec/ch
        [ QuantTab.a, QuantTab.a, QuantTab.a ], // 56 - 80 kbit/sec/ch
        [ QuantTab.b, QuantTab.a, QuantTab.b ]  // 96+     kbit/sec/ch
    ]

    /**
     * Quantizer lookup, step 3: B2 table, subband -> nbal, row index
     * (upper 4 bits: nbal, lower 4 bits: row index)
     */
    static let quantLUTstep3: [[UInt8]] = [
        // Low-rate table (3-B.2c and 3-B.2d)
        [
            0x44,0x44,
            0x34,0x34,0x34,0x34,0x34,0x34,0x34,0x34,0x34,0x34
        ],
        // High-rate table (3-B.2a and 3-B.2b)
        [
            0x43,0x43,0x43,
            0x42,0x42,0x42,0x42,0x42,0x42,0x42,0x42,
            0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,0x31,
            0x20,0x20,0x20,0x20,0x20,0x20,0x20
        ],
        // MPEG-2 LSR table (B.2 in ISO 13818-3)
        [
            0x45,0x45,0x45,0x45,
            0x34,0x34,0x34,0x34,0x34,0x34,0x34,
            0x24,0x24,0x24,0x24,0x24,0x24,0x24,0x24,0x24,0x24,
            0x24,0x24,0x24,0x24,0x24,0x24,0x24,0x24,0x24
        ]
    ]

    /**
     * Quantizer lookup, step 4: table row, allocation[] value -> quant table index
     */
    static let quantLUTstep4: [[UInt8]] = [
        [ 0, 1, 2, 17 ],
        [ 0, 1, 2,  3, 4, 5, 6, 17 ],
        [ 0, 1, 2,  3, 4, 5, 6,  7,  8,  9, 10, 11, 12, 13, 14, 17 ],
        [ 0, 1, 3,  5, 6, 7, 8,  9, 10, 11, 12, 13, 14, 15, 16, 17 ],
        [ 0, 1, 2,  4, 5, 6, 7,  8,  9, 10, 11, 12, 13, 14, 15, 17 ],
        [ 0, 1, 2,  3, 4, 5, 6,  7,  8,  9, 10, 11, 12, 13, 14, 15 ]
    ]

    /**

     */
    static let quantTab: [QuantizerSpec] = [
        QuantizerSpec(levels:     3, group: 1, bits: 5), // 1
        QuantizerSpec(levels:     5, group: 1, bits: 7), // 2
        QuantizerSpec(levels:     7, group: 0, bits: 3), // 3
        QuantizerSpec(levels:    9, group: 1, bits: 10), // 4
        QuantizerSpec(levels:    15, group: 0, bits: 4), // 5
        QuantizerSpec(levels:    31, group: 0, bits: 5), // 6
        QuantizerSpec(levels:    63, group: 0, bits: 6), // 7
        QuantizerSpec(levels:   127, group: 0, bits: 7), // 8
        QuantizerSpec(levels:   255, group: 0, bits: 8), // 9
        QuantizerSpec(levels:   511, group: 0, bits: 9), // 10
        QuantizerSpec(levels:  1023, group: 0, bits: 10), // 11
        QuantizerSpec(levels:  2047, group: 0, bits: 11), // 12
        QuantizerSpec(levels:  4095, group: 0, bits: 12), // 13
        QuantizerSpec(levels:  8191, group: 0, bits: 13), // 14
        QuantizerSpec(levels: 16383, group: 0, bits: 14), // 15
        QuantizerSpec(levels: 32767, group: 0, bits: 15), // 16
        QuantizerSpec(levels: 65535, group: 0, bits: 16)  // 17
    ]

}

/**

 */
struct Samples {
    var time: Double
    var count: UInt
    var channels: [[Float]]
}

/**

 */
class VideoDecoder {
    var time: Double
    var samplesDecoded: Int
    var samplerateIndex: Int
    var bitrateIndex: Int
    var version: Int
    var layer: Int
    var mode: Int
    var bound: Int
    var vPos: Int
    var nextFrameDataSize: Int

    var buffer: Buffer
    var allocation: [[QuantizerSpec]]
    var scaleFactorInfo: [[UInt8]]
    var scaleFactor: [[[Int]]]
    var sample: [[[Int]]]
    var samples: Samples
    var D: [Float]
    var V: [Float]
    var U: [Float]
}
