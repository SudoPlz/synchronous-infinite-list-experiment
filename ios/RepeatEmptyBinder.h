//
//  RepeatEmptyBinder.h
//  example
//
//  Created by John Kokkinidis on 12/09/2017.
//  Copyright © 2017 Facebook. All rights reserved.
//

#import "ScrollViewBindFactory.h"

@interface RepeatEmptyBinder : ScrollViewBindFactory
- (NSDictionary*) getValueForRow: (int)rowIndex andDatasource: (NSMutableArray*) data;
@end
