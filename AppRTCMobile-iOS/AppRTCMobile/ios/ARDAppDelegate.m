/*
 *  Copyright 2013 The WebRTC Project Authors. All rights reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#import "ARDAppDelegate.h"

#import "WebRTC/RTCFieldTrials.h"
#import "WebRTC/RTCLogging.h"
#import "WebRTC/RTCSSLAdapter.h"
#import "WebRTC/RTCTracing.h"
#import "WebRTC/RTCFileLogger.h"
#import "ARDMainViewController.h"

@implementation ARDAppDelegate {
  UIWindow *_window;
  RTCFileLogger *logFileRTC;
}

#pragma mark - UIApplicationDelegate methods

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
  //=================== LOG
    RTCSetMinDebugLogLevel(RTCLoggingSeverityVerbose);
    if (!logFileRTC) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *baseDir = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        
        logFileRTC = [[RTCFileLogger alloc] initWithDirPath:baseDir maxFileSize:(10*1024*1024) rotationType: RTCFileLoggerTypeApp];
    }
    logFileRTC.severity = RTCLoggingSeverityVerbose;
    [logFileRTC start];
  //======================
    
  NSDictionary *fieldTrials = @{
    kRTCFieldTrialH264HighProfileKey: kRTCFieldTrialEnabledValue,
  };
  RTCInitFieldTrialDictionary(fieldTrials);
  RTCInitializeSSL();
  RTCSetupInternalTracer();
    
  _window =  [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
  [_window makeKeyAndVisible];
  ARDMainViewController *viewController = [[ARDMainViewController alloc] init];

  UINavigationController *root = [[UINavigationController alloc] initWithRootViewController:viewController];
  root.navigationBar.translucent = NO;
  _window.rootViewController = root;

//#if defined(NDEBUG)
  // In debug builds the default level is LS_INFO and in non-debug builds it is
  // disabled. Continue to log to console in non-debug builds, but only
  // warnings and errors.
    
  
    RTCLogInfo(@"HELOOO ------------");
    
//#endif

  return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    RTCShutdownInternalTracer();
    RTCCleanupSSL();
    [logFileRTC stop];
}

@end