#ifndef ZegoChatCellLabelViewColors_h
#define ZegoChatCellLabelViewColors_h

#import <Foundation/Foundation.h>
#import <UIKit/UIColor.h>

@interface ZegoAIAgentSubtitlesColors : NSObject

@property(nonatomic, strong) UIColor *myBackgroundColor;
@property(nonatomic, strong) UIColor *myTextColor;
@property(nonatomic, strong) UIColor *otherBackgroundColor;
@property(nonatomic, strong) UIColor *otherTextColor;

- (instancetype)initWithMyBackgroundColor:(UIColor *)myBackgroundColor
                              myTextColor:(UIColor *)myTextColor
                     otherBackgroundColor:(UIColor *)otherBackgroundColor
                           otherTextColor:(UIColor *)otherTextColor;

@end

#endif // #ifndef ZegoChatCellLabelViewColors_h
