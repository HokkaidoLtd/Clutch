//
//  Device.swift
//  Clutch
//
//  Created by Anton Titkov on 19/10/2019.
//  Copyright © 2019 Kim-Jong Cracks. All rights reserved.
//

import MachO.dyld

struct Device {
	static var cputype: cpu_type_t {
		let header = _dyld_get_image_header(0)
		return header!.pointee.cputype
	}
	
	static var cpusubtype: cpu_subtype_t {
		let header = _dyld_get_image_header(0)
		return header!.pointee.cpusubtype
	}
}
