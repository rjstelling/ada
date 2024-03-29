//
//  ADATypes.h
//  ada
//
//  Created by Richard Stelling on 23/12/2013.
//  Copyright (c) 2013 The Ada Analytics Cooperative. All rights reserved.
//

#ifdef RELEASE
# undef ADA_LOGGING
#else
# define ADA_LOGGING 1
#endif

typedef int ADAInt32;
typedef short ADAInt16;

#if __LP64__ || NS_BUILD_32_LIKE_64
typedef long ADAInt64;
#else
# warning Building as 32-bit.
typedef long long ADAInt64;
#endif

#ifdef DEBUG
# include <assert.h>
# include <stdbool.h>
# include <sys/types.h>
# include <unistd.h>
# include <sys/sysctl.h>

#pragma mark - Debug Info

static inline bool AmIBeingDebugged(void)
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