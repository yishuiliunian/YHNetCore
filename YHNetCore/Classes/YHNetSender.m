//
//  YHNetSender.m
//  Pods
//
//  Created by stonedong on 16/4/19.
//
//

#import "YHNetSender.h"

@interface YHNetSender ()

@end


@implementation YHNetSender


- (void)doCFReadStreamCallback:(CFStreamEventType)type forStream:(CFReadStreamRef)stream
{
#pragma unused(stream)
    
    NSParameterAssert(_theReadStream != NULL);
    
    CFStreamError err;
    switch (type)
    {
        case kCFStreamEventOpenCompleted:
            _theFlags |= kDidCompleteOpenForRead;
            //            [self doStreamOpen];
            break;
        case kCFStreamEventHasBytesAvailable:
            if(_theFlags & kStartingReadTLS) {
                //                [self onTLSHandshakeSuccessful];
            }
            else {
                _theFlags |= kSocketHasBytesAvailable;
                //                [self doBytesAvailable];
            }
            break;
        case kCFStreamEventErrorOccurred:
        case kCFStreamEventEndEncountered:
            err = CFReadStreamGetError (_theReadStream);
            //            [self closeWithError: [self errorFromCFStreamError:err]];
            break;
        default:
            NSLog(@"AsyncSocket %p received unexpected CFReadStream callback, CFStreamEventType %i", self, (int)type);
    }
}
@end
