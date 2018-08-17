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
#import "UncaughtExceptionHandler.h"
//#import "CocoaLumberjack/DDLog.h"

@import CocoaLumberjack;

static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

@interface ARDAppDelegate()  <XMPPStreamDelegate>

@end

@implementation ARDAppDelegate {
    UIWindow *_window;
    RTCFileLogger *logFileRTC;
    
}



#pragma mark - UIApplicationDelegate methods

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *logsDirectory = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    //NSString *logsDirectory = [baseDir stringByAppendingPathComponent:@"Logs"];
    
    DDLogFileManagerDefault *defaultLogFileManager = [[DDLogFileManagerDefault alloc] initWithLogsDirectory: logsDirectory];
    DDFileLogger *ddFileLogger = [[DDFileLogger alloc] initWithLogFileManager:defaultLogFileManager]; // File Logger
    
    ddFileLogger.rollingFrequency = 60 * 60 * 24 * 5; // 24 hour rolling
    [ddFileLogger setMaximumFileSize: (5 * 1024 * 1024)];
    ddFileLogger.logFileManager.maximumNumberOfLogFiles = 7;
    [DDLog addLogger:ddFileLogger];
    
//    NSSetUncaughtExceptionHandler(&HandleException);
    InstallUncaughtExceptionHandler();
    //================= LOG
    RTCSetMinDebugLogLevel(RTCLoggingSeverityVerbose);
    if (!logFileRTC) {
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *baseDir = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        
        logFileRTC = [[RTCFileLogger alloc] initWithDirPath:baseDir maxFileSize:(10*1024*1024) rotationType: RTCFileLoggerTypeApp];
    }
    logFileRTC.severity = RTCLoggingSeverityVerbose;
    [logFileRTC start];
    //=================
    // ====== BEGIN XMPP
    if (!self.xmppStream) {
        self.xmppStream = [[XMPPStream alloc] init];
    }
#if TARGET_IPHONE_SIMULATOR
    self.xmppStream.myJID = [XMPPJID jidWithString:@"user02@localhost/abc"];
#else
    self.xmppStream.myJID = [XMPPJID jidWithString:@"user01@localhost/abc"];
#endif
    self.xmppStream.hostName = @"125.235.13.148";
    self.xmppStream.hostPort = 5222;
    
    [self.xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    self.xmppPing = [[XMPPPing alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    self.xmppPing.respondsToQueries = NO;
    [self.xmppPing activate: self.xmppStream];
    
    self.xmppAutoPing = [[XMPPAutoPing alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    
    [self.xmppAutoPing setPingTimeout: 10];
    [self.xmppAutoPing setPingInterval:12];
    [self.xmppAutoPing activate:self.xmppStream];
    
    //    self.xmppAutoPing
    self.xmppReconnect = [[XMPPReconnect alloc] initWithDispatchQueue:dispatch_get_main_queue()];
    [self.xmppReconnect setReconnectDelay:5];
    [self.xmppReconnect setReconnectTimerInterval:5];
    [self.xmppReconnect setAutoReconnect:TRUE];
    [self.xmppReconnect activate:self.xmppStream];
    
    NSError *error;
    
    
    [self.xmppStream connectWithTimeout:50 error: &error];
    
    if (error) {
        RTCLogInfo(@"%@", error.description);
    }
    
    // ===== END XMPP
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
    
    
    DDLogVerbose(@"HELOOO ------------");
    
    //#endif
    
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    RTCShutdownInternalTracer();
    RTCCleanupSSL();
    [logFileRTC stop];
}

-(void)xmppStreamDidConnect:(XMPPStream *)sender {
    NSLog(@"2. DID CONNECT ");
    NSError *error;
    //[self.xmppStream authenticateWithPassword:@"22872172152888958234602" error:&error];
#if TARGET_IPHONE_SIMULATOR
    [self.xmppStream authenticateWithPassword:@"user02" error:&error];
#else
    [self.xmppStream authenticateWithPassword:@"user01" error:&error];
#endif
    if(error) {
        NSLog(@"3. %@", error.description);
    }
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message {
    NSLog(@" %@", [message prettyXMLString]);
}

- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender {
    NSLog(@"3. DID AUTHENTICATE");
}

- (void)xmppStream:(XMPPStream *)sender didSendIQ:(XMPPIQ *)iq {
    NSLog(@"4. IQ: %@", [iq elementID]);
}
//void HandleException(NSException *exception)
//{
//    DDLogVerbose(@"=== EXCEPTION === %@", [exception description]);
//}


- (void) doSendMessage: (XMPPMessage *) msg {
    NSString *UUID = [[NSUUID UUID] UUIDString];
    XMPPMessage *tmp = [[XMPPMessage alloc] initWithType:@"call" to: [XMPPJID jidWithString:@"user01@localhost"] elementID:UUID];
    
    [self.xmppStream sendElement:tmp];
}
@end
