//
//  YHReadBuffer.h
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import <Foundation/Foundation.h>
FOUNDATION_EXTERN int byteToInt2(Byte b[]);
@interface YHReadBuffer : NSObject
@property (nonatomic, assign) int64_t aimDataLength;
@property (nonatomic, readonly, assign) int64_t receivedDataLength;
@property (nonatomic, strong, readonly) NSData* bufferData;
- (void)appendBytes:(const void *)bytes length:(NSUInteger)length;
- (BOOL) isFull;
@end
