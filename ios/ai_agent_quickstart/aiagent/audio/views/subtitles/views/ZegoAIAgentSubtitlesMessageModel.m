#import "ZegoAIAgentSubtitlesMessageModel.h"
@interface ZegoAIAgentSubtitlesMessageModel()
@end

@implementation ZegoAIAgentSubtitlesMessageModel

- (NSString *) description{
    return [NSString stringWithFormat:@"<%d %lld #%lld %@>", self.isMine, self.seqId, self.messageTimeStamp, self.content];
}

-(void)setContent:(NSString *)content{
    _content = content;
    
    UIFont *font = [UIFont fontWithName:@"PingFang SC" size:15.0];
    NSDictionary *attributes = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: [UIColor blackColor]
    };
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:_content attributes:attributes];
    
    // 计算文本的大小
    CGSize maxSize = CGSizeMake(239, CGFLOAT_MAX);
    CGRect boundingBox = [attributedString boundingRectWithSize:maxSize
                                                        options:NSStringDrawingUsesLineFragmentOrigin
                                                       context:nil];
    boundingBox.size.width = boundingBox.size.width + 10;
    CGRect newRect = CGRectInset(boundingBox, -12, -10);
    self.boundingBox = newRect;
}
@end
