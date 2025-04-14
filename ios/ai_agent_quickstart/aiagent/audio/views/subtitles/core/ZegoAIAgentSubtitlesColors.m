#import "ZegoAIAgentSubtitlesColors.h"

@interface ZegoAIAgentSubtitlesColors ()
@end

@implementation ZegoAIAgentSubtitlesColors

- (instancetype)initWithMyBackgroundColor:(UIColor *)myBackgroundColor
                              myTextColor:(UIColor *)myTextColor
                     otherBackgroundColor:(UIColor *)otherBackgroundColor
                           otherTextColor:(UIColor *)otherTextColor {
    self = [super init];
    if (self) {
        self.myBackgroundColor = myBackgroundColor;
        self.myTextColor = myTextColor;
        self.otherBackgroundColor = otherBackgroundColor;
        self.otherTextColor = otherTextColor;
    }
    return self;
}

@end
