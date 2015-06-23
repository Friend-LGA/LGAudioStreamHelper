//
//  LGAudioStreamContentTypeGetter.m
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

#import "LGAudioStreamContentTypeGetter.h"

@interface LGAudioStreamContentTypeGetter () <NSURLConnectionDelegate>

@property (strong, nonatomic) dispatch_queue_t  selfQueue;
@property (strong, nonatomic) NSURLConnection   *connection;
@property (strong, nonatomic) NSHTTPURLResponse *serverResponse;
@property (strong, atomic)    NSMutableData     *streamData;

@property (strong, nonatomic) void (^completionHandler)(NSString *contentType, NSString *fileExtension, AudioFileTypeID audioFileTypeID, NSHTTPURLResponse *serverResponse, NSError *error);

@end

@implementation LGAudioStreamContentTypeGetter

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _selfQueue = dispatch_queue_create("com.LGAudioStreamHelper.LGAudioStreamContentTypeGetterQueue", NULL);
    }
    return self;
}

- (void)getContentTypeFromUrl:(NSURL *)streamUrl
            completionHandler:(void(^)(NSString *contentType, NSString *fileExtension, AudioFileTypeID audioFileTypeID, NSHTTPURLResponse *serverResponse, NSError *error))completionHandler
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
                       
                       if (_streamData) _streamData = nil;
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

- (void)returnWithContentType:(NSString *)contentType error:(NSError *)error
{
    if ([NSThread currentThread].isMainThread) [self returnEndWithContentType:contentType error:error];
    else dispatch_sync(dispatch_get_main_queue(), ^(void)
                       {
                           [self returnEndWithContentType:contentType error:error];
                       });
}

- (void)returnEndWithContentType:(NSString *)contentType error:(NSError *)error
{
    NSHTTPURLResponse *serverResponse = _serverResponse;
    
    if (_connection)
    {
        [_connection cancel];
        _connection = nil;
    }
    
    if (_streamData) _streamData = nil;
    if (_serverResponse) _serverResponse = nil;
    
    NSString *fileExtension;
    AudioFileTypeID audioFileTypeID = 0;
    
    if (contentType)
    {
        if ([contentType isEqualToString:@"audio/mp3"])                     {   fileExtension = @"mp3";     audioFileTypeID = kAudioFileMP3Type;        }
        else if ([contentType isEqualToString:@"audio/mpg"])                {   fileExtension = @"mp3";     audioFileTypeID = kAudioFileMP3Type;        }
        else if ([contentType isEqualToString:@"audio/mpeg"])               {   fileExtension = @"mp3";     audioFileTypeID = kAudioFileMP3Type;        }
        else if ([contentType isEqualToString:@"audio/aacp"])               {   fileExtension = @"aac";     audioFileTypeID = kAudioFileAAC_ADTSType;   }
        else if ([contentType isEqualToString:@"audio/aac"])                {   fileExtension = @"aac";     audioFileTypeID = kAudioFileAAC_ADTSType;   }
        else if ([contentType isEqualToString:@"audio/ac3"])                {   fileExtension = @"ac3";     audioFileTypeID = kAudioFileAC3Type;        }
        else if ([contentType isEqualToString:@"audio/wav"])                {   fileExtension = @"wav";     audioFileTypeID = kAudioFileWAVEType;       }
        else if ([contentType isEqualToString:@"audio/x-wav"])              {   fileExtension = @"wav";     audioFileTypeID = kAudioFileWAVEType;       }
        else if ([contentType isEqualToString:@"audio/aifc"])               {   fileExtension = @"aifc";    audioFileTypeID = kAudioFileAIFCType;       }
        else if ([contentType isEqualToString:@"audio/x-aifc"])             {   fileExtension = @"aifc";    audioFileTypeID = kAudioFileAIFCType;       }
        else if ([contentType isEqualToString:@"audio/aiff"])               {   fileExtension = @"aiff";    audioFileTypeID = kAudioFileAIFFType;       }
        else if ([contentType isEqualToString:@"audio/x-aiff"])             {   fileExtension = @"aiff";    audioFileTypeID = kAudioFileAIFFType;       }
        else if ([contentType isEqualToString:@"audio/x-m4a"])              {   fileExtension = @"m4a";     audioFileTypeID = kAudioFileM4AType;        }
        else if ([contentType isEqualToString:@"audio/m4a"])                {   fileExtension = @"m4a";     audioFileTypeID = kAudioFileM4AType;        }
        else if ([contentType isEqualToString:@"audio/x-mp4"])              {   fileExtension = @"mp4";     audioFileTypeID = kAudioFileMPEG4Type;      }
        else if ([contentType isEqualToString:@"audio/mp4"])                {   fileExtension = @"mp4";     audioFileTypeID = kAudioFileMPEG4Type;      }
        else if ([contentType isEqualToString:@"audio/caf"])                {   fileExtension = @"caf";     audioFileTypeID = kAudioFileCAFType;        }
        else if ([contentType isEqualToString:@"audio/x-caf"])              {   fileExtension = @"caf";     audioFileTypeID = kAudioFileCAFType;        }
        else if ([contentType isEqualToString:@"audio/3gp"])                {   fileExtension = @"3gp";     audioFileTypeID = kAudioFile3GPType;        }
        else if ([contentType isEqualToString:@"audio/3gpp"])               {   fileExtension = @"3gp";     audioFileTypeID = kAudioFile3GPType;        }
        else if ([contentType isEqualToString:@"audio/3gpp2"])              {   fileExtension = @"3gp";     audioFileTypeID = kAudioFile3GP2Type;       }
        else if ([contentType isEqualToString:@"audio/ogg"])                {   fileExtension = @"ogg";     audioFileTypeID = 0;                        }
        else if ([contentType isEqualToString:@"application/ogg"])          {   fileExtension = @"ogg";     audioFileTypeID = 0;                        }
        else if ([contentType isEqualToString:@"application/octet-stream"]) {   fileExtension = @"mp3";     audioFileTypeID = kAudioFileMP3Type;        }
        else                                                                {   fileExtension = nil;        audioFileTypeID = 0;                        }
    }
    
    if (_completionHandler) _completionHandler(contentType, fileExtension, audioFileTypeID, serverResponse, error);
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    _serverResponse = response;
    
    NSString *contentType = response.allHeaderFields[@"content-type"];
    
    if (contentType && contentType.length > 0) [self returnWithContentType:contentType error:nil];
    else _streamData = [NSMutableData new];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self returnWithContentType:nil error:error];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    dispatch_async(_selfQueue, ^(void)
                   {
                       [_streamData appendData:data];
                       
                       if (_streamData.length >= 200)
                       {
                           NSData *metaData = [_streamData subdataWithRange:NSMakeRange(0, 10)];
                           NSString *string = [NSString stringWithUTF8String:metaData.bytes];
                           
                           if ([string caseInsensitiveCompare:@"ICY 200 OK"] == NSOrderedSame)
                           {
                               NSMutableString *header = [NSMutableString new];
                               
                               for (int i=0; i<_streamData.length-10; i++)
                               {
                                   NSData *metaData1 = [_streamData subdataWithRange:NSMakeRange(10+i, 1)];
                                   NSString *string1 = [NSString stringWithUTF8String:metaData1.bytes];
                                   
                                   if (string1) [header appendString:string1];
                                   
                                   if (header.length >= 4 && [[header substringFromIndex:header.length-4] isEqualToString:@"\r\n\r\n"]) break;
                               }
                               
                               [header replaceOccurrencesOfString:@"\r\n\r\n" withString:@"" options:0 range:NSMakeRange(0, header.length)];
                               
                               NSArray *array = [header componentsSeparatedByString:@"\r\n"];
                               
                               NSMutableDictionary *metadataDictionary = [NSMutableDictionary new];
                               
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
                                       
                                       [metadataDictionary setObject:string2 forKey:string1];
                                   }
                               }
                               
                               NSString *contentType = metadataDictionary[@"content-type"];
                               
                               [self returnWithContentType:contentType error:nil];
                           }
                           else [self returnWithContentType:nil error:nil];
                       }
                   });
}

@end
