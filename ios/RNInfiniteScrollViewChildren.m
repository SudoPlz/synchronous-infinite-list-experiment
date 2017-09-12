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

#define EMPTY_ROW_ID -1
#define LOOP_MODE_NONE @"no-loop"
#define LOOP_MODE_REPEAT_EMPTY @"repeat-empty"
#define LOOP_MODE_REPEAT_EDGE @"repeat-edge"

@interface RNInfiniteScrollViewChildren()
@end

@implementation RNInfiniteScrollViewChildren
@synthesize data;

RCTBridge *_bridge;
RCTEventDispatcher *_eventDispatcher;
NSMutableArray *_renderRows;
int _firstRenderRow;
float _firstRenderRowOffset;
int _firstRowIndex;
const int ROW_BUFFER = 2;
float _contentOffsetShift;
BOOL rowsAreCreated = NO;
int createdRowCnt = 0;
ScrollViewBindFactory* bindFactory;

- (instancetype)initWithBridge:(RCTBridge *)bridge {
  RCTAssertParam(bridge);
  //  NSLog(@"****** initWithBridge BEGAN");
  if ((self = [super initWithFrame:CGRectZero])) {
    _eventDispatcher = bridge.eventDispatcher;
    
    _bridge = bridge;
    while ([_bridge respondsToSelector:NSSelectorFromString(@"parentBridge")]
           && [_bridge valueForKey:@"parentBridge"]) {
      _bridge = [_bridge valueForKey:@"parentBridge"];
    }
    
    _renderRows = [NSMutableArray array];
    _firstRenderRow = 0;
    _firstRenderRowOffset = 0;
    _firstRowIndex = 0;
    _contentOffsetShift = 0;
    _initialPosition = 0;
    
    //    emptyRowView = [[RCCSyncRootView alloc] initWithBridge:_bridge moduleName:@"RNInfiniteScrollViewRowTemplate" initialProperties:@{}];
    //    emptyRowView.isEmptyView = YES;
    
    self.delegate = self;
    self.backgroundColor = [UIColor whiteColor];
    self.showsVerticalScrollIndicator = YES; // TODO change that to NO in time
    self.showsHorizontalScrollIndicator = NO;
    self.loopMode = LOOP_MODE_NONE;
    bindFactory = [[NoLoopBinder alloc] init];
    //    NSLog(@"****** initWithBridge ENDED");
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
  CGPoint currentOffset = [self contentOffset]; // cur scroll values
  CGFloat contentHeight = [self contentSize].height;
  CGFloat centerOffsetY = (contentHeight - [self bounds].size.height) / 2.0; // find the center Y point
  CGFloat distanceFromCenter = fabs(currentOffset.y - centerOffsetY); // find the distance of the center Y
  if (rowsAreCreated == YES // if the rows have been created
      // && [self.loopMode  isEqual: LOOP_MODE_NONE] == NO // if we're NOT on loop mode
      && _renderRows.count > 0 // and we got renderRows
      && distanceFromCenter > (contentHeight / 4.0)) // and we have scrolled more than 25% ahead
  {
//    NSLog(@"distance from center: %f > %f", distanceFromCenter, (contentHeight / 4.0));
    [self recenterTo: CGPointMake(0, centerOffsetY)];
  }
}

- (void) recenterTo: (CGPoint) recenterPoint withNewBindingsStartingFrom: (NSNumber*) bindStart {
  CGPoint currentOffset = [self contentOffset]; // cur scroll values
//    NSLog(@"cur offset %f and center x: %f", currentOffset.y, recenterPoint.y);
  
  
//  NSLog(@" @@@@@@ NOW RECENTERRING to %f", recenterPoint.y);
  // setting the Y value to be equal to the center Y point
  self.contentOffset = CGPointMake(currentOffset.x, recenterPoint.y);
  
//  int bindShouldStartFrom = bindStart != nil ? bindStart.intValue - ROW_BUFFER : 0;

  // move content by the same amount so it appears to stay still
  int i = 0;
  for (RCCSyncRootView *view in _renderRows) {
    CGPoint center = view.center;
    center.y += (recenterPoint.y - currentOffset.y);
    NSLog(@"New center %f", center.y);
    view.center = center;
    if (bindStart != nil) {
      NSLog(@"Binding it to %d", bindStart.intValue + i);
      [self bindView:view toRowIndex:(int)(bindStart.intValue + i)];
    }
    i++;
  }
  
  _contentOffsetShift += (recenterPoint.y - currentOffset.y);
}

- (void) recenterTo: (CGPoint) recenterPoint {
  [self recenterTo: recenterPoint withNewBindingsStartingFrom:nil];
}


- (void) swapViewsIfNecessary {
  CGPoint currentOffset = [self contentOffset];
  
  double curYValue = currentOffset.y - _contentOffsetShift;
//  NSLog(@"cur y %f bc currentOffset.y: %f - _contentOffsetShift: %f", curYValue, currentOffset.y, _contentOffsetShift);
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

- (void)layoutSubviews {
  [super layoutSubviews];
//  NSLog(@"_firstRenderRowOffset: %f, _firstRenderRow: %d, _firstRowIndex: %d", _firstRenderRowOffset, _firstRenderRow, _firstRowIndex);
  [self recenterIfNecessary];
  [self swapViewsIfNecessary];
}

- (void)moveFirstRenderRowToEnd {
  //  NSLog(@" abt to moveFirstRenderRowToEnd");
  if (rowsAreCreated == YES && self.numRenderRows > 0 && [_renderRows count] > 0) {
    //    NSLog(@"************* moveFirstRenderRowToEnd");
    RCCSyncRootView *view = _renderRows[_firstRenderRow];
    CGPoint center = view.center;
    center.y += self.rowHeight * self.numRenderRows;
    view.center = center;

    
    [self bindView:view toRowIndex:(int)(_firstRowIndex + self.numRenderRows)];
    _firstRenderRowOffset += self.rowHeight;
    _firstRenderRow = (_firstRenderRow + 1) % self.numRenderRows;
    _firstRowIndex += 1;
  }
}

- (void)moveLastRenderRowToBeginning {
  //  NSLog(@" abt to moveLastRenderRowToBeginning");
  if (rowsAreCreated == YES && self.numRenderRows > 0 && [_renderRows count] > 0) {
//        NSLog(@"******* moveLastRenderRowToBeginning");
    int _lastRenderRow = (_firstRenderRow + self.numRenderRows - 1) % (int)self.numRenderRows;
    RCCSyncRootView *view = _renderRows[_lastRenderRow];
    CGPoint center = view.center;
    center.y -= self.rowHeight * self.numRenderRows;
    view.center = center;
    //    int rowToBindTo;
    
    //    if ([self.loopMode  isEqual: LOOP_MODE_REPEAT_EDGE]) {
    //      // if the loopMode is repeat w/ using the edge views
    //      rowToBindTo = (int);
    //    } else { // if the loopMode is set to no-loop or to repeat-empty
    //      rowToBindTo = EMPTY_ROW_ID;
    //    }
    [self bindView:view toRowIndex:(_firstRowIndex - 1)];
    _firstRenderRowOffset -= self.rowHeight;
    _firstRenderRow = _lastRenderRow;
    _firstRowIndex -= 1;
  }
}

//- (void)bindViewAtIndex:(int)childIndex toRowIndex:(int)rowIndex
//{
//  RCCSyncRootView *curRowView = _renderRows[childIndex];
//  NSDictionary* newDt = [bindFactory getValueForRow:rowIndex andDatasource:data];
//  if (newDt) {
//    [curRowView updateProps:newDt];
//  }
//}

- (void)bindView:(RCCSyncRootView *)child toRowIndex:(int)rowIndex
{
//  NSLog(@"Now requesting to bind row index %d", rowIndex);
  NSDictionary* newDt = [bindFactory getValueForRow:rowIndex andDatasource:data];
  if (newDt) {
    [child updateProps:newDt];
  }
}

#pragma mark - UIScrollViewDelegate callable methods


- (void) createRows {
  //  NSLog(@"**** NO of rows: %ld", self.numRenderRows);
  //  NSLog(@" loop? %@", self.loopMode);
  rowsAreCreated = NO;
  createdRowCnt = 0;
  
  for (int i = 0; i < self.numRenderRows; i++)
  {
    //    NSLog(@"%d", i);
    dispatch_async(dispatch_get_main_queue(), ^
                   {
                     NSString* curRowValue;
                     if (data != nil && [data count] > i) {
                       curRowValue = [data objectAtIndex:i];
                     }
                     
                     RCCSyncRootView *rootView = [[RCCSyncRootView alloc] initWithBridge:_bridge moduleName:@"RNInfiniteScrollViewRowTemplate" initialProperties:curRowValue ? @{ @"rowValue" : curRowValue } : @{}];
                     
                     CGPoint center = rootView.center;
                     center.y = self.rowHeight * i;
                     //                       NSLog(@"******* ITEM AT %d, will place that at %f", i, center.y);
                     rootView.center = center;
                     rootView.backgroundColor = [UIColor yellowColor];
                     [_renderRows addObject:rootView];
                     [self insertSubview:rootView atIndex:i];
                     createdRowCnt ++;
                     //                       NSLog(@" Created row %d out of %ld", createdRowCnt, (long)self.numRenderRows);
                     if (createdRowCnt == self.numRenderRows) {
                       NSLog(@" @@@@@@ ROWS CREATED");
                       rowsAreCreated = YES;
                       self.contentSize = CGSizeMake(self.frame.size.width, self.rowHeight * data.count);
                       
                       if (_initialPosition != 0) {
                         [self scrollToItemWithIndex:_initialPosition animated:NO];
                       }
                     }
                   });
  }
}

- (void) appendDataToDataSource: (NSArray*) newData {
  NSLog(@" NEW DATA %@", newData);
  [data addObjectsFromArray:newData];
}

- (void) scrollToItemWithIndex: (int) itemIndex animated: (BOOL) animated {
  float newOffsetY = itemIndex * self.rowHeight;
  
  if (animated == NO) {
    CGFloat contentHeight = [self contentSize].height;
    CGFloat centerOffsetY = (contentHeight - [self bounds].size.height) / 2.0; // find the center Y point

    [self recenterTo: CGPointMake(0, centerOffsetY) withNewBindingsStartingFrom:[NSNumber numberWithInt:itemIndex]];
    _firstRenderRowOffset = 0;
    _firstRenderRow = 0;
    _firstRowIndex = itemIndex;
  } else {
    [self setContentOffset: CGPointMake(0, newOffsetY) animated:YES];
  }
}


#pragma mark - UIScrollViewDelegate callbacks


//-(void) scrollViewDidScroll:(UIScrollView *)scrollView {
//  NSLog(@"scrollViewDidScroll");
//}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
  //  NSLog(@"scrollViewWillBeginDragging");
}

-(void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
  //  NSLog(@"scrollViewWillEndDragging");
}


#pragma mark - Setter functions

//- (void) setRowHeight:(float)rowHeight{
//  _rowHeight = rowHeight;
//  NSLog(@"####################### rowHeight was SET");
//}

- (void) setLoopMode:(NSString *)loopMode {
  _loopMode = loopMode;
  if ([loopMode isEqualToString:LOOP_MODE_REPEAT_EMPTY]) {
    bindFactory = [[RepeatEmptyBinder alloc] init];
  } else if ([loopMode isEqualToString:LOOP_MODE_REPEAT_EDGE]) {
    bindFactory = [[RepeatEdgeBinder alloc] init];
  } else {
    bindFactory = [[NoLoopBinder alloc] init];
  }
}

- (void) setData:(NSArray *) newData {
  data = [newData mutableCopy];
}

@end
