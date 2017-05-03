//
//  PLKeychainHelper.m
//  TestDeviceID
//
//  Created by PhilipLee on 2017/5/3.
//  Copyright © 2017年 PhilipLee. All rights reserved.
//

#import "PLKeychainHelper.h"
#import <AdSupport/AdSupport.h>
#import "NSString+PLAdd.h"
#import <UIKit/UIKit.h>

#ifdef DEBUG
#define PLLog(...)  printf("\n--------------------------\n%s Line:%d]\n[\n%s\n]\n\n", __FUNCTION__,__LINE__,[[NSString stringWithFormat:__VA_ARGS__] UTF8String])
#else
#define PLLog(...)
#endif

@implementation PLKeychainHelper


+ (NSMutableDictionary *)getKeychainQueryWithService:(NSString *)service publicGroup:(BOOL)publicGroup
{

    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:3];
    [dictionary setObject:(__bridge id)kSecClassGenericPassword forKey:(__bridge id)kSecClass];
    
    [dictionary setObject:service forKey:(__bridge id)kSecAttrService];
    [dictionary setObject:[service pl_md5] forKey:(__bridge id)kSecAttrAccount];
    
    if (publicGroup) {
        [dictionary setObject:(__bridge NSString * _Nullable)(kSecAttrAccessGroupToken) forKey:(__bridge id)kSecAttrAccessGroup];
    } else {
        [dictionary setObject:(__bridge NSString * _Nullable)(kSecAttrAccessibleAfterFirstUnlock) forKey:(__bridge id)kSecAttrAccessible];
    }
    return dictionary;
}

+ (void)saveData:(id)data forService:(NSString *)service
{
    NSMutableDictionary *dictionary = [self getKeychainQueryWithService:service publicGroup:NO];
    SecItemDelete((__bridge CFDictionaryRef)(dictionary));
    
    [dictionary setObject:[NSKeyedArchiver archivedDataWithRootObject:data]
                      forKey:(__bridge id<NSCopying>)(kSecValueData)];
    
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)(dictionary), &result);
    if (status != errSecSuccess) {
        PLLog(@"---------------------------------- Failed to save to APP keychain");
    } else {
        PLLog(@"---------------------------------- Success to save to APP keychain");
    }
    
}

+ (id)dataWithService:(NSString *)service
{
    id ret = nil;
    NSMutableDictionary *dictionary = [self getKeychainQueryWithService:service publicGroup:NO];
    [dictionary setObject:(id)kCFBooleanTrue forKey:(__bridge id<NSCopying>)(kSecReturnData)];
    [dictionary setObject:(__bridge id)(kSecMatchLimitOne) forKey:(__bridge id<NSCopying>)(kSecMatchLimit)];
    
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)dictionary, &result);
    if (status != errSecSuccess) {
        PLLog(@"---------------------------------- Error fetching from APP keychain");
    } else {
        PLLog(@"---------------------------------- Success fetching from APP keychain");
        @try {
            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData*)result];
        } @catch (NSException *exception) {
            PLLog(@"---------------------------------- fail to unarchive %@: %@", service, exception);
        }
    }
    if (result) CFRelease(result);
    
    return ret;
}

+ (void)deleteWithService:(NSString *)service
{
    NSMutableDictionary *keychainQuery = [self getKeychainQueryWithService:service publicGroup:NO];
    SecItemDelete((__bridge CFDictionaryRef)(keychainQuery));
}

#pragma mark 公共token kSecAttrAccessGroupToken
+ (void)savePublicGroupData:(id )data forKey:(NSString *)key __OSX_AVAILABLE_STARTING(__MAC_10_12, __IPHONE_10_0)
{
    NSData *dd = [NSKeyedArchiver archivedDataWithRootObject:data];

    NSMutableDictionary *dictionary = [self getKeychainQueryWithService:key publicGroup:YES];
    SecItemDelete((__bridge CFDictionaryRef)(dictionary));
    
    [dictionary setObject:dd forKey:(__bridge id)kSecValueData];
    
    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)dictionary, NULL);
    if (status != errSecSuccess) {
        PLLog(@"---------------------------------- Failed to save to public Group keychain");
    } else {
        PLLog(@"---------------------------------- Success to save to public Group keychain");
    }
}

+ (id)getPublicGroupDataForKey:(NSString *)key __OSX_AVAILABLE_STARTING(__MAC_10_12, __IPHONE_10_0)
{
    /* Try to fetch from the keychain */
    NSMutableDictionary *dictionary = [self getKeychainQueryWithService:key publicGroup:YES];
    
    [dictionary setObject:@YES forKey:(__bridge id)kSecReturnData];
    [dictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    id ret = nil;
    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)dictionary, &result);
    if (status != errSecSuccess) {
        PLLog(@"--------------------------------- Error fetching from keychain");
    } else {
        PLLog(@"--------------------------------- Success fetching from keychain");
        @try {
            ret = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData*)result];
        } @catch (NSException *exception) {
            PLLog(@"fail to unarchive %@: %@", key, exception);
        }
    }
    
    return ret;
}

+ (void)deletePublicGroupForKey:(NSString *)key
{
    NSMutableDictionary *dictionary = [self getKeychainQueryWithService:key publicGroup:YES];
    
    [dictionary setObject:@YES forKey:(__bridge id)kSecReturnData];
    [dictionary setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
    
    SecItemDelete((__bridge CFDictionaryRef)(dictionary));
}

#pragma mark APP 使用
+ (NSString *)getUniqueDeviceId
{
    static NSString *deviceID;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *tmp = [self retrieveUniqueDeviceId];
        
        PLLog(@"------------------------------------ retrieveUniqueDeviceId deviceID \n%@\n", tmp);
        
        if (tmp.length == 0) {
            tmp = [self generateUniqueDeviceId];
            
            PLLog(@"-------------------------------- generateUniqueDeviceId deviceID \n%@\n", tmp);
            
        }
        if (tmp) {
            
            PLLog(@"-------------------------------- saveUniqueDeviceId deviceID \n%@\n", tmp);
            
            [self saveUniqueDeviceId:tmp];
        }
        deviceID = tmp;
    });
    
    return deviceID;
}

+(NSString *)retrieveUniqueDeviceId
{
    NSString *deviceID = [self dataWithService:[self uniqueKey]];
    
    if (deviceID && deviceID.length > 0) {
        PLLog(@"------------------------------------- version<10.0 GET deviceID \n%@\n", deviceID);
        return deviceID;
    }
    if ([self systemVersion] >= 10.0) {
        deviceID = [self getPublicGroupDataForKey:[self uniqueKey]];
        if (deviceID && deviceID.length > 0) {
            PLLog(@"--------------------------------- version>=10.0 GET deviceID \n%@\n", deviceID);
            return deviceID;
        }
    }
    return deviceID;
}

+(NSString *)generateUniqueDeviceId
{
    NSString *deviceID = nil;
    // generate and save token to keychain
    if ([ASIdentifierManager sharedManager].advertisingTrackingEnabled) {
        deviceID = [[[ASIdentifierManager sharedManager] advertisingIdentifier] UUIDString];
        
        if (deviceID && deviceID.length > 0) {
            deviceID = [deviceID pl_md5];
            PLLog(@"------------------------------------------- \
                  advertisingIdentifier \n%@\n", deviceID);
            return deviceID;
        }
    } else {
        deviceID = [NSString uuid];
        
        if (deviceID && deviceID.length > 0) {
            deviceID = [deviceID pl_md5];
            PLLog(@"------------------------------------------- uuid\n\
                  %@\n", deviceID);
            return deviceID;
        }
    }
    
    return deviceID;
}

+ (void) saveUniqueDeviceId:(NSString *)uid
{
    [self saveData:uid forService:[self uniqueKey]];
    if ([self systemVersion] >= 10.0) {
        [self savePublicGroupData:uid forKey:[self uniqueKey]];
    }
}

+ (void) deleteUniqueDeviceId
{
    [self deleteWithService:[self uniqueKey]];
}

+ (NSString *)uniqueKey
{
    return [@"pl.key.unique_device_id" pl_md5];
}

+(float)systemVersion
{
    return [[[UIDevice currentDevice] systemVersion] floatValue];
}

@end
