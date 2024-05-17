//
//  Data+Extensions.swift
//  Clutch
//
//  Created by NinjaLikesCheez Hedderwick on 22/10/2020.
//  Copyright © 2020 Kim-Jong Cracks. All rights reserved.
//

import Foundation
import MachO.loader

extension Data {
	func read<T>(at offset: Int) -> T {
		let slice = self[offset..<(offset + MemoryLayout<T>.size)]

		return slice.withUnsafeBytes { buffer in
			buffer.load(as: T.self)
		}
	}
}
