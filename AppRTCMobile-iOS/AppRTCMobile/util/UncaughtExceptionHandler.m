//
//  UncaughtExceptionHandler.m
//  AppRTCMobile-iOS
//
//  Created by Nguyen Kim Ngoc on 8/3/18.
//  Copyright © 2018 Bang Nguyen. All rights reserved.
//

#import "UncaughtExceptionHandler.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>

@import CocoaLumberjack;
static const DDLogLevel ddLogLevel = DDLogLevelVerbose;

NSString * const UncaughtExceptionHandlerSignalExceptionName = @"UncaughtExceptionHandlerSignalExceptionName";
NSString * const UncaughtExceptionHandlerSignalKey = @"UncaughtExceptionHandlerSignalKey";
NSString * const UncaughtExceptionHandlerAddressesKey = @"UncaughtExceptionHandlerAddressesKey";

const NSInteger UncaughtExceptionHandlerSkipAddressCount = 4;
const NSInteger UncaughtExceptionHandlerReportAddressCount = 5;

@implementation UncaughtExceptionHandler

+ (NSArray *)backtrace
{
    void* callstack[128];
    int frames = backtrace(callstack, 128);
    char **strs = backtrace_symbols(callstack, frames);
    
    int i;
    NSMutableArray *backtrace = [NSMutableArray arrayWithCapacity:frames];
    for (
         i = UncaughtExceptionHandlerSkipAddressCount;
         i < UncaughtExceptionHandlerSkipAddressCount +
         UncaughtExceptionHandlerReportAddressCount;
         i++)
    {
        [backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
    }
    free(strs);
    
    return backtrace;
}

- (void)validateAndSaveCriticalApplicationData
{
    
}

- (void)handleException:(NSException *)exception
{
    [self validateAndSaveCriticalApplicationData];
    
    
    DDLogVerbose(@"Debug details follow:\n%@\n%@", [exception reason], [[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey]);
    
    //    UIAlertView *alert =
    //        [[[UIAlertView alloc]
    //            initWithTitle:NSLocalizedString(@"Unhandled exception", nil)
    //            message:[NSString stringWithFormat:NSLocalizedString(
    //                @"You can try to continue but the application may be unstable.\n\n"
    //                @"Debug details follow:\n%@\n%@", nil),
    //                [exception reason],
    //                [[exception userInfo] objectForKey:UncaughtExceptionHandlerAddressesKey]]
    //            delegate:self
    //            cancelButtonTitle:NSLocalizedString(@"Quit", nil)
    //            otherButtonTitles:NSLocalizedString(@"Continue", nil), nil]
    //        autorelease];
    //    [alert show];
    
    //    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    //    CFArrayRef allModes = CFRunLoopCopyAllModes(runLoop);
    
    //    while (!dismissed)
    //    {
    //        for (NSString *mode in (NSArray *)allModes)
    //        {
    //            CFRunLoopRunInMode((CFStringRef)mode, 0.001, false);
    //        }
    //    }
    //
    //    CFRelease(allModes);
    //
    //    NSSetUncaughtExceptionHandler(NULL);
    //    signal(SIGABRT, SIG_DFL);
    //    signal(SIGILL, SIG_DFL);
    //    signal(SIGSEGV, SIG_DFL);
    //    signal(SIGFPE, SIG_DFL);
    //    signal(SIGBUS, SIG_DFL);
    //    signal(SIGPIPE, SIG_DFL);
    //
    //    if ([[exception name] isEqual:UncaughtExceptionHandlerSignalExceptionName])
    //    {
    //        kill(getpid(), [[[exception userInfo] objectForKey:UncaughtExceptionHandlerSignalKey] intValue]);
    //    }
    //    else
    //    {
    //        [exception raise];
    //    }
}


@end

void HandleException(NSException *exception)
{
    
    //    int32_t exceptionCount = OSAtomicIncrement32(&UncaughtExceptionCount);
    //    if (exceptionCount > UncaughtExceptionMaximum)
    //    {
    //        return;
    //    }
    
    NSArray *callStack = [UncaughtExceptionHandler backtrace];
    NSMutableDictionary *userInfo =
    [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
    [userInfo setObject:callStack forKey:UncaughtExceptionHandlerAddressesKey];
    
    [[[UncaughtExceptionHandler alloc] init] performSelectorOnMainThread:@selector(handleException:)  withObject: [NSException exceptionWithName:[exception name] reason:[exception reason] userInfo:userInfo] waitUntilDone:YES];
}


void InstallUncaughtExceptionHandler()
{
    NSSetUncaughtExceptionHandler(&HandleException);
    
}


