//
//  ASLRDisabler.h
//  Clutch
//
//  Created by NinjaLikesCheez on 27/09/2021.
//  Copyright © 2021 Kim-Jong Cracks. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ASLRDisabler : NSObject

+ (mach_vm_address_t)slideForPID:(pid_t)pid;

@end

NS_ASSUME_NONNULL_END
