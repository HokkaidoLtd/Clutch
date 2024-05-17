// swiftlint:disable comment_spacing
//////
//////  ASLRDisabler.swift
//////  Clutch
//////
//////  Created by NinjaLikesCheez Hedderwick on 12/11/2019.
//////  Copyright © 2019 Kim-Jong Cracks. All rights reserved.
//////
////
////import Foundation
////
//import MachO.loader
//
//class ASLRDisabler {
//	static func slide(forPID pid: Int32) -> mach_vm_address_t {
//		var target: vm_map_t = 0
//		var return_value: kern_return_t = 0 // don't remove this unused variable, it will break the function???
//
//		var kernel_return = task_for_pid(mach_task_self_, pid, &target)
//		if kernel_return != KERN_SUCCESS {
//			print("tfp0 failed: \(kernel_return)")
//			return 0
//		}
//
//		let VM_REGION_SUBMAP_INFO_V2_COUNT_64: mach_msg_type_number_t = mach_msg_type_number_t((MemoryLayout<vm_region_submap_info_data_64_t>.size / MemoryLayout<natural_t>.size))
//
//		var iter: vm_address_t = 0
//		var i: Int32 = 0
//
//		while true {
//			var address: vm_address_t = iter
//			var size: vm_size_t = 0
//			var depth: UInt32 = 0
//			var count: mach_msg_type_number_t = VM_REGION_SUBMAP_INFO_V2_COUNT_64
//
//			print("\n\n\n")
//			print("target(\(type(of: target))) = \(target)")
//			print("address(\(type(of: address))) = \(address)")
//			print("size(\(type(of: size))) = \(size)")
//			print("depth(\(type(of: depth))) = \(depth)")
//			print("count(\(type(of: count))) = \(count)")
//
//			kernel_return = withUnsafeMutablePointer(to: &i) {
//				vm_region_recurse_64(target, &address, &size, &depth, $0, &count)
//			}
//
//			if kernel_return != KERN_SUCCESS {
//				if let errorChar = mach_error_string(kernel_return),
//					 let errorString = String(utf8String: errorChar) {
//					print("vm_region_recurse_64 error: \(errorString)")
//				} else {
//					print("vm_region_recurse_64 error: \(kernel_return)")
//				}
//
//				break
//			}
//
//			var bytes_read: mach_vm_size_t = 0
//			var mh: mach_header = mach_header()
//
//			withUnsafePointer(to: &mh, {
//				let voidPtr = UnsafeRawPointer($0)
//				kernel_return = mach_vm_read_overwrite(
//					target,
//					mach_vm_address_t(address),
//					mach_vm_size_t(MemoryLayout<mach_header>.size),
//					mach_vm_address_t(voidPtr),
//					&bytes_read
//				)
//			})
//
//			if kernel_return != KERN_SUCCESS {
//				print("mach_vm_read_overwrite return: \(kernel_return)")
//			}
//
//			if kernel_return == KERN_SUCCESS && bytes_read == MemoryLayout<mach_header>.size {
//				if (mh.magic == MH_MAGIC || mh.magic == MH_MAGIC_64) && mh.filetype == MH_EXECUTE {
//					print("Found main binary mach-o image @ 0x\(address.hexString)")
//					return mach_vm_address_t(address)
//				}
//			}
//
//			iter = address + size
//		}
//
//		print("should not reach here!")
//		return 0
//	}
//}
// swiftlint:enable comment_spacing
