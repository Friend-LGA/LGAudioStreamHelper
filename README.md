# LGAudioStreamHelper

iOS helper for easy recording audio stream, getting metadata and type of stream.

- [LGAudioStreamMetadataGetter](https://github.com/Friend-LGA/LGAudioStreamHelper/blob/master/LGAudioStreamHelper/LGAudioStreamMetadataGetter/LGAudioStreamMetadataGetter.h) helps to get metadata of audio stream.
- [LGAudioStreamContentTypeGetter](https://github.com/Friend-LGA/LGAudioStreamHelper/blob/master/LGAudioStreamHelper/LGAudioStreamContentTypeGetter/LGAudioStreamContentTypeGetter.h) helps to get type of audio stream.
- [LGAudioStreamRecorder](https://github.com/Friend-LGA/LGAudioStreamHelper/blob/master/LGAudioStreamHelper/LGAudioStreamRecorder/LGAudioStreamRecorder.h) helps to record audio stream.

## Installation

### With source code

[Download repository](https://github.com/Friend-LGA/LGAudioStreamHelper/archive/master.zip), then add [LGAudioStreamHelper directory](https://github.com/Friend-LGA/LGAudioStreamHelper/blob/master/LGAudioStreamHelper/) to your project.

### With CocoaPods

[CocoaPods](http://cocoapods.org/) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries in your projects. See the "Get Started" section for more details.

#### Podfile
```
platform :ios, '6.0'
pod 'LGAudioStreamHelper', '~> 1.0.0'
```

## Usage

In the source files where you need to use the library, import the header file:

```objective-c
#import "LGAudioStreamHelper.h"
```

Or you can use sublibraries separately, depend of your needs: 

```objective-c
#import "LGAudioStreamMetadataGetter.h"     // helps to get metadata of audio stream 
#import "LGAudioStreamContentTypeGetter.h"  // helps to get type of audio stream
#import "LGAudioStreamRecorder.h"           // helps to record audio stream
```

### More

For more details see files:
- [LGAudioStreamMetadataGetter.h](https://github.com/Friend-LGA/LGAudioStreamHelper/blob/master/LGAudioStreamHelper/LGAudioStreamMetadataGetter/LGAudioStreamMetadataGetter.h)
- [LGAudioStreamContentTypeGetter.h](https://github.com/Friend-LGA/LGAudioStreamHelper/blob/master/LGAudioStreamHelper/LGAudioStreamContentTypeGetter/LGAudioStreamContentTypeGetter.h)
- [LGAudioStreamRecorder.h](https://github.com/Friend-LGA/LGAudioStreamHelper/blob/master/LGAudioStreamHelper/LGAudioStreamRecorder/LGAudioStreamRecorder.h)

## License

LGAudioStreamHelper is released under the MIT license. See [LICENSE](https://raw.githubusercontent.com/Friend-LGA/LGAudioStreamHelper/master/LICENSE) for details.
