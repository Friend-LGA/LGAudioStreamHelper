//
//  LGAudioStreamRecorder.m
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

#import "LGAudioStreamRecorder.h"

@interface LGAudioStreamRecorder () <NSURLConnectionDelegate>

typedef enum
{
    LGAudioStreamRecorderResponceTypeHTTP = 1,
    LGAudioStreamRecorderResponceTypeICY  = 2
}
LGAudioStreamRecorderResponceType;

@property (strong, nonatomic) dispatch_queue_t                  selfQueue;
@property (strong, nonatomic) NSURLConnection                   *connection;
@property (strong, nonatomic) NSString                          *contentType;
@property (strong, atomic)    NSMutableData                     *streamData;
@property (strong, nonatomic) NSString                          *fileExtension;
@property (strong, nonatomic) NSURL                             *streamURL;
@property (strong, nonatomic) NSURL                             *localURL;
@property (assign, nonatomic) LGAudioStreamRecorderResponceType responceType;

@property (strong, nonatomic) void (^errorHandler)(NSError *error);

@property (assign, nonatomic, getter=isRecording) BOOL recording;
@property (assign, nonatomic, getter=isParsed) BOOL parsed;

@end

@implementation LGAudioStreamRecorder

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _selfQueue = dispatch_queue_create("com.LGAudioStreamHelper.LGAudioStreamRecorderQueue", NULL);
    }
    return self;
}

- (void)startRecordingFromUrl:(NSURL *)streamUrl
                   toLocalUrl:(NSURL *)localUrl
                 errorHandler:(void(^)(NSError *error))errorHandler
{
    if (!self.isRecording)
    {
        _recording = YES;

        dispatch_async(_selfQueue, ^(void)
                       {
                           [self clear];

                           if (_errorHandler) _errorHandler = nil;

                           _errorHandler = errorHandler;

                           _streamURL = streamUrl;
                           _localURL = localUrl;

                           NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_streamURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
                           [request setHTTPMethod:@"GET"];
                           [request setValue:@"0" forHTTPHeaderField:@"Icy-MetaData"];

                           dispatch_async(dispatch_get_main_queue(), ^(void)
                                          {
                                              _connection = [NSURLConnection connectionWithRequest:request delegate:self];
                                              [_connection start];
                                          });
                       });
    }
}

- (void)stopRecording
{
    if (self.isRecording)
    {
        _recording = NO;

        dispatch_async(_selfQueue, ^(void)
                       {
                           dispatch_async(dispatch_get_main_queue(), ^(void)
                                          {
                                              [_connection cancel];
                                              _connection = nil;
                                          });

                           if (_fileExtension)
                           {
                               _localURL = [_localURL URLByDeletingPathExtension];
                               _localURL = [_localURL URLByAppendingPathExtension:_fileExtension];

                               if (_streamData) [_streamData writeToURL:_localURL atomically:YES];
                           }

                           [self clear];
                       });
    }
}

- (void)identifyFileExtensionForContentType:(NSString *)contentType
{
    if (contentType)
    {
        if ([contentType isEqualToString:@"audio/mp3"])                     _fileExtension = @"mp3";
        else if ([contentType isEqualToString:@"audio/mpg"])                _fileExtension = @"mp3";
        else if ([contentType isEqualToString:@"audio/mpeg"])               _fileExtension = @"mp3";
        else if ([contentType isEqualToString:@"audio/aacp"])               _fileExtension = @"aac";
        else if ([contentType isEqualToString:@"audio/aac"])                _fileExtension = @"aac";
        else if ([contentType isEqualToString:@"audio/ac3"])                _fileExtension = @"ac3";
        else if ([contentType isEqualToString:@"audio/wav"])                _fileExtension = @"wav";
        else if ([contentType isEqualToString:@"audio/x-wav"])              _fileExtension = @"wav";
        else if ([contentType isEqualToString:@"audio/aifc"])               _fileExtension = @"aifc";
        else if ([contentType isEqualToString:@"audio/x-aifc"])             _fileExtension = @"aifc";
        else if ([contentType isEqualToString:@"audio/aiff"])               _fileExtension = @"aiff";
        else if ([contentType isEqualToString:@"audio/x-aiff"])             _fileExtension = @"aiff";
        else if ([contentType isEqualToString:@"audio/x-m4a"])              _fileExtension = @"m4a";
        else if ([contentType isEqualToString:@"audio/m4a"])                _fileExtension = @"m4a";
        else if ([contentType isEqualToString:@"audio/x-mp4"])              _fileExtension = @"mp4";
        else if ([contentType isEqualToString:@"audio/mp4"])                _fileExtension = @"mp4";
        else if ([contentType isEqualToString:@"audio/caf"])                _fileExtension = @"caf";
        else if ([contentType isEqualToString:@"audio/x-caf"])              _fileExtension = @"caf";
        else if ([contentType isEqualToString:@"audio/3gp"])                _fileExtension = @"3gp";
        else if ([contentType isEqualToString:@"audio/3gpp"])               _fileExtension = @"3gp";
        else if ([contentType isEqualToString:@"audio/3gpp2"])              _fileExtension = @"3gp";
        else if ([contentType isEqualToString:@"audio/ogg"])                _fileExtension = @"ogg";
        else if ([contentType isEqualToString:@"application/ogg"])          _fileExtension = @"ogg";
        else if ([contentType isEqualToString:@"application/octet-stream"]) _fileExtension = @"mp3";
        else                                                                _fileExtension = @"mp3";
    }
}

- (void)clear
{
    if ([NSThread currentThread].isMainThread) [self clearEnd];
    else dispatch_sync(dispatch_get_main_queue(), ^(void)
                       {
                           [self clearEnd];
                       });
}

- (void)clearEnd
{
    //_recording = NO;
    _parsed = NO;

    if (_connection)
    {
        [_connection cancel];
        _connection = nil;
    }

    if (_streamData) _streamData = nil;
    if (_contentType) _contentType = nil;
    if (_fileExtension) _fileExtension = nil;
    if (_streamURL) _streamURL = nil;
    if (_localURL) _localURL = nil;

    _responceType = 0;
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSHTTPURLResponse *)response
{
    _streamData = [NSMutableData new];

    NSString *contentType = response.allHeaderFields[@"content-type"];

    if (contentType && contentType.length > 0)
    {
        _responceType = LGAudioStreamRecorderResponceTypeHTTP;

        [self identifyFileExtensionForContentType:contentType];
    }
    else _responceType = LGAudioStreamRecorderResponceTypeICY;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    _recording = NO;

    [self clear];

    if (_errorHandler) _errorHandler(error);
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    dispatch_async(_selfQueue, ^(void)
                   {
                       [_streamData appendData:data];

                       if (_responceType == LGAudioStreamRecorderResponceTypeICY && !self.isParsed && _streamData.length >= 200)
                       {
                           _parsed = YES;

                           NSData *metaData = [_streamData subdataWithRange:NSMakeRange(0, 10)];
                           NSString *string = [NSString stringWithUTF8String:metaData.bytes];

                           if ([string caseInsensitiveCompare:@"ICY 200 OK"] == NSOrderedSame)
                           {
                               NSMutableString *header = [NSMutableString new];

                               for (int i=0; ; i++)
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

                               [self identifyFileExtensionForContentType:contentType];
                           }
                       }
                   });
}

@end
