//
//  YHNetRespHandler.m
//  Pods
//
//  Created by stonedong on 16/4/19.
//
//

#import "YHNetRespHandler.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <netdb.h>

#if TARGET_OS_IPHONE
// Note: You may need to add the CFNetwork Framework to your project
#import <CFNetwork/CFNetwork.h>
#endif

#import "YHNetRunloop.h"

@interface YHNetRespHandler ()
{
    CFReadStreamRef _readStream;
}
@property (nonatomic, assign) CFReadStreamRef readStream;
@end


@implementation YHNetRespHandler

- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _active = NO;
    return self;
}

- (void) startWithReadStream:(CFReadStreamRef) readStream
{
    _readStream = readStream;
    [self attachToRunloop:nil];
    [self openStreamsAndReturnError:nil];
}

- (NSError *)errorFromCFStreamError:(CFStreamError)err
{
    if (err.domain == 0 && err.error == 0) return nil;
    
    // Can't use switch; these constants aren't int literals.
    NSString *domain = @"CFStreamError (unlisted domain)";
    NSString *message = nil;
    
    if(err.domain == kCFStreamErrorDomainPOSIX) {
        domain = NSPOSIXErrorDomain;
    }
    else if(err.domain == kCFStreamErrorDomainMacOSStatus) {
        domain = NSOSStatusErrorDomain;
    }
    else if(err.domain == kCFStreamErrorDomainMach) {
        domain = NSMachErrorDomain;
    }
    else if(err.domain == kCFStreamErrorDomainNetDB)
    {
        domain = @"kCFStreamErrorDomainNetDB";
        message = [NSString stringWithCString:gai_strerror(err.error) encoding:NSASCIIStringEncoding];
    }
    else if(err.domain == kCFStreamErrorDomainNetServices) {
        domain = @"kCFStreamErrorDomainNetServices";
    }
    else if(err.domain == kCFStreamErrorDomainSOCKS) {
        domain = @"kCFStreamErrorDomainSOCKS";
    }
    else if(err.domain == kCFStreamErrorDomainSystemConfiguration) {
        domain = @"kCFStreamErrorDomainSystemConfiguration";
    }
    else if(err.domain == kCFStreamErrorDomainSSL) {
        domain = @"kCFStreamErrorDomainSSL";
    }
    
    NSDictionary *info = nil;
    if(message != nil)
    {
        info = [NSDictionary dictionaryWithObject:message forKey:NSLocalizedDescriptionKey];
    }
    return [NSError errorWithDomain:domain code:err.error userInfo:info];
}

- (NSError *)getStreamError
{
    CFStreamError err;
    if (_readStream != NULL)
    {
        err = CFReadStreamGetError (_readStream);
        if (err.error != 0) return [self errorFromCFStreamError: err];
    }
    return nil;
}

- (BOOL) attachToRunloop:(NSError* __autoreleasing*)error
{
    CFOptionFlags readStreamEvents = kCFStreamEventHasBytesAvailable |
    kCFStreamEventErrorOccurred     |
    kCFStreamEventEndEncountered    |
    kCFStreamEventOpenCompleted;
    
    CFSocketContext context;
    context.info = (__bridge void *)(self);
    if (!CFReadStreamSetClient(_readStream,
                               readStreamEvents,
                               (CFReadStreamClientCallBack)&MyCFReadStreamCallback,
                               (CFStreamClientContext *)(&context)))
    {
        NSError *err = [self getStreamError];
        
        NSLog (@"AsyncSocket %p couldn't attach read stream to run-loop,", self);
        NSLog (@"Error: %@", err);
        if (error) {
            *error = err;
        }

        return NO;
    }
    
  
    // Add read and write streams to run loop
    
    CFRunLoopRef runloop = [[YHNetRunloop runloop] getCFRunLoop];
    for (NSString *runLoopMode in [YHNetRunloop runloopModes])
    {
        CFReadStreamScheduleWithRunLoop(_readStream, runloop, (__bridge CFStringRef)runLoopMode);
    }
    return YES;
}

- (BOOL)openStreamsAndReturnError:(NSError **)errPtr
{
    BOOL pass = YES;
    
    if(pass && !CFReadStreamOpen(_readStream))
    {
        NSLog (@"AsyncSocket %p couldn't open read stream,", self);
        pass = NO;
    }
    
    if(!pass)
    {
        if (errPtr) *errPtr = [self getStreamError];
    }
    
    return pass;
}

/**
 * This is the callback we setup for CFReadStream.
 * This method does nothing but forward the call to it's Objective-C counterpart
 **/
static void MyCFReadStreamCallback (CFReadStreamRef stream, CFStreamEventType type, void *pInfo)
{
    @autoreleasepool {
        
        YHNetRespHandler *theSocket = (__bridge YHNetRespHandler*)pInfo;
        [theSocket doCFReadStreamCallback:type forStream:stream];
        
    }
}

- (void)doStreamOpen
{
    {
        NSError *err = nil;
        
        // Get the socket
        if (![self setSocketFromStreamsAndReturnError: &err])
        {
            NSLog (@"AsyncSocket %p couldn't get socket from streams, %@. Disconnecting.", self, err);
            [self closeWithError:err];
            return;
        }
        
        // Stop the connection attempt timeout timer
        [self endConnectTimeout];
        
        if ([theDelegate respondsToSelector:@selector(onSocket:didConnectToHost:port:)])
        {
            [theDelegate onSocket:self didConnectToHost:[self connectedHost] port:[self connectedPort]];
        }
        
        // Immediately deal with any already-queued requests.
        [self maybeDequeueRead];
        [self maybeDequeueWrite];
    }
}

- (void)doCFReadStreamCallback:(CFStreamEventType)type forStream:(CFReadStreamRef)stream
{
#pragma unused(stream)
    
    NSParameterAssert(_readStream != NULL);
    
    CFStreamError err;
    switch (type)
    {
        case kCFStreamEventOpenCompleted:
            theFlags |= kDidCompleteOpenForRead;
            [self doStreamOpen];
            break;
        case kCFStreamEventHasBytesAvailable:
                theFlags |= kSocketHasBytesAvailable;
                [self doBytesAvailable];
            break;
        case kCFStreamEventErrorOccurred:
        case kCFStreamEventEndEncountered:
            err = CFReadStreamGetError (theReadStream);
            [self closeWithError: [self errorFromCFStreamError:err]];
            break;
        default:
            NSLog(@"AsyncSocket %p received unexpected CFReadStream callback, CFStreamEventType %i", self, (int)type);
    }
}
@end
