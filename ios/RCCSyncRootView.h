
#import <UIKit/UIKit.h>
#import <React/RCTRootView.h>

@interface RCCSyncRootView : RCTRootView

- (void)updateProps:(NSDictionary *)newProps;

@property (nonatomic) int boundToIndex;

@end
