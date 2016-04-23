//
//  YHReadBuffer.m
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import "YHReadBuffer.h"

static int8_t HEAD_LEN = 4;

static int byteToInt2(Byte b[]) {
    int mask=0xff;
    int temp=0;
    int n=0;
    for(int i=0;i<HEAD_LEN;i++){
        n<<=8;
        temp=b[i]&mask;
        n|=temp;
    }
    return n;
}
@implementation YHReadBuffer
{
    NSMutableData* _data;
}
- (instancetype) init
{
    self = [super init];
    if (!self) {
        return self;
    }
    _dataLength = 0;
    _data = [NSMutableData new];
    return self;
}

- (void)appendBytes:(const void *)bytes length:(NSUInteger)length
{
    if (_dataLength == 0 && self.reciveDataLength == 0) {
        uint32_t dataLength = 0;
        dataLength = byteToInt2(bytes) - HEAD_LEN;
        bytes += HEAD_LEN;
        length -= HEAD_LEN;
        _dataLength = dataLength;
    }
    if (length > 0 && length != NSNotFound) {
        [_data appendBytes:bytes length:length];
    }
}

- (int64_t) reciveDataLength
{
    return _data.length;
}


- (BOOL) isFull
{
    if (_dataLength !=0 && self.reciveDataLength != 0) {
        if (_dataLength == self.reciveDataLength) {
            return YES;
        }
    }
    return NO;
}

- (NSData*) bufferData
{
    return [_data copy];
}

@end
