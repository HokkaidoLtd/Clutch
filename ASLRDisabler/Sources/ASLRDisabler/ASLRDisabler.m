//
//  ASLRDisabler.m
//  Clutch
//
//  Created by NinjaLikesCheez on 27/09/2021.
//  Copyright © 2021 Kim-Jong Cracks. All rights reserved.
//

#import "ASLRDisabler.h"

// #import "mach_vm.h"
#import <mach/mach_vm.h>
#import <mach/mach_init.h>
#import <mach/vm_map.h>

@import MachO.loader;

@implementation ASLRDisabler

// TODO: use the logger class when you can figure out why it's not importing via the bridging headers
+ (mach_vm_address_t)slideForPID:(pid_t)pid {
	vm_map_t targetTask = 0;

	if (task_for_pid(mach_task_self(), pid, &targetTask)) {
		printf("[!] Can't execute task_for_pid! Do you have the right permissions/entitlements?");
		return 0;
	}

	kern_return_t kernelReturn = 0;
	vm_address_t address = 0;

	while (1) {
		struct mach_header header = {0};
		vm_size_t size = 0;
		uint32_t depth = 0;
		mach_vm_size_t bytesRead = 0;
		struct vm_region_submap_info_64 info = {0};
		mach_msg_type_number_t count = VM_REGION_SUBMAP_INFO_COUNT_64;

		if (vm_region_recurse_64(targetTask, &address, &size, &depth, (vm_region_info_t)&info, &count)) {
			break;
		}

		kernelReturn = mach_vm_read_overwrite(targetTask,
																					(mach_vm_address_t)address,
																					(mach_vm_size_t)sizeof(struct mach_header),
																					(mach_vm_address_t)&header,
																					&bytesRead);

		if (kernelReturn == KERN_SUCCESS && bytesRead == sizeof(struct mach_header)) {
			/* only one image with MH_EXECUTE filetype */
			if ((header.magic == MH_MAGIC || header.magic == MH_MAGIC_64) && header.filetype == MH_EXECUTE) {
				printf("[+] Found main binary mach-o image @ %p!\n", (void *)address);
				return address;
			}
		}

		address += size;
	}

	printf("[!] Should not reach here");
	return 0;
}

@end
