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
#define RECENTER_PERCENTAGE 0.25

@interface RNInfiniteScrollViewChildren()
@end

@implementation RNInfiniteScrollViewChildren
@synthesize data;

#pragma mark - init

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
    _horizontal = NO;
    
    //    emptyRowView = [[RCCSyncRootView alloc] initWithBridge:_bridge moduleName:@"RNInfiniteScrollViewRowTemplate" initialProperties:@{}];
    //    emptyRowView.isEmptyView = YES;
    
    self.delegate = self;
    self.backgroundColor = [UIColor whiteColor];
    self.showsVerticalScrollIndicator = YES; // TODO change that to NO in time
    self.showsHorizontalScrollIndicator = YES; // TODO change that to NO in time
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
  [super insertReactSubview: subview atIndex:atIndex];
  // we comment the following lines out bc we don't want to add any views from jsx
  
  //  [_renderRows addObject:subview];
  //  [self insertSubview:subview atIndex:atIndex];
  //  [self bind:subview atIndex:(int)atIndex toRowIndex:(int)atIndex];
  // instead all of that logic will take place in createRows
}

#pragma mark - inner methods

- (void)recenterIfNecessary
{
  CGPoint currentOffset = [self contentOffset]; // cur scroll values
  if (_horizontal == NO) { // vertical mode
    CGFloat contentHeight = [self contentSize].height;
    CGFloat centerOffsetY = (contentHeight - [self bounds].size.height) / 2.0; // find the center Y point
    CGFloat distanceFromCenter = fabs(currentOffset.y - centerOffsetY); // find the distance of the center Y
    if (rowsAreCreated == YES // if the rows have been created
        && _renderRows.count > 0 // and we got renderRows
        && distanceFromCenter > (contentHeight * RECENTER_PERCENTAGE)) // and we have scrolled more than 25% ahead
    {
      [self recenterTo: CGPointMake(0, centerOffsetY)];
    }
  } else { // horizontal mode
    CGFloat contentWidth = [self contentSize].width;
    CGFloat centerOffsetX = (contentWidth - [self bounds].size.width) / 2.0; // find the center Y point
    CGFloat distanceFromCenter = fabs(currentOffset.x - centerOffsetX); // find the distance of the center Y
    if (rowsAreCreated == YES // if the rows have been created
        && _renderRows.count > 0 // and we got renderRows
        && distanceFromCenter > (contentWidth * RECENTER_PERCENTAGE)) // and we have scrolled more than 25% ahead
    {
//      NSLog(@" Must recenter because distance from center (%f) is more than 25% (%f), contentWidth=%f", distanceFromCenter, contentWidth * RECENTER_PERCENTAGE, contentWidth);
      [self recenterTo: CGPointMake(centerOffsetX, 0)];
    }
  }
}

- (void) recenterTo: (CGPoint) recenterPoint withNewBindingsStartingFrom: (NSNumber*) bindStart {
  CGPoint currentOffset = [self contentOffset]; // cur scroll values
  if (_horizontal == YES) { // horizontal mode
    NSLog(@" Now recentering to x: %f, y: %f", recenterPoint.x, currentOffset.y);
    
    // setting the Y value to be equal to the center Y point
    self.contentOffset = CGPointMake(recenterPoint.x, currentOffset.y);

    // move content by the same amount so it appears to stay still
    int i = 0;
    for (RCCSyncRootView *view in _renderRows) {
      CGPoint center = view.center;
      center.x += (recenterPoint.x - currentOffset.x);
      view.center = center;
      if (bindStart != nil) {
        [self bindView:view toRowIndex:(int)(bindStart.intValue + i)];
      }
      i++;
    }
    _contentOffsetShift += (recenterPoint.x - currentOffset.x);
  } else { // vertical mode
    NSLog(@" Now recentering to x: %f, y: %f", currentOffset.x, recenterPoint.y);
    
    // setting the Y value to be equal to the center Y point
    self.contentOffset = CGPointMake(currentOffset.x, recenterPoint.y);

    // move content by the same amount so it appears to stay still
    int i = 0;
    for (RCCSyncRootView *view in _renderRows) {
      CGPoint center = view.center;
      center.y += (recenterPoint.y - currentOffset.y);
      view.center = center;
      if (bindStart != nil) {
        [self bindView:view toRowIndex:(int)(bindStart.intValue + i)];
      }
      i++;
    }
    _contentOffsetShift += (recenterPoint.y - currentOffset.y);
  }
}

- (void) recenterTo: (CGPoint) recenterPoint {
  [self recenterTo: recenterPoint withNewBindingsStartingFrom:nil];
}


- (void) swapViewsIfNecessary {
  CGPoint currentOffset = [self contentOffset];
  
  if (_horizontal == NO) { // vertical mode
    double curYValue = currentOffset.y - _contentOffsetShift;
    double furthestPointBottom = _firstRenderRowOffset + (self.rowHeight * (self.numRenderRows - ROW_BUFFER));
    /* the furthest point bottom is
     _firstRenderRowOffset (where we started rendering)
     + the height of all the rows minus the ROW_BUFFER (rows outside the screen)
     */
    if (curYValue + self.frame.size.height > furthestPointBottom) {
      [self moveFirstRenderRowToEnd];
    }
    
    double furthestPointTop = _firstRenderRowOffset + (self.rowHeight * ROW_BUFFER);
    /* the furthest point ahead is
     _firstRenderRowOffset (where we started rendering)
     + the height of the ROW_BUFFER rows (rows outside the screen)
     */
    
    if (curYValue < furthestPointTop) {
      [self moveLastRenderRowToBeginning];
    }
  } else { // horizontal mode
    double curXValue = currentOffset.x - _contentOffsetShift;
    double furthestPointRight = _firstRenderRowOffset + (self.rowWidth * (self.numRenderRows - ROW_BUFFER));
    /* the furthest point right is
     _firstRenderRowOffset (where we started rendering)
     + the width of all the rows minus the ROW_BUFFER (rows outside the screen)
     */
    if (curXValue + self.frame.size.width > furthestPointRight) {
      NSLog(@"curXValue: %f plus frame width %f > furthestPointRight %f", curXValue, self.frame.size.width, furthestPointRight);
      [self moveFirstRenderRowToEnd];
    }
    
    double furthestPointLeft = _firstRenderRowOffset + (self.rowWidth * ROW_BUFFER);
    NSLog(@"furthestPointLeft: %f plus 2 more rows (%f) ", furthestPointLeft, (self.rowWidth * ROW_BUFFER));
    /* the furthest point left is
     _firstRenderRowOffset (where we started rendering)
     + the height (or width) of the ROW_BUFFER rows (rows outside the screen)
     */
    
    if (curXValue < furthestPointLeft) {
      NSLog(@"cur X: %f, < furthestPointLeft %f ? ", curXValue, furthestPointLeft);
      [self moveLastRenderRowToBeginning];
    }
  }
  
}

- (void)moveFirstRenderRowToEnd {
  //  NSLog(@" abt to moveFirstRenderRowToEnd");
  if (rowsAreCreated == YES && self.numRenderRows > 0 && [_renderRows count] > 0) {
        NSLog(@"************* moveFirstRenderRowToEnd");
    RCCSyncRootView *view = _renderRows[_firstRenderRow];
    CGPoint center = view.center;
    if (_horizontal == NO) { // vertical mode
      center.y += self.rowHeight * self.numRenderRows;
      _firstRenderRowOffset += self.rowHeight;
    } else { // horizontal mode
      center.x += self.rowWidth * self.numRenderRows;
      _firstRenderRowOffset += self.rowWidth;
    }
    view.center = center;
    
    _firstRenderRow = (_firstRenderRow + 1) % self.numRenderRows;
    _firstRowIndex += 1;
    [self bindView:view toRowIndex:(int)(_firstRowIndex + self.numRenderRows)];
  }
}

- (void)moveLastRenderRowToBeginning {
  //  NSLog(@" abt to moveLastRenderRowToBeginning");
  if (rowsAreCreated == YES && self.numRenderRows > 0 && [_renderRows count] > 0) {
        NSLog(@"******* moveLastRenderRowToBeginning");
    int _lastRenderRow = (_firstRenderRow + self.numRenderRows - 1) % (int)self.numRenderRows;
    RCCSyncRootView *view = _renderRows[_lastRenderRow];
    CGPoint center = view.center;
    if (_horizontal == NO) { // vertical mode
      center.y -= self.rowHeight * self.numRenderRows;
      _firstRenderRowOffset -= self.rowHeight;
    } else { // horizontal mode
      center.x -= self.rowWidth * self.numRenderRows;
      _firstRenderRowOffset -= self.rowWidth;
    }
    view.center = center;
    [self bindView:view toRowIndex:(_firstRowIndex - 1)];
    _firstRenderRow = _lastRenderRow;
    _firstRowIndex -= 1;
  }
}

//- (void)bindViewAtIndex:(int)childIndex toRowIndex:(int)rowIndex
//{
//  RCCSyncRootView *curRowView = _renderRows[childIndex];
//  NSDictionary* newDt = [bindFactory getValueForRow:rowIndex andDatasource:data];
//  if (newDt) {
//curRowView.boundToIndex = rowIndex;
//    [curRowView updateProps:newDt];
//  }
//}

- (void)bindView:(RCCSyncRootView *)child toRowIndex:(int)rowIndex
{
  if (child.boundToIndex != rowIndex || rowIndex == 0) {
//    NSLog(@"Now requesting to bind row index %d", rowIndex);
    NSDictionary* newDt = [bindFactory getValueForRow:rowIndex andDatasource:data];
    if (newDt) {
//      NSLog(@"GOT DATA %@", newDt);
      child.boundToIndex = rowIndex;
      [child updateProps:newDt];
    }
  }
}

#pragma mark - exposed methods


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
                     
                     RCCSyncRootView *rootView = [[RCCSyncRootView alloc] initWithBridge:_bridge moduleName:@"RNInfiniteScrollViewRowTemplate" initialProperties:curRowValue ? @{ @"item" : curRowValue, @"index": [NSNumber numberWithInt:i] } : @{ @"index": [NSNumber numberWithInt:i]}];
                     rootView.boundToIndex = i;
                     CGPoint center = rootView.center;
                     if (_horizontal == NO) { // vertical mode
                       center.y = self.rowHeight * i;
                     } else { // horizontal mode
                       center.x = self.rowWidth * i;
                     }
                     NSLog(@"******* ITEM AT %d, will be placed that at x: %f, y: %f", i, center.x, center.y);
                     
                     rootView.center = center;
                     rootView.backgroundColor = [UIColor yellowColor];
                     [_renderRows addObject:rootView];
                     [self insertSubview:rootView atIndex:i];
                     createdRowCnt ++;
                     //                       NSLog(@" Created row %d out of %ld", createdRowCnt, (long)self.numRenderRows);
                     if (createdRowCnt == self.numRenderRows) {
                       NSLog(@" @@@@@@ ROWS CREATED");
                       rowsAreCreated = YES;
                       if (_horizontal == NO) { // vertical mode
                         if (self.rowHeight <= 0) {
                           RCTLogError(@"RNInfiniteScrollView: We need a rowHeight greater than zero for horizontal={false}. Cur value: %f", self.rowHeight);

                         }
                         if (self.rowWidth > 0) {
                           NSString *warnMsg = @"RNInfiniteScrollView: You don't really have to specify the rowWidth on horizontal={false} mode";
                           RCTLogWarn(@"%@", warnMsg);
                           NSLog(@"%@", warnMsg);
                         }
                         self.contentSize = CGSizeMake(self.frame.size.width, self.rowHeight * (data.count - 1));
                       } else { // horizontal mode
                         if (self.rowWidth <= 0) {
                           RCTLogError(@"RNInfiniteScrollView: We need a rowWidth greater than zero for horizontal mode. Cur value: %f", self.rowWidth);
                           
                         }
                         if (self.rowHeight > 0) {
                           NSString *warnMsg = @"RNInfiniteScrollView: You don't have to specify the rowHeight on horizontal mode";
                           RCTLogWarn(@"%@", warnMsg);
                           NSLog(@"%@", warnMsg);
                         }
                         self.contentSize = CGSizeMake(self.rowWidth * (data.count - 1), self.frame.size.height);
                       }
                       
                       if (_initialPosition != 0) {
                         [self scrollToItemWithIndex:_initialPosition animated:NO];
                       }
                     }
                   });
  }
}

- (void) appendDataToDataSource: (NSArray*) newData {
  if (_firstRowIndex + self.numRenderRows > data.count) { // if we have children rendered above the data count limit
    // we have to update the data props for those children
    for (RCCSyncRootView *view in _renderRows) {
      int viewBindIndex = view.boundToIndex;
      int rowsAfterViewBindIndex = viewBindIndex - (int) data.count;
      if (rowsAfterViewBindIndex >= 0
          && rowsAfterViewBindIndex < newData.count) {
        [view updateProps:@{ @"item": newData[rowsAfterViewBindIndex], @"index": [NSNumber numberWithInt:viewBindIndex]}];
      }
    }
  }
  
  // then insert the new data in the end of our datasource
  [data addObjectsFromArray:newData];
}


- (void) prependDataToDataSource: (NSArray*) newData {
  if (_firstRowIndex < 0) { // if we have children rendered below the current data count
    // we have to update the data props for those children
    for (RCCSyncRootView *view in _renderRows) {
      int viewBindIndex = view.boundToIndex;
      if (viewBindIndex < 0 && fabs(viewBindIndex) <= newData.count) {
        NSLog(@"Now translating data index: %d to newData index: %d", viewBindIndex, (int) newData.count + viewBindIndex);
        [view updateProps:@{ @"item": newData[newData.count + viewBindIndex ], @"index": [NSNumber numberWithInt:viewBindIndex] }];
      }
    }
    _firstRowIndex += newData.count;
  }
  
  // then insert the new data in the beggining of our datasource
  NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange:
                         NSMakeRange(0,[newData count])];
  [data insertObjects:newData atIndexes:indexes];
  
  NSLog(@"### The datasource is now: %@", data);
}

- (void) updateDataAtIndex: (int) rowIndex withNewData: (id) newData {
  if (rowIndex > 0 && rowIndex < data.count) { // if the rowIndex is within our data range
    [data replaceObjectAtIndex:rowIndex withObject:newData];
  }
  
   // if the row index is
  if (rowIndex > _firstRowIndex // above the first rendered index
      && rowIndex < _firstRowIndex + self.numRenderRows) { // and below the last rendered index
    // that means we have to update the view containing that data as well

    for (RCCSyncRootView *view in _renderRows) {
      int viewBindIndex = view.boundToIndex;
      if (viewBindIndex == rowIndex) {
        NSLog(@"Now replacing data at index: %d w/ newData %@", viewBindIndex, newData);
        [view updateProps:@{ @"item": newData, @"index": [NSNumber numberWithInt:viewBindIndex] }];
      }
    }
  }
}

- (void) scrollToItemWithIndex: (int) itemIndex animated: (BOOL) animated {
  if (_horizontal == NO) { // vertical mode
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
  } else { // horizontal mode
    float newOffsetX = itemIndex * self.rowWidth;
    
    if (animated == NO) {
      CGFloat contentWidth = [self contentSize].width;
      CGFloat centerOffsetX = (contentWidth - [self bounds].size.width) / 2.0; // find the center Y point
      
      [self recenterTo: CGPointMake(centerOffsetX, 0) withNewBindingsStartingFrom:[NSNumber numberWithInt:itemIndex]];
      _firstRenderRowOffset = 0;
      _firstRenderRow = 0;
      _firstRowIndex = itemIndex;
    } else {
      [self setContentOffset: CGPointMake(newOffsetX, 0) animated:YES];
    }
  }
}


#pragma mark - UIScrollViewDelegate callbacks

- (void)layoutSubviews {
  [super layoutSubviews];
//  NSLog(@"_firstRenderRowOffset: %f, _firstRenderRow: %d, _firstRowIndex: %d", _firstRenderRowOffset, _firstRenderRow, _firstRowIndex);
  if (![self.loopMode isEqualToString:LOOP_MODE_NONE]) {
    [self recenterIfNecessary];
  }
  [self swapViewsIfNecessary];
}


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

- (void) setHorizontal:(BOOL)horizontal {
  _horizontal = horizontal;
}

@end
