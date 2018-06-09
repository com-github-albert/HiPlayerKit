//
//  PlayerFileManager.h
//  PlayerKit
//
//  Created by Jett on 14/12/2017.
//  Copyright © 2018 <https://github.com/mutating>. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayerFileManager : NSObject

+ (instancetype)sharedInstance;

+ (void)createDirectoryAtPath:(NSString *)path;
+ (void)createFileAtPath:(NSString *)path;
+ (BOOL)deleteFileAtPath:(NSString *)path;

@property (nonatomic, strong) NSString *destDirectory;
@property (nonatomic, strong) NSString *cacheDirectory;

- (void)clean;

@end

NS_ASSUME_NONNULL_END
