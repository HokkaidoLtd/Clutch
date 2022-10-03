//
//  MachVM+Extensions.swift
//  Clutch
//
//  Created by NinjaLikesCheez Hedderwick on 22/10/2020.
//  Copyright © 2020 Kim-Jong Cracks. All rights reserved.
//

import Foundation

extension mach_vm_address_t {
	init(_ ptr: UnsafeRawPointer?) {
		self.init(UInt(bitPattern: ptr))
	}
}
