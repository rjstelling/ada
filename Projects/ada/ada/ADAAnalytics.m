//
//  ADAAnalytics.m
//  ADA Analytics
//
//  Created by Richard Stelling on 11/11/2013.
//  Copyright (c) 2013 The Ada Analytics Cooperative. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import "ADAAnalytics.h"

#ifdef DEBUG
# include <assert.h>
# include <stdbool.h>
# include <sys/types.h>
# include <unistd.h>
# include <sys/sysctl.h>

#pragma mark - Debug Info

static bool AmIBeingDebugged(void)
// Returns true if the current process is being debugged (either
// running under the debugger or has a debugger attached post facto).
{
    int                 junk;
    int                 mib[4];
    struct kinfo_proc   info;
    size_t              size;
    
    // Initialize the flags so that, if sysctl fails for some bizarre
    // reason, we get a predictable result.
    
    info.kp_proc.p_flag = 0;
    
    // Initialize mib, which tells sysctl the info we want, in this case
    // we're looking for information about a specific process ID.
    
    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_PID;
    mib[3] = getpid();
    
    // Call sysctl.
    
    size = sizeof(info);
    junk = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
    assert(junk == 0);
    
    // We're being debugged if the P_TRACED flag is set.
    
    return ( (info.kp_proc.p_flag & P_TRACED) != 0 );
}
#endif //DEBUG

@implementation ADAAnalytics
{
    BOOL _isDebuggerAttached;
}

#pragma mark - Life Cycle

// This is called when the library is loaded into th eObjective-C runtime.
// We use this to create a singleton of the ADAAnalytics object.
+ (void)load
{
#ifdef ADA_LOGGING
    NSLog(@"[ADA ANALYTICS] Loading ADA into Objective-C runtime");
#endif
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        [ADAAnalytics sharedAnalyticsManager];
        
#ifdef ADA_LOGGING
        NSLog(@"[ADA ANALYTICS] Singleton created on background thread");
#endif
    });
}

+ (ADAAnalytics *)sharedAnalyticsManager
{
    static dispatch_once_t onceToken;
    static ADAAnalytics *manager_ = nil;
    
    dispatch_once(&onceToken, ^{
        manager_ = [[ADAAnalytics alloc] init];
    });
    
    return manager_;
}

- (instancetype)init
{
    self = [super init];
    
    if(self)
    {
#ifdef DEBUG
        if(AmIBeingDebugged())
        {
            NSLog(@"[ADA ANALYTICS] Running with a debugger attached, no data will be sent to the servers.");
            _isDebuggerAttached = YES;
        }
#endif
        
#ifdef ADA_LOGGING
        NSLog(@"[ADA ANALYTICS] -init called while creating ADAAnalytics object");
#endif
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onApplicationDidBecomeActiveNotification:)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }
    
    return self;
}

#pragma mark - Notifications

- (void)onApplicationDidBecomeActiveNotification:(NSNotification *)notification
{
    const u_int32_t upperBounds = 5; //a higher number will result in less frequent sampling
    u_int32_t random = arc4random_uniform(upperBounds);
    
    if(random == (upperBounds - 1) || _isDebuggerAttached)
    {
        //Only collect data here, this has a 1/upperBounds
        //chnace of being triggered.
        
        NSLog(@"[ADA ANALYTICS] \n%@\n%@\n%@\n%@\n%@",
        [UIDevice currentDevice].model,
        [UIDevice currentDevice].localizedModel,
        [UIDevice currentDevice].systemName,
        [UIDevice currentDevice].systemVersion,
        [[UIDevice currentDevice].identifierForVendor UUIDString]);
    }
}

- (void)collectDeviceFeatures
{
    /* OpenGLES
     EAGLGetVersion(unsigned int* major, unsigned int* minor);
     */
    
    /* CoreTelephony
     CTCarrier *subscriberCellularProvider
     + (CTSubscriber*) subscriber;
     */
    
    /* CoreMotion
     + (NSUInteger)availableAttitudeReferenceFrames NS_AVAILABLE(NA,5_0);
     BOOL accelerometerAvailable;
     BOOL gyroAvailable;
     BOOL magnetometerAvailable
     BOOL deviceMotionAvailable;
     + (BOOL)isStepCountingAvailable;
     */
    
    /* CoreLocation
     + (BOOL)locationServicesEnabled
     + (BOOL)headingAvailable
     + (BOOL)significantLocationChangeMonitoringAvailable
     + (BOOL)isMonitoringAvailableForClass:(Class)regionClass
     + (BOOL)regionMonitoringEnabled
     + (BOOL)isRangingAvailable
     + (CLAuthorizationStatus)authorizationStatus
     + (BOOL)deferredLocationUpdatesAvailable
     */
    
    /* AVFoundation
     + (NSArray *)devices;
     + (NSArray *)devicesWithMediaType:(NSString *)mediaType;
     
     AVCaptureDevice
     AVCaptureDevicePosition position;
     BOOL hasFlash;
     - (BOOL)isFlashModeSupported:(AVCaptureFlashMode)flashMode;
     BOOL hasTorch;
     - (BOOL)isFocusModeSupported:(AVCaptureFocusMode)focusMode;
     BOOL focusPointOfInterestSupported;
     BOOL autoFocusRangeRestrictionSupported
     BOOL smoothAutoFocusSupported
     - (BOOL)isExposureModeSupported:(AVCaptureExposureMode)exposureMode;
     BOOL exposurePointOfInterestSupported
     - (BOOL)isWhiteBalanceModeSupported:(AVCaptureWhiteBalanceMode)whiteBalanceMode
     BOOL lowLightBoostSupported
     CGFloat videoZoomFactor
     */
}

@end
