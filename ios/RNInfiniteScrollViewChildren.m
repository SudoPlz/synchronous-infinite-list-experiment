//
//  RNTableViewChildren.m
//  example
//
//  Created by Tal Kol on 6/8/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "RNInfiniteScrollViewChildren.h"
#import "RCTConvert.h"
#import "RCTEventDispatcher.h"
#import "RCTUtils.h"
#import "UIView+React.h"

@interface RNInfiniteScrollViewChildren()
@end

@implementation RNInfiniteScrollViewChildren

RCTBridge *_bridge;
RCTEventDispatcher *_eventDispatcher;
NSMutableArray *_renderRows;
int _firstRenderRow;
float _firstRenderRowOffset;
int _firstRowIndex;
const int ROW_BUFFER = 2;
float _contentOffsetShift;
NSArray *dataSource;
BOOL rowsAreCreated = NO;

- (instancetype)initWithBridge:(RCTBridge *)bridge {
  RCTAssertParam(bridge);
  NSLog(@"****** initWithBridge BEGAN");
  if ((self = [super initWithFrame:CGRectZero])) {
    _eventDispatcher = bridge.eventDispatcher;
    
    _bridge = bridge;
    while ([_bridge respondsToSelector:NSSelectorFromString(@"parentBridge")]
           && [_bridge valueForKey:@"parentBridge"]) {
      _bridge = [_bridge valueForKey:@"parentBridge"];
    }
    
    _renderRows = [NSMutableArray array];
    dataSource = @[@"Row 1", @"Row 2", @"Row 3", @"Row 4", @"Row 5", @"Row 6", @"Row 7", @"Row 8", @"Row 9", @"Row 10", @"Row 11", @"Row 12", @"Row 13", @"Row 14", @"Row 15", @"Row 16", @"Row 17", @"Row 18", @"Row 19", @"Row 20"];
    _firstRenderRow = 0;
    _firstRenderRowOffset = 0;
    _firstRowIndex = 0;
    _contentOffsetShift = 0;
    
    self.delegate = self;
    self.backgroundColor = [UIColor whiteColor];
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
    NSLog(@"****** initWithBridge ENDED");
  }
  
  return self;
}

RCT_NOT_IMPLEMENTED(-initWithFrame:(CGRect)frame)
RCT_NOT_IMPLEMENTED(-initWithCoder:(NSCoder *)aDecoder)

- (void)insertReactSubview:(UIView *)subview atIndex:(NSInteger)atIndex
{
  // we comment the following lines out bc we don't want to add any views from jsx
  
  //  [_renderRows addObject:subview];
  //  [self insertSubview:subview atIndex:atIndex];
  //  [self bind:subview atIndex:(int)atIndex toRowIndex:(int)atIndex];
  // instead all of that logic will take place in createRows
}



- (void)recenterIfNecessary
{
  CGPoint currentOffset = [self contentOffset];
  CGFloat contentHeight = [self contentSize].height;
  CGFloat centerOffsetY = (contentHeight - [self bounds].size.height) / 2.0;
  CGFloat distanceFromCenter = fabs(currentOffset.y - centerOffsetY);
  
  if ([_renderRows count] > 0 && distanceFromCenter > (contentHeight / 4.0))
  {
    NSLog(@"*** NOW RECENTERING");
    self.contentOffset = CGPointMake(currentOffset.x, centerOffsetY);
    
          int ii = 0;
    // move content by the same amount so it appears to stay still
    for (UIView *view in _renderRows) {
      CGPoint center = view.center;
//      double old = center.y;
      center.y += (centerOffsetY - currentOffset.y);
//      NSLog(@"new Y for %d old y %f, new y: %f", ii, old, center.y);
      view.center = center;
      ii++;
    }
    
    _contentOffsetShift += (centerOffsetY - currentOffset.y);
  }
}

- (void)layoutSubviews {
  [super layoutSubviews];
  
  self.contentSize = CGSizeMake(self.frame.size.width, self.rowHeight * self.numRenderRows * 2);
  
  [self recenterIfNecessary];
  
  CGPoint currentOffset = [self contentOffset];
  
  //  NSLog(@"cur y %f", curYValue);
//  NSLog(@"cur y %f", curYValue);

  double curYValue = currentOffset.y - _contentOffsetShift;
  double furthestPointBottom = _firstRenderRowOffset + (self.rowHeight * (self.numRenderRows - ROW_BUFFER));
  /* the furthest point bottom is
   _firstRenderRowOffset (where we started rendering)
   + the height of all the rows minus the ROW_BUFFER (rows outside the screen)
   */
  if (curYValue + self.frame.size.height > furthestPointBottom) {
    [self moveFirstRenderRowToEnd];
  }
  
  double furthestPointTop = _firstRenderRowOffset; //  + (self.rowHeight * ROW_BUFFER)
  /* the furthest point top is
   _firstRenderRowOffset (where we started rendering)
   + the height of the ROW_BUFFER rows (rows outside the screen)
   */

  if (curYValue < furthestPointTop) {
    [self moveLastRenderRowToBeginning];
  }
}

- (void)moveFirstRenderRowToEnd {
  if (rowsAreCreated == YES && self.numRenderRows > 0 && [_renderRows count] > 0) {
    NSLog(@"************* moveFirstRenderRowToEnd");
    UIView *view = _renderRows[_firstRenderRow];
    CGPoint center = view.center;
    center.y += self.rowHeight * self.numRenderRows;
    view.center = center;
    [self bind:view atIndex:_firstRenderRow toRowIndex:(int)(_firstRowIndex + self.numRenderRows)];
    _firstRenderRowOffset += self.rowHeight;
    _firstRenderRow = (_firstRenderRow + 1) % self.numRenderRows;
    _firstRowIndex += 1;
  }
}

- (void)moveLastRenderRowToBeginning {
  if (rowsAreCreated == YES && self.numRenderRows > 0 && [_renderRows count] > 0) {
    NSLog(@"******* moveLastRenderRowToBeginning");
    int _lastRenderRow = (_firstRenderRow + self.numRenderRows - 1) % (int)self.numRenderRows;
    UIView *view = _renderRows[_lastRenderRow];
    CGPoint center = view.center;
    center.y -= self.rowHeight * self.numRenderRows;
    view.center = center;
    [self bind:view atIndex:_lastRenderRow toRowIndex:(int)(_firstRowIndex - 1)];
    _firstRenderRowOffset -= self.rowHeight;
    _firstRenderRow = _lastRenderRow;
    _firstRowIndex -= 1;
  }
}

- (void)bind:(UIView *)child atIndex:(int)childIndex toRowIndex:(int)rowIndex
{
  if (dataSource != nil && [dataSource count] > rowIndex) {
    NSLog(@"******* Binding childIndex %d to data row %d", childIndex, rowIndex);
    NSString* curRowValue = [dataSource objectAtIndex:rowIndex];
    RCCSyncRootView *curRowView = _renderRows[childIndex];
    if (curRowView) {
      [curRowView updateProps:@{ @"rowValue" : curRowValue }];
    }
  }
}


- (void) createRows {
  NSLog(@"**** NO of rows: %ld", self.numRenderRows);
  for (int i = 0; i < self.numRenderRows; i++)
  {
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                     if (dataSource != nil && [dataSource count] > i) {
                       NSString* curRowValue = [dataSource objectAtIndex:i];
                       RCCSyncRootView *rootView = [[RCCSyncRootView alloc] initWithBridge:_bridge moduleName:@"RNInfiniteScrollViewRowTemplate" initialProperties:@{ @"rowValue" : curRowValue }];
                       //        [rootView setFrame:CGRectMake(0, 0, 1000, self.rowHeight)];
                       CGPoint center = rootView.center;
                       center.y = self.rowHeight * i;
                       NSLog(@"******* ITEM AT %d, will place that at %f", i, center.y);
                       rootView.center = center;
                       rootView.backgroundColor = [UIColor yellowColor];
                       [_renderRows addObject:rootView];
                       [self insertSubview:rootView atIndex:i];
                     }
                   });
  }
  rowsAreCreated = YES;
}

#pragma mark - UIScrollViewDelegate callbacks

//-(void) scrollViewDidScroll {
//  NSLog(@"scrollViewDidScroll");
//}

-(void) scrollViewWillBeginDragging {
  NSLog(@"scrollViewWillBeginDragging");
}

-(void) scrollViewWillEndDragging {
  NSLog(@"scrollViewWillEndDragging");
}

-(void) scrollViewDidEndDragging {
  NSLog(@"scrollViewDidEndDragging");
}



@end
