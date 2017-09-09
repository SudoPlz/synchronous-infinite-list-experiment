//
//  RNTableViewChildren.h
//  example
//
//  Created by Tal Kol on 6/8/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCCSyncRootView.h"

@class RCTBridge;

@interface RNInfiniteScrollViewChildren : UIScrollView <UIScrollViewDelegate>

- (instancetype)initWithBridge:(RCTBridge *)bridge NS_DESIGNATED_INITIALIZER;
- (void) createRows;

@property (nonatomic) float rowHeight;
@property (nonatomic) float yeep;
@property (nonatomic) NSInteger numRenderRows;
@property (nonatomic) NSString *loopMode;

@end
