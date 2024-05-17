//
//  BinaryInteger+Extensions.swift
//  Clutch
//
//  Created by NinjaLikesCheez Hedderwick on 22/10/2020.
//  Copyright © 2020 Kim-Jong Cracks. All rights reserved.
//

import Foundation

extension BinaryInteger {
	var hexString: String {
		"0x\(String(self, radix: 16, uppercase: true))"
	}
}
