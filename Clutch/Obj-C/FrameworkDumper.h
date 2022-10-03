//
//  FrameworkDumper.h
//  Clutch
//
//  Created by NinjaLikesCheez on 30/09/2021.
//  Copyright © 2021 Kim-Jong Cracks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FrameworkDumper : NSObject

+ (NSData *)dumpFromIndex:(uint32_t)index totalSize:(uint32_t)size totalPages:(uint32_t)pages fromAddress:(mach_vm_address_t)textStart;

@end

NS_ASSUME_NONNULL_END
