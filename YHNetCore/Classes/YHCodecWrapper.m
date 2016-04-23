//
//  YHCodecWrapper.m
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import "YHCodecWrapper.h"
#import "RpcMessage.pbobjc.h"
#import "YHSendMessage.h"
#import "YHCmd.h"
#import "YHFromMessage.h"
@implementation YHCodecWrapper

+ (NSData*) encode:(YHSendMessage*)message
{
    if (!message) {
        return nil;
    }
    RpcMessage* msg = [[RpcMessage alloc] init];
    msg.sequenceId = message.seq;
    msg.servant = message.cmd.servant;
    msg.method = message.cmd.method;
    msg.oneway_p = message.doOneWay;
    if (message.headers.count) {
        NSMutableDictionary* map = msg.context;
        [map setValuesForKeysWithDictionary:message.headers];
    }
    msg.buffer = message.dataBuffer;
    
    
    NSData* data = [msg data];
    
    int magicLength = 4;
    int n = magicLength + data.length;
    
    Byte magic[4];
    magic[3] = (n & 0xff);
    magic[2] = (n >> 8 & 0xff);
    magic[1] = (n >> 16 & 0xff);
    magic[0] = (n >> 24 & 0xff);
    
    NSMutableData* appendData  = [NSMutableData dataWithBytes:magic length:4];
    [appendData appendData:data];
    return appendData;
}

+ (YHFromMessage*) decode:(NSData*)data
{
    if (data.length < 1 ) {
        return nil;
    }
    NSError* error;
    RpcMessage* msg = [RpcMessage parseFromData:data error:&error];
    YHFromMessage* fromMsg = [[YHFromMessage alloc] initWithSEQ:msg.sequenceId cmd:[YHCmd cmdWithServant:msg.servant method:msg.method]];
    fromMsg.data = msg.buffer;
    fromMsg.doOneWay = msg.oneway_p;
    fromMsg.headers = msg.context;
    return fromMsg;
}


@end
