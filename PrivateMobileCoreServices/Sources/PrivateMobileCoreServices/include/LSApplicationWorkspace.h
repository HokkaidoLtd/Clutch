//
//  LSApplicationWorkspace.h
//  Clutch
//
//  Created by Anton Titkov on 18/10/2019.
//  Copyright © 2019 Kim-Jong Cracks. All rights reserved.
//

#ifndef LSApplicationWorkspace_h
#define LSApplicationWorkspace_h

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface LSBundleProxy : NSObject
@property(readonly) NSString * bundleIdentifier;
@property(readonly) NSURL * bundleURL;
@property(readonly) NSURL * bundleContainerURL;
@property(readonly) NSString * bundleExecutable;
@property(readonly) NSString * bundleVersion;
@property(readonly) NSURL * containerURL;
@property(readonly) NSURL * dataContainerURL;
@property(readonly) NSDictionary *entitlements;
@property(readonly) NSDictionary *environmentVariables;
@property(readonly) NSString *signerIdentity;
@property(readonly) NSString * localizedShortName;
@end

@interface LSPlugInKitProxy : LSBundleProxy
+ (instancetype)pluginKitProxyForIdentifier:(NSString *)pluginIdentifier;
@property(readonly) LSBundleProxy *containingBundle;
@property(readonly) NSDictionary *infoPlist;
@property(readonly) BOOL isOnSystemPartition;
@property(readonly) NSString *originalIdentifier;
@property(readonly) NSString *pluginIdentifier;
@property(readonly) NSDictionary *pluginKitDictionary;
@property(readonly) NSUUID *pluginUUID;
@property(readonly) NSString *protocol;
@property(readonly) NSDate *registrationDate;
@end

@interface LSApplicationProxy : LSBundleProxy
+ (instancetype)applicationProxyForIdentifier:(NSString *)appIdentifier;
@property(readonly) NSString * applicationIdentifier;
@property(readonly) NSString * applicationType;
@property(readonly) NSArray * deviceFamily;
@property(readonly) NSString * localizedName;
@property(readonly) NSString * shortVersionString;
@property(readonly) BOOL isStickerProvider;
@property(readonly) BOOL isInstalled;
@property(readonly) NSArray<LSPlugInKitProxy *> *plugInKitPlugins;
@end

@interface LSApplicationWorkspace : NSObject

typedef NS_ENUM(NSUInteger, Type) {
    User = 0,
    System = 1,
};

+ (instancetype)defaultWorkspace;
- (NSArray<LSApplicationProxy *> *)applicationsOfType:(Type)arg1;
- (NSArray<LSApplicationProxy *> *)blacklistedApps;

@end

NS_ASSUME_NONNULL_END

#endif /* LSApplicationWorkspace_h */
