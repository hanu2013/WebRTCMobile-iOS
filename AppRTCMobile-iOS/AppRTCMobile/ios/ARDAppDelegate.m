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

@interface ARDAppDelegate()  <XMPPStreamDelegate>

@end

@implementation ARDAppDelegate {
    UIWindow *_window;
    RTCFileLogger *logFileRTC;
    
}



#pragma mark - UIApplicationDelegate methods

- (BOOL)application:(UIApplication *)application
didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
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
    
    self.xmppStream.myJID = [XMPPJID jidWithString:@"user01@localhost/abc"];
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
    
    
    RTCLogInfo(@"HELOOO ------------");
    
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
    [self.xmppStream authenticateWithPassword:@"user01" error:&error];
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

@end
