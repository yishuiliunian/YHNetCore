//
//  YHEndPoint.m
//  Pods
//
//  Created by stonedong on 16/4/21.
//
//

#import "YHEndPoint.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <netdb.h>

@implementation YHEndPoint

- (instancetype) initWithHost:(NSString *)host port:(NSString *)port
{
    self = [super init];
    if (!self) {
        return self;
    }
    _host = host;
    _port = port;
    _lastOpenTime = 0;
    return self;
}


- (NSString*) description
{
    return [NSString stringWithFormat:@"EndPoint Host:%@ Port:%@", _host, _port];
}

- (void) onConnected
{
    _lastOpenTime = CFAbsoluteTimeGetCurrent();
}

- (NSData*) addressIPV4:(NSError* __autoreleasing*)error
{
    NSData *address4 = nil, *address6 = nil;
    struct addrinfo hints, *res, *res0;
    memset(&hints, 0, sizeof(hints));
    hints.ai_family   = PF_UNSPEC;
    hints.ai_socktype = SOCK_STREAM;
    hints.ai_protocol = IPPROTO_TCP;
    hints.ai_flags    = AI_PASSIVE;
    int errCode = getaddrinfo([_host UTF8String], [_port UTF8String], &hints, &res0);
    if (error != NULL) {
        NSString *errMsg = [NSString stringWithCString:gai_strerror(errCode) encoding:NSASCIIStringEncoding];
        NSDictionary *info = [NSDictionary dictionaryWithObject:errMsg forKey:NSLocalizedDescriptionKey];
        *error = [NSError errorWithDomain:@"kCFStreamErrorDomainNetDB" code:errCode userInfo:info];
    } else {
        for (res = res0; res; res = res->ai_next)
        {
            if (!address4 && (res->ai_family == AF_INET))
            {
                // Found IPv4 address
                // Wrap the native address structures for CFSocketSetAddress.
                address4 = [NSData dataWithBytes:res->ai_addr length:res->ai_addrlen];
            }
            else if (!address6 && (res->ai_family == AF_INET6))
            {
                // Found IPv6 address
                // Wrap the native address structures for CFSocketSetAddress.
                address6 = [NSData dataWithBytes:res->ai_addr length:res->ai_addrlen];
            }
        }
        freeaddrinfo(res0);
    }
    return address4;
}
@end
