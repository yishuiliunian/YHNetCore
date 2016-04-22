//
//  YHNetSocketConnection.m
//  Pods
//
//  Created by stonedong on 16/4/19.
//
//

#import "YHNetSocketConnection.h"
#import <libkern/OSAtomic.h>
#import <CoreFoundation/CoreFoundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <netdb.h>
#import "YHEndPoint.h"

@interface YHNetSocketConnection ()
- (void)doCFSocketCallback:(CFSocketCallBackType)type
                 forSocket:(CFSocketRef)sock
               withAddress:(NSData *)address
                  withData:(const void *)pData;
@end

static void MyCFSocketCallback (CFSocketRef sref, CFSocketCallBackType type, CFDataRef inAddress, const void *pData, void *pInfo)
{
    @autoreleasepool {
        
        YHNetSocketConnection *theSocket = (__bridge YHNetSocketConnection *)pInfo;
        NSData *address = [(__bridge NSData *)inAddress copy];
        [theSocket doCFSocketCallback:type forSocket:sref withAddress:address withData:pData];
    }
}



@implementation YHNetSocketConnection
{
    YHNetCommunicator* _communicator;
    BOOL _shouldClose;
    CFSocketContext _context;
    CFSocketRef _theSocket4;
    CFRunLoopRef _theRunLoop;
    CFRunLoopSourceRef _theSource4;
    NSArray* _theRunLoopModes;
    enum YHNetConnectionFlag _theFlags;
    CFSocketNativeHandle theNativeSocket4;
    CFReadStreamRef _theReadStream;
    CFWriteStreamRef _theWriteStream;
}


- (instancetype) initWithCommunicator:(YHNetCommunicator *)c
{
    self = [super init];
    if (!self) {
        return self;
    }
    _communicator = c;
    
    // Socket context
    NSAssert(sizeof(CFSocketContext) == sizeof(CFStreamClientContext), @"CFSocketContext != CFStreamClientContext");
    _context.version = 0;
    _context.info = (__bridge void *)(self);
    _context.retain = nil;
    _context.release = nil;
    _context.copyDescription = nil;
    
    _theRunLoopModes = [NSArray arrayWithObject:NSDefaultRunLoopMode];
    return self;
}


- (void)doCFSocketCallback:(CFSocketCallBackType)type
                 forSocket:(CFSocketRef)sock
               withAddress:(NSData *)address
                  withData:(const void *)pData
{
    #pragma unused(address)
   	NSParameterAssert ((sock == _theSocket4));
    switch (type) {
        case kCFSocketConnectCallBack:
            if(pData)
                [self doSocketOpen:sock withCFSocketError:kCFSocketError];
            else
                [self doSocketOpen:sock withCFSocketError:kCFSocketSuccess];
            break;
            
        default:
			NSLog(@"AsyncSocket %p received unexpected CFSocketCallBackType %i", self, (int)type);
            break;
    }
    
}


/**
 * This method is called as a result of connectToAddress:withTimeout:error:.
 * At this point we have an open CFSocket from which we need to create our read and write stream.
 **/
- (void)doSocketOpen:(CFSocketRef)sock withCFSocketError:(CFSocketError)socketError
{
    NSParameterAssert ((sock == _theSocket4));
    
    if(socketError == kCFSocketTimeout || socketError == kCFSocketError)
    {
        [self closeWithError:[self getSocketError]];
        return;
    }
    
    // Get the underlying native (BSD) socket
    CFSocketNativeHandle nativeSocket = CFSocketGetNative(sock);
    
    // Store a reference to it
    if (sock == _theSocket4)
        theNativeSocket4 = nativeSocket;
    
    // Setup the CFSocket so that invalidating it will not close the underlying native socket
    CFSocketSetSocketFlags(sock, 0);
    
    // Invalidate and release the CFSocket - All we need from here on out is the nativeSocket.
    // Note: If we don't invalidate the CFSocket (leaving the native socket open)
    // then theReadStream and theWriteStream won't function properly.
    // Specifically, their callbacks won't work, with the exception of kCFStreamEventOpenCompleted.
    //
    // This is likely due to the mixture of the CFSocketCreateWithNative method,
    // along with the CFStreamCreatePairWithSocket method.
    // The documentation for CFSocketCreateWithNative states:
    //
    //   If a CFSocket object already exists for sock,
    //   the function returns the pre-existing object instead of creating a new object;
    //   the context, callout, and callBackTypes parameters are ignored in this case.
    //
    // So the CFStreamCreateWithNative method invokes the CFSocketCreateWithNative method,
    // thinking that is creating a new underlying CFSocket for it's own purposes.
    // When it does this, it uses the context/callout/callbackTypes parameters to setup everything appropriately.
    // However, if a CFSocket already exists for the native socket,
    // then it is returned (as per the documentation), which in turn screws up the CFStreams.
    
    CFSocketInvalidate(sock);
    CFRelease(sock);
    _theSocket4 = NULL;
    
    NSError *err;
    BOOL pass = YES;
    
    if(pass && ![self createStreamsFromNative:nativeSocket error:&err]) pass = NO;
    if(pass && ![self attachStreamsToRunLoop:nil error:&err])           pass = NO;
    if(pass && ![self openStreamsAndReturnError:&err])                  pass = NO;
    
    if(!pass)
    {
        [self closeWithError:err];
    }
}



/**
 * Returns a standard error message for a CFSocket error.
 * Unfortunately, CFSocket offers no feedback on its errors.
 **/
- (NSError *)getSocketError
{
    NSString *errMsg = NSLocalizedStringWithDefaultValue(@"AsyncSocketCFSocketError",
                                                         @"AsyncSocket", [NSBundle mainBundle],
                                                         @"General CFSocket error", nil);
    
    NSDictionary *info = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
    
    return [NSError errorWithDomain:@"com.yaohe.net.error" code:-1109 userInfo:info];
}

/**
 * Adds the CFSocket's to the run-loop so that callbacks will work properly.
 **/
- (BOOL)attachSocketsToRunLoop:(NSRunLoop *)runLoop error:(NSError **)errPtr
{
#pragma unused(errPtr)
    
    // Get the CFRunLoop to which the socket should be attached.
    _theRunLoop = (runLoop == nil) ? CFRunLoopGetCurrent() : [runLoop getCFRunLoop];
    if(_theSocket4)
    {
        _theSource4 = CFSocketCreateRunLoopSource (kCFAllocatorDefault, _theSocket4, 0);
        [self runLoopAddSource:_theSource4];
    }
    
    return YES;
}
- (BOOL) openWithEndPoint:(YHEndPoint *)point error:(NSError* __autoreleasing*) error
{
    NSData* addr = [point addressIPV4:error];
    if (error != NULL &&  *error) {
        return NO;
    }
    struct sockaddr *pSockAddr = (struct sockaddr *)[addr bytes];
    int addressFamily = pSockAddr->sa_family;
    
    _theSocket4 = CFSocketCreate(kCFAllocatorDefault, addressFamily, SOCK_STREAM, IPPROTO_TCP, kCFSocketConnectCallBack, &MyCFSocketCallback, &_context);
    if (_theSocket4 == NULL) {
        if (error != NULL) {
            *error  = [self getSocketError];
        }
        return NO;
    }
    
    CFSocketConnectToAddress(_theSocket4, (CFDataRef)addr, -1);
    [self attachSocketsToRunLoop:nil error:nil];
    
    return YES;
}


- (void) close
{
    
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Disconnect Implementation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Sends error message and disconnects
- (void)closeWithError:(NSError *)err
{
    _theFlags |= kClosingWithError;
    
    if (_theFlags & kDidStartDelegate)
    {
//        // Try to salvage what data we can.
//        [self recoverUnreadData];
//        
//        // Let the delegate know, so it can try to recover if it likes.
//        if ([theDelegate respondsToSelector:@selector(onSocket:willDisconnectWithError:)])
//        {
//            [theDelegate onSocket:self willDisconnectWithError:err];
//        }
    }
    [self close];
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Run Loop
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void)runLoopAddSource:(CFRunLoopSourceRef)source
{
    for (NSString *runLoopMode in _theRunLoopModes)
    {
        CFRunLoopAddSource(_theRunLoop, source, (__bridge CFStringRef)runLoopMode);
    }
}

- (void)runLoopRemoveSource:(CFRunLoopSourceRef)source
{
    for (NSString *runLoopMode in _theRunLoopModes)
    {
        CFRunLoopRemoveSource(_theRunLoop, source, (__bridge CFStringRef)runLoopMode);
    }
}



- (BOOL)attachStreamsToRunLoop:(NSRunLoop *)runLoop error:(NSError **)errPtr
{
    // Get the CFRunLoop to which the socket should be attached.
    _theRunLoop = (runLoop == nil) ? CFRunLoopGetCurrent() : [runLoop getCFRunLoop];
    
    // Setup read stream callbacks
    
    CFOptionFlags readStreamEvents = kCFStreamEventHasBytesAvailable |
    kCFStreamEventErrorOccurred     |
    kCFStreamEventEndEncountered    |
    kCFStreamEventOpenCompleted;
    
    if (!CFReadStreamSetClient(_theReadStream,
                               readStreamEvents,
                               (CFReadStreamClientCallBack)&MyCFReadStreamCallback,
                               (CFStreamClientContext *)(&_context)))
    {
        NSError *err = [self getStreamError];
        
        NSLog (@"AsyncSocket %p couldn't attach read stream to run-loop,", self);
        NSLog (@"Error: %@", err);
        
        if (errPtr) *errPtr = err;
        return NO;
    }
    
    // Setup write stream callbacks
    
    CFOptionFlags writeStreamEvents = kCFStreamEventCanAcceptBytes |
    kCFStreamEventErrorOccurred  |
    kCFStreamEventEndEncountered |
    kCFStreamEventOpenCompleted;
    
    if (!CFWriteStreamSetClient (_theWriteStream,
                                 writeStreamEvents,
                                 (CFWriteStreamClientCallBack)&MyCFWriteStreamCallback,
                                 (CFStreamClientContext *)(&_context)))
    {
        NSError *err = [self getStreamError];
        
        NSLog (@"AsyncSocket %p couldn't attach write stream to run-loop,", self);
        NSLog (@"Error: %@", err);
        
        if (errPtr) *errPtr = err;
        return NO;
    }
    
    // Add read and write streams to run loop
    
    for (NSString *runLoopMode in _theRunLoopModes)
    {
        CFReadStreamScheduleWithRunLoop(_theReadStream, _theRunLoop, (__bridge CFStringRef)runLoopMode);
        CFWriteStreamScheduleWithRunLoop(_theWriteStream, _theRunLoop, (__bridge CFStringRef)runLoopMode);
    }
    
    return YES;
}
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Stream Implementation
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * Creates the CFReadStream and CFWriteStream from the given native socket.
 * The CFSocket may be extracted from either stream after the streams have been opened.
 *
 * Note: The given native socket must already be connected!
 **/
- (BOOL)createStreamsFromNative:(CFSocketNativeHandle)native error:(NSError **)errPtr
{
    // Create the socket & streams.
    CFStreamCreatePairWithSocket(kCFAllocatorDefault, native, &_theReadStream, &_theWriteStream);
    if (_theReadStream == NULL || _theWriteStream == NULL)
    {
        NSError *err = [self getSocketError];
        
        NSLog(@"AsyncSocket %p couldn't create streams from accepted socket: %@", self, err);
        
        if (errPtr) *errPtr = err;
        return NO;
    }
    
    // Ensure the CF & BSD socket is closed when the streams are closed.
    CFReadStreamSetProperty(_theReadStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    CFWriteStreamSetProperty(_theWriteStream, kCFStreamPropertyShouldCloseNativeSocket, kCFBooleanTrue);
    
    return YES;
}



- (void)doCFWriteStreamCallback:(CFStreamEventType)type forStream:(CFWriteStreamRef)stream
{
#pragma unused(stream)
    
    NSParameterAssert(_theWriteStream != NULL);
    
    CFStreamError err;
    switch (type)
    {
        case kCFStreamEventOpenCompleted:
            _theFlags |= kDidCompleteOpenForWrite;
//            [self doStreamOpen];
            break;
        case kCFStreamEventCanAcceptBytes:
            if(_theFlags & kStartingWriteTLS) {
//                [self onTLSHandshakeSuccessful];
            }
            else {
                _theFlags |= kSocketCanAcceptBytes;
//                [self doSendBytes];
            }
            break;
        case kCFStreamEventErrorOccurred:
        case kCFStreamEventEndEncountered:
            err = CFWriteStreamGetError (_theWriteStream);
            [self closeWithError: [self errorFromCFStreamError:err]];
            break;
        default:
            NSLog(@"AsyncSocket %p received unexpected CFWriteStream callback, CFStreamEventType %i", self, (int)type);
    }
}
- (NSError *)getStreamError
{
    CFStreamError err;
    if (_theReadStream != NULL)
    {
        err = CFReadStreamGetError (_theReadStream);
        if (err.error != 0) return [self errorFromCFStreamError: err];
    }
    
    if (_theWriteStream != NULL)
    {
        err = CFWriteStreamGetError (_theWriteStream);
        if (err.error != 0) return [self errorFromCFStreamError: err];
    }
    
    return nil;
}
- (BOOL)openStreamsAndReturnError:(NSError **)errPtr
{
    BOOL pass = YES;
    
    if(pass && !CFReadStreamOpen(_theReadStream))
    {
        NSLog (@"AsyncSocket %p couldn't open read stream,", self);
        pass = NO;
    }
    
    if(pass && !CFWriteStreamOpen(_theWriteStream))
    {
        NSLog (@"AsyncSocket %p couldn't open write stream,", self);
        pass = NO;
    }
    
    if(!pass)
    {
        if (errPtr) *errPtr = [self getStreamError];
    }
    
    return pass;
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

static void MyCFReadStreamCallback (CFReadStreamRef stream, CFStreamEventType type, void *pInfo)
{
    @autoreleasepool {
        
        YHNetSocketConnection *theSocket = (__bridge YHNetSocketConnection *)pInfo;
        [theSocket doCFReadStreamCallback:type forStream:stream];
        
    }
}

/**
 * This is the callback we setup for CFWriteStream.
 * This method does nothing but forward the call to it's Objective-C counterpart
 **/
static void MyCFWriteStreamCallback (CFWriteStreamRef stream, CFStreamEventType type, void *pInfo)
{
    @autoreleasepool {
        
        YHNetSocketConnection *theSocket = (__bridge YHNetSocketConnection *)pInfo;
        [theSocket doCFWriteStreamCallback:type forStream:stream];
        
    }
}

@end
