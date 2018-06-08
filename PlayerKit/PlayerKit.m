//
//  PlayerKit.m
//  PlayerKit
//
//  Created by Jett on 14/12/2017.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import "PlayerKit.h"
#import "PlayerFileManager.h"

@implementation PlayerKit

+ (NSString *)version { return @"1.0"; }

+ (void)setDestDirectory:(NSString *)destDirectory {
    PlayerFileManager.sharedInstance.destDirectory = destDirectory;
}

+ (NSString *)destDirectory {
    return PlayerFileManager.sharedInstance.destDirectory;
}

+ (void)setCacheDirectory:(NSString *)cacheDirectory {
    PlayerFileManager.sharedInstance.cacheDirectory = cacheDirectory;
}

+ (NSString *)cacheDirectory {
    return PlayerFileManager.sharedInstance.cacheDirectory;
}

- (void)dealloc {
    [PlayerFileManager.sharedInstance clean];
}

@end
