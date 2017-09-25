/**
 * @Author: Dana Buehre <creaturesurvive>
 * @Date:   18-09-2017 2:02:28
 * @Email:  dbuehre@me.com
 * @Filename: PTCProvider.m
 * @Last modified by:   creaturesurvive
 * @Last modified time: 24-09-2017 1:15:07
 * @Copyright: Copyright © 2014-2017 CreatureSurvive
 */


#include "PTCProvider.h"

@implementation PTCProvider

#pragma mark Initialization

+ (CSPreferencesProvider *)sharedProvider {
    static dispatch_once_t once;
    static CSPreferencesProvider *sharedProvider;
    dispatch_once(&once, ^{
        NSString *tweakId = @"com.creaturecoding.PullToClear";
        NSString *prefsNotification = [tweakId stringByAppendingString:@".prefschanged"];

        sharedProvider = [[CSPreferencesProvider alloc] initWithTweakID:tweakId defaults:nil postNotification:prefsNotification notificationCallback:nil];
    });
    return sharedProvider;
}

@end
