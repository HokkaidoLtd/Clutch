//
//  FrameworkDumper.m
//  Clutch
//
//  Created by NinjaLikesCheez on 30/09/2021.
//  Copyright © 2021 Kim-Jong Cracks. All rights reserved.
//

#import "FrameworkDumper.h"
#import <mach-o/dyld.h>
#import <mach-o/dyld_images.h>

@implementation FrameworkDumper

+ (NSData *)dumpFromIndex:(uint32_t)index totalSize:(uint32_t)size totalPages:(uint32_t)pages fromAddress:(mach_vm_address_t)textStart {
	NSMutableData *data = [[NSMutableData alloc] initWithCapacity:(pages * 0x1000)];

	const struct mach_header *imageHeader = _dyld_get_image_header(index);
	uint32_t pagesProcessed = 0;
	uint32_t pageSize = 0x1000;
	uint8_t *buffer = malloc(pageSize);

	while (size > 0) {
		memcpy(buffer, (unsigned char*)imageHeader + (pagesProcessed * pageSize), pageSize);
		[data appendData: [NSData dataWithBytes:buffer length:pageSize]];

		size -= pageSize;
		pagesProcessed += 1;
	}

	free(buffer);

	return data;
}

@end
