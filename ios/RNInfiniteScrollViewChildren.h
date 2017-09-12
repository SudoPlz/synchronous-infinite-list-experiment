//
//  RNTableViewChildren.h
//  example
//
//  Created by Tal Kol on 6/8/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RCCSyncRootView.h"
#import "ScrollViewBindFactory.h"
#import "NoLoopBinder.h"
#import "RepeatEdgeBinder.h"
#import "RepeatEmptyBinder.h"

@class RCTBridge;

@interface RNInfiniteScrollViewChildren : UIScrollView <UIScrollViewDelegate>

- (instancetype)initWithBridge:(RCTBridge *)bridge NS_DESIGNATED_INITIALIZER;
- (void) createRows;
- (void) appendDataToDataSource: (NSArray*) newData;
- (void) prependDataToDataSource: (NSArray*) newData;
  
@property (nonatomic) float rowHeight;
@property (nonatomic) float yeep;
@property (nonatomic) int initialPosition;
@property (nonatomic) NSInteger numRenderRows;
@property (nonatomic) NSString *loopMode;
@property (nonatomic) NSMutableArray *data;


@end
