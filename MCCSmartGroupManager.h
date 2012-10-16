//
//  MCCSmartGroupManager.h
//
//  Created by Thierry Passeron on 14/09/12.
//  Copyright (c) 2012 Monte-Carlo Computing. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCCSmartGroup.h"

@interface MCCSmartGroupManager : NSObject

- (NSArray *)smartGroups;
- (MCCSmartGroup *)smartGroupWithTag:(NSUInteger)tag;
- (NSInteger)indexOfSmartGroup:(MCCSmartGroup *)smartGroup;

- (NSArray *)effectiveSmartGroups;
- (BOOL)isEffectiveSmartGroup:(MCCSmartGroup *)smartGroup;
- (NSInteger)effectiveIndexOfSmartGroup:(MCCSmartGroup *)smartGroup;
- (NSUInteger)effectiveSmartGroupsCount;
- (MCCSmartGroup *)smartGroupAtEffectiveIndex:(NSUInteger)index;

- (void)addSmartGroup:(MCCSmartGroup*)smartGroup;

- (void)reload; /* force a reload of smartGroups. Note: no need to do it when attached to a tableView. */

@end

@interface MCCSmartGroupManager (UITableView) <UITableViewDataSource>

- (void)addSmartGroup:(MCCSmartGroup*)smartGroup inTableView:(UITableView *)aTableView;

@end
