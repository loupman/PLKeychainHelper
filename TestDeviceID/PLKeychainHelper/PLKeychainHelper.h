//
//  PLKeychainHelper.h
//  TestDeviceID
//
//  Created by PhilipLee on 2017/5/3.
//  Copyright © 2017年 PhilipLee. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PLKeychainHelper : NSObject

#pragma mark keychain  基础数据操作
/* 保存数据到 keychain */
+ (void)saveData:(id)data forService:(NSString *)service;

/* 从 keychain 获取数据 */
+ (id)dataWithService:(NSString *)service;

/* 从 keychain 删除数据 */
+ (void)deleteWithService:(NSString *)service;


#pragma mark APP 使用
+ (NSString *)getUniqueDeviceId;
+ (void) deleteUniqueDeviceId;


@end
