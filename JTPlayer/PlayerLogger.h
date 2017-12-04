//
//  PlayerLogger.h
//  JTPlayer
//
//  Created by JT Ma on 04/12/2017.
//  Copyright © 2017 JT (ma.jiangtao.86@gmail.com). All rights reserved.
//

#ifndef PlayerLogger_h
#define PlayerLogger_h

#ifdef DEBUG
#define NSLog(...) NSLog(@"Player: %@", __VA_ARGS__)
#define NSLogMethod() NSLog(@"%s", __func__)
#else
#define NSLog(...)
#define NSLogMethod()
#endif

#endif /* PlayerLogger_h */
