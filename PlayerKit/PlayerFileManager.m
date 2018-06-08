//
//  PlayerFileManager.m
//  PlayerKit
//
//  Created by Jett on 14/12/2017.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import "PlayerFileManager.h"

@implementation PlayerFileManager

@synthesize destDirectory = _destDirectory, cacheDirectory = _cacheDirectory;

static id sharedInstance = nil;
static dispatch_once_t onceToken = 0;

+ (instancetype)sharedInstance {
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

+ (void)createDirectoryAtPath:(NSString *)path {
    BOOL isDirectory, isExist;
    isExist = [NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDirectory];
    if (!isExist || !isDirectory) {
        [NSFileManager.defaultManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

+ (void)createFileAtPath:(NSString *)path {
    BOOL isExist = [NSFileManager.defaultManager fileExistsAtPath:path];
    if (isExist) {
        [NSFileManager.defaultManager removeItemAtPath:path error:nil];
    }
    [NSFileManager.defaultManager createFileAtPath:path contents:nil attributes:nil];
}

+ (BOOL)deleteFileAtPath:(NSString *)path {
    NSError* error;
    BOOL isDirectory, isExist;
    isExist = [NSFileManager.defaultManager fileExistsAtPath:path isDirectory:&isDirectory];
    if (isExist) {
        BOOL success = [NSFileManager.defaultManager removeItemAtPath:path error:&error];
        if (success) {
            return YES;
        } else {
            NSLog(@"Delete directory failure: %@", error.description);
        }
    }
    return NO;
}

- (NSString *)destDirectory {
    if (_destDirectory == nil) {
        NSString *nsCachePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];
        _destDirectory = nsCachePath;
    }
    return _destDirectory;
}

- (void)setDestDirectory:(NSString *)destDirectory {
    _destDirectory = destDirectory;
    [PlayerFileManager createDirectoryAtPath:_destDirectory];
}

- (NSString *)cacheDirectory {
    if (_cacheDirectory == nil) {
        NSString *nsTempPath = NSTemporaryDirectory();
        _cacheDirectory = nsTempPath;
    }
    return _cacheDirectory;
}

- (void)setCacheDirectory:(NSString *)cacheDirectory {
    _cacheDirectory = cacheDirectory;
    [PlayerFileManager createDirectoryAtPath:_cacheDirectory];
}

- (void)clean {
    sharedInstance = nil;
    onceToken = 0;
}

- (void)dealloc {
    NSLog(@"%@ dealloc", NSStringFromClass(self.class));
}

@end
