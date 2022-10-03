//
//  ExDefines.swift
//  Clutch
//
//  Created by Anton Titkov on 10/11/2019.
//  Copyright © 2019 Kim-Jong Cracks. All rights reserved.
//

import Foundation

let CSMAGIC_EMBEDDED_SIGNATURE: UInt32 = 0xfade0cc0
let CSSLOT_CODEDIRECTORY = 0
let PT_TRACE_ME = 0

struct blob_index: CustomStringConvertible {
	private var _type: UInt32 = 0
	private var _offset: UInt32 = 0
	
	var type: UInt32 {
		_OSSwapInt32(_type)
	}
	
	var offset: UInt32 {
		_OSSwapInt32(_offset)
	}
	
	var description: String {
		"blob_index(type: \(type), offset: \(offset))"
	}
}

struct super_blob: CustomStringConvertible {
	private var _magic: UInt32 = 0
	private var _length: UInt32 = 0
	private var _count: UInt32 = 0
	
	var magic: UInt32 {
		_OSSwapInt32(_magic)
	}
	
	var length: UInt32 {
		_OSSwapInt32(_length)
	}
	
	var count: UInt32 {
		_OSSwapInt32(_count)
	}
	
	var description: String {
		"super_blob(magic: \(magic.hexString), length: \(length), count: \(count))"
	}
}

struct code_directory: CustomStringConvertible {
	private var _magic: UInt32 = 0
	private var _length: UInt32 = 0
	private var _version: UInt32 = 0
	private var _flags: UInt32 = 0
	private var _hashOffset: UInt32 = 0
	private var _identOffset: UInt32 = 0
	private var _nSpecialSlots: UInt32 = 0
	private var _nCodeSlots: UInt32 = 0 /* number of ordinary (code) hash slots */
	private var _codeLimit: UInt32 = 0
	private var _hashSize: UInt8 = 0
	private var _hashType: UInt8 = 0
	private var _spare1: UInt8 = 0
	private var _pageSize: UInt8 = 0
	private var _spare2: UInt32 = 0
	
	var magic: UInt32 {
		_OSSwapInt32(_magic)
	}
	
	var length: UInt32 {
		_OSSwapInt32(_length)
	}
	
	var version: UInt32 {
		_OSSwapInt32(_version)
	}
	
	var flags: UInt32 {
		_OSSwapInt32(_flags)
	}
	
	var hashOffset: UInt32 {
		_OSSwapInt32(_hashOffset)
	}
	
	var identOffset: UInt32 {
		_OSSwapInt32(_identOffset)
	}
	
	var nSpecialSlots: UInt32 {
		_OSSwapInt32(_nSpecialSlots)
	}
	
	var nCodeSlots: UInt32 {
		_OSSwapInt32(_nCodeSlots)
	}
	
	var codeLimit: UInt32 {
		_OSSwapInt32(_codeLimit)
	}
	
	var hashSize: UInt8 {
		_hashSize
	}
	
	var hashType: UInt8 {
		_hashType
	}
	
	var spare1: UInt8 {
		_spare1
	}
	
	var pageSize: UInt8 {
		_pageSize
	}
	
	var spare2: UInt32 {
		_OSSwapInt32(_spare2)
	}
	
	var description: String {
		"code_directory(magic: \(magic.hexString), length: \(length), version: \(version), flags: \(flags), hashOffset: \(hashOffset), identOffset: \(identOffset), nSpecialSlots: \(nSpecialSlots), nCodeSlots: \(nCodeSlots), codeLimit: \(codeLimit), hashSize: \(hashSize), hashType: \(hashType), spare1: \(spare1), pageSize: \(pageSize), spare2: \(spare2))"
	}
}
