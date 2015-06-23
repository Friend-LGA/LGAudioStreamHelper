//
//  LGAudioStreamMetadataGetter.m
//  LGAudioStreamHelper
//
//
//  The MIT License (MIT)
//
//  Copyright (c) 2015 Grigory Lutkov <Friend.LGA@gmail.com>
//  (https://github.com/Friend-LGA/LGAudioStreamHelper)
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

#import "LGAudioStreamMetadataGetter.h"

@interface LGAudioStreamMetadataGetter () <NSURLConnectionDelegate>

typedef enum
{
    LGAudioStreamMetadataGetterResponceTypeHTTP = 1,
    LGAudioStreamMetadataGetterResponceTypeICY  = 2
}
LGAudioStreamMetadataGetterResponceType;

@property (strong, nonatomic) dispatch_queue_t                          selfQueue;
@property (strong, nonatomic) NSURLConnection                           *connection;
@property (strong, nonatomic) NSHTTPURLResponse                         *serverResponse;
@property (strong, nonatomic) NSMutableDictionary                       *metadataDictionary;
@property (strong, atomic)    NSMutableData                             *streamData;
@property (assign, nonatomic) LGAudioStreamMetadataGetterResponceType   responceType;

@property (strong, nonatomic) void (^completionHandler)(NSDictionary *metadataDictionary, NSHTTPURLResponse *serverResponse, NSError *error);

@end

@implementation LGAudioStreamMetadataGetter

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _selfQueue = dispatch_queue_create("com.LGAudioStreamHelper.LGAudioStreamMetadataGetterQueue", NULL);
    }
    return self;
}

- (void)getMetadataFromUrl:(NSURL *)streamUrl
         completionHandler:(void(^)(NSDictionary *metadataDictionary, NSHTTPURLResponse *serverResponse, NSError *error))completionHandler
{
    dispatch_async(_selfQueue, ^(void)
                   {
                       if (_connection)
                       {
                           dispatch_sync(dispatch_get_main_queue(), ^(void)
                                         {
                                             [_connection cancel];
                                             _connection = nil;
                                         });
                       }
                       
                       if (_responceType) _responceType = 0;
                       if (_streamData) _streamData = nil;
                       if (_metadataDictionary) _metadataDictionary = nil;
                       if (_serverResponse) _serverResponse = nil;
                       if (_completionHandler) _completionHandler = nil;
                       
                       _completionHandler = completionHandler;
                       
                       NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:streamUrl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
                       [request setHTTPMethod:@"GET"];
                       [request setValue:@"1" forHTTPHeaderField:@"Icy-MetaData"];
                       
                       dispatch_async(dispatch_get_main_queue(), ^(void)
                                      {
                                          _connection = [NSURLConnection connectionWithRequest:request delegate:self];
                                          [_connection start];
                                      });
                   });
}

- (void)returnWithMetadataDictionary:(NSDictionary *)metadataDictionary error:(NSError *)error
{
    if ([NSThread currentThread].isMainThread) [self returnEndWithMetadataDictionary:metadataDictionary error:error];
    else dispatch_sync(dispatch_get_main_queue(), ^(void)
                       {
                           [self returnEndWithMetadataDictionary:metadataDictionary error:error];
                       });
}

- (void)returnEndWithMetadataDictionary:(NSDictionary *)metadataDictionary error:(NSError *)error
{
    NSHTTPURLResponse *serverResponse = _serverResponse;
    
    if (_connection)
    {
        [_connection cancel];
        _connection = nil;
    }
    
    if (_responceType) _responceType = 0;
    if (_streamData) _streamData = nil;
    if (_metadataDictionary) _metadataDictionary = nil;
    if (_serverResponse) _serverResponse = nil;
    
    if (_completionHandler) _completionHandler(metadataDictionary, serverResponse, error);
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    _serverResponse = response;
    
    _streamData = [NSMutableData new];
    
    NSString *contentType = response.allHeaderFields[@"content-type"];
    
    if (contentType && contentType.length > 0)
    {
        _responceType = LGAudioStreamMetadataGetterResponceTypeHTTP;
        
        _metadataDictionary = [NSMutableDictionary dictionaryWithDictionary:response.allHeaderFields];
        [_metadataDictionary setObject:@"HTTP 200" forKey:@"StreamResponceType"];
        
        NSString *icyMetaint = response.allHeaderFields[@"icy-metaint"];
        
        if (!(icyMetaint && icyMetaint.intValue > 0)) [self returnWithMetadataDictionary:_metadataDictionary error:nil];
    }
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self returnWithMetadataDictionary:_metadataDictionary error:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    dispatch_async(_selfQueue, ^(void)
                   {
                       [_streamData appendData:data];
                       
                       int metaint = 0;
                       
                       if (_responceType == LGAudioStreamMetadataGetterResponceTypeHTTP)
                       {
                           metaint = [_metadataDictionary[@"icy-metaint"] intValue];
                           
                           if (metaint == 0) [self returnWithMetadataDictionary:_metadataDictionary error:nil];
                       }
                       else if (_streamData.length >= 200)
                       {
                           NSData *metaData = [_streamData subdataWithRange:NSMakeRange(0, 10)];
                           NSString *string = [NSString stringWithUTF8String:metaData.bytes];
                           
                           if ([string caseInsensitiveCompare:@"ICY 200 OK"] == NSOrderedSame)
                           {
                               _responceType = LGAudioStreamMetadataGetterResponceTypeICY;
                               
                               _metadataDictionary = [NSMutableDictionary new];
                               [_metadataDictionary setObject:@"ICY 200" forKey:@"StreamResponceType"];
                               
                               NSMutableString *header = [NSMutableString new];
                               
                               for (int i=0; i<_streamData.length-10; i++)
                               {
                                   NSData *metaData1 = [_streamData subdataWithRange:NSMakeRange(10+i, 1)];
                                   NSString *string1 = [NSString stringWithUTF8String:metaData1.bytes];
                                   
                                   if (string1) [header appendString:string1];
                                   
                                   if (header.length >= 4 && [[header substringFromIndex:header.length-4] isEqualToString:@"\r\n\r\n"]) break;
                               }
                               
                               [header replaceOccurrencesOfString:@"<BR>" withString:@"" options:0 range:NSMakeRange(0, header.length)];
                               [header replaceOccurrencesOfString:@"\r\n\r\n" withString:@"" options:0 range:NSMakeRange(0, header.length)];
                               
                               NSArray *array = [header componentsSeparatedByString:@"\r\n"];
                               
                               for (NSString *string in array)
                               {
                                   NSArray *array = [string componentsSeparatedByString:@":"];
                                   
                                   if (array.count > 1)
                                   {
                                       NSString *string1 = [array objectAtIndex:0];
                                       NSMutableString *string2 = [NSMutableString new];
                                       
                                       for (int i=1; i<array.count; i++)
                                       {
                                           if (i > 1) [string2 appendString:@":"];
                                           
                                           [string2 appendString:[array objectAtIndex:i]];
                                       }
                                       
                                       [_metadataDictionary setObject:string2 forKey:string1];
                                   }
                               }
                               
                               metaint = [_metadataDictionary[@"icy-metaint"] intValue];
                               
                               if (metaint == 0) [self returnWithMetadataDictionary:_metadataDictionary error:nil];
                           }
                           else [self returnWithMetadataDictionary:nil error:nil];
                       }
                       
                       if (_responceType > 0 && metaint > 0 && _streamData.length >= metaint+1)
                       {
                           NSData *metaData = [_streamData subdataWithRange:NSMakeRange(metaint, 1)];
                           NSMutableString *string = [NSMutableString stringWithFormat:@"%@", metaData];
                           [string replaceOccurrencesOfString:@"<" withString:@"" options:0 range:NSMakeRange(0, string.length)];
                           [string replaceOccurrencesOfString:@">" withString:@"" options:0 range:NSMakeRange(0, string.length)];
                           
                           if (string.intValue > 0)
                           {
                               if (_streamData.length >= metaint+1+string.intValue*16)
                               {
                                   NSData *metaData = [_streamData subdataWithRange:NSMakeRange(metaint+1, string.intValue*16)];
                                   NSMutableString *string = [NSMutableString stringWithUTF8String:metaData.bytes];
                                   
                                   NSArray *array = [string componentsSeparatedByString:@"'"];
                                   
                                   if (array.count > 1)
                                   {
                                       string = [array objectAtIndex:1];
                                       
                                       if (string.length > 5) [_metadataDictionary setObject:string forKey:@"StreamTitle"];
                                   }
                                   
                                   [self returnWithMetadataDictionary:_metadataDictionary error:nil];
                               }
                           }
                           else [self returnWithMetadataDictionary:_metadataDictionary error:nil];
                       }
                   });
}

@end
