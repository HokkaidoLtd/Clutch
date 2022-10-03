//
//  Executable+Extensions.swift
//  Clutch
//
//  Created by Anton Titkov on 19/10/2019.
//  Copyright © 2019 Kim-Jong Cracks. All rights reserved.
//

import Foundation

let cputypes = [
	CPU_TYPE_ARM: "arm",
	CPU_TYPE_ARM64: "arm64"
]

let cpusubtypes = [
	CPU_SUBTYPE_ARM_V7: "armv7",
	CPU_SUBTYPE_ARM_V7S: "armv7s",
	CPU_SUBTYPE_ARM_V7K: "armv7k",
	
	CPU_SUBTYPE_ARM_V8: "armv8",
	
	CPU_SUBTYPE_ARM64_ALL: "arm64",
	CPU_SUBTYPE_ARM64_V8: "arm64v8",
	CPU_SUBTYPE_ARM64E: "arm64e"
]

extension Executable {
	static func readable(arch: ArchHeader) -> (String, String) {
		(cputypes[arch.header.cputype] ?? "unknown", cpusubtypes[arch.header.cpusubtype] ?? "unknown")
	}
}
