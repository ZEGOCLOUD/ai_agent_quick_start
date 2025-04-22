
#import "ZegoAIAgentSubtitlesDefines.h"

@implementation ZegoAIAgentSubtitlesCommand
@end

@implementation ZegoAIAgentAudioSubtitlesMessage
-(instancetype)init{
    if(self = [super init]){
        self.data = [[ZegoAIAgentSubtitlesCommand alloc] init];
    }
    return self;
}
@end

