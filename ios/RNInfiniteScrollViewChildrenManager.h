//
//  TableViewChildren.h
//  example
//
//  Created by Tal Kol on 6/8/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "RCTViewManager.h"
#import "RNInfiniteScrollViewChildren.h"

@interface RNInfiniteScrollViewChildrenManager : RCTViewManager
-(void) prepareRows:(nonnull NSNumber *)reactTag;
@property (nonatomic, strong) RNInfiniteScrollViewChildren * _Nullable scrollView;
@property (nonatomic) BOOL loop;
@end
