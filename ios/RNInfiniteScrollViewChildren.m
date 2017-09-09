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
int createdRowCnt = 0;

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
    dataSource = @[@"Row 0", @"Row 1", @"Row 2", @"Row 3", @"Row 4", @"Row 5", @"Row 6", @"Row 7", @"Row 8", @"Row 9", @"Row 10", @"Row 11", @"Row 12", @"Row 13", @"Row 14", @"Row 15", @"Row 16", @"Row 17", @"Row 18", @"Row 19"];
    _firstRenderRow = 0;
    _firstRenderRowOffset = 0;
    _firstRowIndex = 0;
    _contentOffsetShift = 0;
    
//    emptyRowView = [[RCCSyncRootView alloc] initWithBridge:_bridge moduleName:@"RNInfiniteScrollViewRowTemplate" initialProperties:@{}];
//    emptyRowView.isEmptyView = YES;

    self.delegate = self;
    self.backgroundColor = [UIColor whiteColor];
    self.showsVerticalScrollIndicator = YES; // TODO change that to NO in time
    self.showsHorizontalScrollIndicator = NO;
    self.loopMode = LOOP_MODE_NONE;
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
  CGPoint currentOffset = [self contentOffset]; // cur scroll values
  CGFloat contentHeight = [self contentSize].height;
  CGFloat centerOffsetY = (contentHeight - [self bounds].size.height) / 2.0; // find the center Y point
  CGFloat distanceFromCenter = fabs(currentOffset.y - centerOffsetY); // find the distance of the center Y
//  NSLog(@"cur offset %f w/ content height %f, and center x: %f, so the distance from center is %f", currentOffset.y, contentHeight, centerOffsetY, distanceFromCenter);

  if (rowsAreCreated == YES // if the rows have been created
      && [self.loopMode  isEqual: LOOP_MODE_NONE] == NO // if we're NOT on loop mode
      && [_renderRows count] > 0 // and we got renderRows
      && distanceFromCenter > (contentHeight / 4.0)) // and we have scrolled more than 25% ahead
  {
    // setting the Y value to be equal to the center Y point
    self.contentOffset = CGPointMake(currentOffset.x, centerOffsetY);

    // move content by the same amount so it appears to stay still
    for (UIView *view in _renderRows) {
      CGPoint center = view.center;
      center.y += (centerOffsetY - currentOffset.y);
      NSLog(@"New center %f", center.y);
      view.center = center;
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
    
//    int rowToBindTo;

//    if ([self.loopMode  isEqual: LOOP_MODE_REPEAT_EDGE]) {
//      // if the loopMode is repeat w/ using the edge views
//      rowToBindTo = (int)(_firstRowIndex + self.numRenderRows);
//    } else { // if the loopMode is set to no-loop or to repeat-empty
//      rowToBindTo = EMPTY_ROW_ID;
//    }
    // TODO that is not right
    
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
//    int rowToBindTo;
    
//    if ([self.loopMode  isEqual: LOOP_MODE_REPEAT_EDGE]) {
//      // if the loopMode is repeat w/ using the edge views
//      rowToBindTo = (int);
//    } else { // if the loopMode is set to no-loop or to repeat-empty
//      rowToBindTo = EMPTY_ROW_ID;
//    }

    [self bind:view atIndex:_lastRenderRow toRowIndex:(_firstRowIndex - 1)];
    _firstRenderRowOffset -= self.rowHeight;
    _firstRenderRow = _lastRenderRow;
    _firstRowIndex -= 1;
  }
}

- (void)bind:(UIView *)child atIndex:(int)childIndex toRowIndex:(int)rowIndex
{
  if (dataSource != nil) {
      NSLog(@"******* Binding childIndex %d to data row %d.", childIndex, rowIndex);
    
    RCCSyncRootView *curRowView = _renderRows[childIndex];

    if (rowIndex >= 0 && rowIndex < dataSource.count) { // if the data index is within our datasource bounds
      [curRowView updateProps: @{ @"rowValue" : [dataSource objectAtIndex:rowIndex]}]; // just update the row
    } else {
      NSNumber *newDataIndex;

      if ([self.loopMode  isEqual: LOOP_MODE_REPEAT_EDGE]) { // if we're loop repeat-empty-mode
        // find the (absolute) modulo of the row index
        int moduloRowIndex = (ABS(rowIndex) % dataSource.count);
        if (rowIndex >= 0) { // if the row index is a positive number
          newDataIndex = [NSNumber numberWithInt:moduloRowIndex];
        } else { // else if the row index is a negative number
          // we'll need to do some more work to calculate the new index
          
          // calculate the new data index
          newDataIndex = moduloRowIndex == 0 ? // if the modulo is 0
            [NSNumber numberWithInt:moduloRowIndex] // just return the modulo
          :              // else
            [NSNumber numberWithInt:(int) dataSource.count - moduloRowIndex];
          // we do that because we want the values to start again from the end of the array once the user reaches child 0 (a.k.a when rowIndex is negative)
        }
        NSLog(@"rowIndex %d was translated to %d because %d mod %lu", rowIndex, newDataIndex.intValue, rowIndex, (unsigned long)dataSource.count);
      }
      
      if (newDataIndex != nil) { // if we have a newDataIndex value
        // just set the view data to the value of that index
        [curRowView updateProps: @{ @"rowValue" : [dataSource objectAtIndex:newDataIndex.intValue]}];
      } else { // otherwise if we don't have a value
        // set the view data to the empty view
        [curRowView updateProps:@{}];
      }
    }
  }
}


- (void) createRows {
  NSLog(@"**** NO of rows: %ld", self.numRenderRows);
  NSLog(@" loop? %@", self.loopMode);
  rowsAreCreated = NO;
  createdRowCnt = 0;

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
                       createdRowCnt ++;
                       NSLog(@" Created row %d", createdRowCnt);
                       if (createdRowCnt == self.numRenderRows) {
                         NSLog(@" @@@@@@ ROWS CREATED");
                         rowsAreCreated = YES;
                         [self recenterIfNecessary];
                       }
                     }
                   });
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

@end
