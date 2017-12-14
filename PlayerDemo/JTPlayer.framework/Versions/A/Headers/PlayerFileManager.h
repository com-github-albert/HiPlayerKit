//
//  PlayerFileManager.h
//  JTPlayer
//
//  Created by JT Ma on 14/12/2017.
//  Copyright © 2017 JT (ma.jiangtao.86@gmail.com). All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlayerFileManager : NSObject

+ (instancetype)sharedInstance;

+ (void)createDirectoryAtPath:(NSString *)path;
+ (void)createFileAtPath:(NSString *)path;
+ (BOOL)deleteFileAtPath:(NSString *)path;

@property (nonatomic, strong) NSString *destDirectory;
@property (nonatomic, strong) NSString *cacheDirectory;

@end
