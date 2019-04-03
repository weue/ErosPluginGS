//
//  ErosPluginAppDelegate.m
//  ErosPluginGS
//
//  Created by sharesin on 04/02/2019.
//  Copyright (c) 2019 sharesin. All rights reserved.
//

#import "ErosPluginAppDelegate.h"

#import <WeexSDK/WeexSDK.h>
#import "BluetoothModule.h"

@implementation ErosPluginAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    //    NSData *imgData = [NSData dataFromBase64String:strImg];
    //
    //    UIImage *image = [UIImage imageWithData: imgData];
    
    
        BluetoothModule *event = [[BluetoothModule alloc] init];
    //    //    [event isSupport:^(id result) {
    //    //
    //    //    }];
    //    //    [event isEnabled:^(id result) {
    //    //
    //    //    }];
    //
    //    //读取JSON文件
    //    NSDictionary *json = [AppDelegate readLocalFileWithName:@"data"];
    //    [event enableBluetooth:json callback:^(id result) {
    //
    //    }];
    
    //    [event searchDevices:^(id result) {
    //
    //        NSString * uuid = @"3492B897-D73B-690C-AC06-8DE7A5724FE7";
    //        [event bondDevice:uuid callback:^(id result) {
    //            if ([@"1" isEqualToString:result]) {
    //                [event enableBluetooth:json];
    //            }
    //
    //        }];
    //    }];
    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
