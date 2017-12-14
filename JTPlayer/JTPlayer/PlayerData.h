//
//  PlayerModel.h
//  JTPlayer
//
//  Created by JT Ma on 04/12/2017.
//  Copyright © 2017 JT (ma.jiangtao.86@gmail.com). All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PlayerData : NSObject

@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSURLSessionDataTask *task;
@property (nonatomic, strong) NSURL *location;
@property (nonatomic, assign) BOOL isDownloading;

@property (nonatomic, assign) double progress;
@property (nonatomic, assign) double totalSize;
@property (nonatomic, assign) double speed;

- (instancetype)initWithURL:(NSString *)url;

@end
