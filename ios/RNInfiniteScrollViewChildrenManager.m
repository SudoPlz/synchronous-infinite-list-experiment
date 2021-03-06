//
//  TableViewChildren.m
//  example
//
//  Created by Tal Kol on 6/8/16.
//  Copyright © 2016 Facebook. All rights reserved.
//

#import "RNInfiniteScrollViewChildrenManager.h"

@implementation RNInfiniteScrollViewChildrenManager

RCT_EXPORT_MODULE()

- (UIView *)view
{
  _scrollView = [[RNInfiniteScrollViewChildren alloc] initWithBridge:self.bridge];
//  [_scrollView setFrame:CGRectMake(0, 0, 960, 1132)];
  return _scrollView;
}

RCT_EXPORT_VIEW_PROPERTY(rowHeight, float)
RCT_EXPORT_VIEW_PROPERTY(rowWidth, float)
RCT_EXPORT_VIEW_PROPERTY(numRenderRows, NSInteger)
RCT_EXPORT_VIEW_PROPERTY(loopMode, NSString)
RCT_EXPORT_VIEW_PROPERTY(data, NSArray)
RCT_EXPORT_VIEW_PROPERTY(initialPosition, int)
RCT_EXPORT_VIEW_PROPERTY(horizontal, BOOL)
RCT_EXPORT_VIEW_PROPERTY(paging, BOOL)
RCT_EXPORT_VIEW_PROPERTY(dynamicViewSizes, BOOL)

RCT_EXPORT_METHOD(prepareRows)
{
  [_scrollView createRows];
}

RCT_EXPORT_METHOD(appendDataToDataSource: (NSArray *) newData) {
  [_scrollView appendDataToDataSource:newData];
}

RCT_EXPORT_METHOD(prependDataToDataSource: (NSArray *) newData) {
  [_scrollView prependDataToDataSource:newData];
}

RCT_EXPORT_METHOD(updateDataAtIndex: (int) rowIndex withNewData: (id) newData) {
  [_scrollView updateDataAtIndex:rowIndex withNewData:newData];
}

RCT_EXPORT_METHOD(setScrollerZoom: (float) zoomScale animated: (BOOL) animated) {
  [_scrollView setScrollerZoom:zoomScale animated:animated];
}


@end
