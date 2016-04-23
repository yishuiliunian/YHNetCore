//
//  YHReadBuffer.h
//  Pods
//
//  Created by stonedong on 16/4/23.
//
//

#import <Foundation/Foundation.h>

@interface YHReadBuffer : NSObject
@property (nonatomic, readonly,assign) int64_t dataLength;
@property (nonatomic, readonly, assign) int64_t reciveDataLength;
@property (nonatomic, strong, readonly) NSData* bufferData;
- (void)appendBytes:(const void *)bytes length:(NSUInteger)length;
- (BOOL) isFull;
@end
