//
//  MCCSmartGroupDelegate.m
//  MCCSmartGroupDemo
//
//  Created by Thierry Passeron on 14/09/12.
//  Copyright (c) 2012 Monte-Carlo Computing. All rights reserved.
//

#import "MCCSmartGroupManager.h"

NS_INLINE NSArray *indexPathsForSectionWithIndexSet(NSInteger section, NSIndexSet *indexSet) {
  NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:indexSet.count];
  [indexSet enumerateIndexesUsingBlock:^(NSUInteger row, BOOL *stop){
    [indexPaths addObject:[NSIndexPath indexPathForRow:row inSection:section]];
  }];
  return indexPaths;
}

@interface MCCSmartGroupManager ()
@property (assign, nonatomic) BOOL dirty;
@property (retain, nonatomic) NSMutableArray *smartGroups;
@property (retain, nonatomic) NSMutableArray *effectiveSmartGroups;
@end

@implementation MCCSmartGroupManager
@synthesize smartGroups, effectiveSmartGroups, dirty;

- (id)init {
  self = [super init];
  if (!self) return nil;
  self.effectiveSmartGroups = [NSMutableArray array];
  self.smartGroups = [NSMutableArray array];
  self.dirty = TRUE;
  return self;
}

- (void)dealloc {
  self.effectiveSmartGroups = nil;
  self.smartGroups = nil;
  [super dealloc];
}


#pragma mark query and manage SmartGroups

- (NSUInteger)effectiveSmartGroupsCount {
  return effectiveSmartGroups.count;
}

- (MCCSmartGroup *)smartGroupAtEffectiveIndex:(NSUInteger)index {
  return [effectiveSmartGroups objectAtIndex:index];
}

- (NSInteger)effectiveIndexOfSmartGroup:(MCCSmartGroup *)smartGroup {
  return [effectiveSmartGroups indexOfObject:smartGroup];
}

- (void)addSmartGroup:(MCCSmartGroup*)smartGroup {
  [smartGroups addObject:smartGroup];
  dirty = TRUE;
}

- (NSInteger)effectiveIndexForInsertableSmartGroup:(MCCSmartGroup*)smartGroup {
  NSInteger index = [smartGroups indexOfObject:smartGroup];
  __block NSInteger insertIndex = 0;
  
  // Get the target index
  [effectiveSmartGroups enumerateObjectsUsingBlock:^(NSNumber *obj, NSUInteger idx, BOOL *stop) {
    NSInteger objIndex = [smartGroups indexOfObject:obj];
    if (objIndex >= index) { *stop = YES; return; }
    insertIndex = idx + 1;
  }];
  
  return insertIndex;
}

- (void)addSmartGroup:(MCCSmartGroup*)smartGroup inTableView:(UITableView *)aTableView {
  [self addSmartGroup:smartGroup];
  smartGroup.onUpdate = [self buildUITableViewUpdateBlockForTableView:aTableView smartGroup:smartGroup];
}


- (void)reload {
  if (!dirty) return;
  [effectiveSmartGroups removeAllObjects];
  
  for (MCCSmartGroup *smartGroup in smartGroups) {
    if ([smartGroup numberOfRows] == 0) continue;
    [effectiveSmartGroups addObject:smartGroup];
  }
  
  dirty = FALSE;
}



#pragma mark UITableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  if (dirty) [self reload];
  return [self effectiveSmartGroupsCount];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  MCCSmartGroup *smartGroup = [self smartGroupAtEffectiveIndex:section];
  return [smartGroup numberOfRows];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  MCCSmartGroup *smartGroup = [self smartGroupAtEffectiveIndex:indexPath.section];
  return [smartGroup viewForRowAtIndex:indexPath.row];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  MCCSmartGroup *smartGroup = [self smartGroupAtEffectiveIndex:section];
  return smartGroup.title;
}



#pragma mark tool method

- (void)hideSmartGroup:(MCCSmartGroup *)smartGroup inTableView:(UITableView *)tableView {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSInteger effectiveIndex = [self effectiveIndexOfSmartGroup:smartGroup];
    [effectiveSmartGroups removeObject:smartGroup];
    [smartGroup commitUpdates];
    [tableView deleteSections:[NSIndexSet indexSetWithIndex:effectiveIndex] withRowAnimation:UITableViewRowAnimationTop];
  });
}

- (NSInteger)showSmartGroup:(MCCSmartGroup *)smartGroup inTableView:(UITableView *)tableView {
  dispatch_async(dispatch_get_main_queue(), ^{
    NSInteger insertIndex = [self effectiveIndexForInsertableSmartGroup:smartGroup];
    [effectiveSmartGroups insertObject:smartGroup atIndex:insertIndex];
    [smartGroup commitUpdates];
    [tableView insertSections:[NSIndexSet indexSetWithIndex:insertIndex] withRowAnimation:UITableViewRowAnimationTop];
  });
  
  return 0;
}

- (void(^)(NSInteger count, NSIndexSet* reloads, NSIndexSet* removes, NSIndexSet* inserts))buildUITableViewUpdateBlockForTableView:(UITableView *)tableView smartGroup:(MCCSmartGroup*)smartGroup {
  return [[^void(NSInteger count, NSIndexSet* reloads, NSIndexSet* removes, NSIndexSet* inserts) {
    if (count == 0 && smartGroup.shouldHideWhenEmpty) {
      if ([effectiveSmartGroups indexOfObject:smartGroup] != NSNotFound) [self hideSmartGroup:smartGroup inTableView:tableView];
      return;
    }
    
    if ([effectiveSmartGroups indexOfObject:smartGroup] == NSNotFound) {
      [self showSmartGroup:smartGroup inTableView:tableView];
      return;
    }
          
    dispatch_async(dispatch_get_main_queue(), ^{
      NSInteger section = [self effectiveIndexOfSmartGroup:smartGroup];
      [smartGroup commitUpdates];

      [tableView beginUpdates];
      
      if (reloads && reloads.count) {
        [tableView reloadRowsAtIndexPaths:indexPathsForSectionWithIndexSet(section, reloads)
                         withRowAnimation:UITableViewRowAnimationFade];
      }
      if (removes && removes.count) {
        [tableView deleteRowsAtIndexPaths:indexPathsForSectionWithIndexSet(section, removes)
                         withRowAnimation:UITableViewRowAnimationTop];
      }
      if (inserts && inserts.count) {
        [tableView insertRowsAtIndexPaths:indexPathsForSectionWithIndexSet(section, inserts)
                         withRowAnimation:UITableViewRowAnimationTop];
      }
      
      [tableView endUpdates];
    });
  } copy]autorelease];
}

@end
