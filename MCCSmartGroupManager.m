//
//  MCCSmartGroupManager.h
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

- (NSArray *)smartGroups { return [[smartGroups copy]autorelease]; }

- (MCCSmartGroup *)smartGroupWithTag:(NSUInteger)tag {
  __block MCCSmartGroup *smartGroup = nil;
  [smartGroups enumerateObjectsUsingBlock:^(MCCSmartGroup *s, NSUInteger idx, BOOL *stop) {
    if (s.tag == tag) {
      smartGroup = s;
      *stop = TRUE;
    }
  }];
  return smartGroup;
}

- (BOOL)isEffectiveSmartGroup:(MCCSmartGroup *)smartGroup {
  return [self effectiveIndexOfSmartGroup:smartGroup] != NSNotFound;
}

- (NSInteger)indexOfSmartGroup:(MCCSmartGroup *)smartGroup {
  return [smartGroups indexOfObject:smartGroup];
}

- (NSArray *)effectiveSmartGroups {
  return effectiveSmartGroups;
}

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
    if (([smartGroup numberOfRows] == 0) && smartGroup.shouldHideWhenEmpty) continue;
    [effectiveSmartGroups addObject:smartGroup];
  }
  
  dirty = FALSE;
}

- (void)updateSmartGroup:(MCCSmartGroup*)smartGroup {
#ifdef DEBUG_MCCSmartGroupManager
  NSLog(@"%@ %@ : %@", NSStringFromClass([self class]), NSStringFromSelector(_cmd), smartGroup);
#endif

  if (![NSThread isMainThread]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      [smartGroup processUpdates];
    });
  } else [smartGroup processUpdates];
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

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
  MCCSmartGroup *smartGroup = [self smartGroupAtEffectiveIndex:indexPath.section];
  return smartGroup.editable;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  MCCSmartGroup *smartGroup = [self smartGroupAtEffectiveIndex:indexPath.section];
  return smartGroup.movable;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
  MCCSmartGroup *smartGroup = [self smartGroupAtEffectiveIndex:indexPath.section];
  smartGroup.onCommitEditingStyle(editingStyle, indexPath);
  [self updateSmartGroup:smartGroup];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
  MCCSmartGroup *smartGroup = [self smartGroupAtEffectiveIndex:fromIndexPath.section];
  smartGroup.onMoveRowAtIndexPath(fromIndexPath, toIndexPath);
}



#pragma mark tool method

- (void)hideSmartGroup:(MCCSmartGroup *)smartGroup inTableView:(UITableView *)tableView {
  NSInteger effectiveIndex = [self effectiveIndexOfSmartGroup:smartGroup];
  [effectiveSmartGroups removeObject:smartGroup];
  [smartGroup commitUpdates];
  [tableView deleteSections:[NSIndexSet indexSetWithIndex:effectiveIndex] withRowAnimation:UITableViewRowAnimationTop];
}

- (void)showSmartGroup:(MCCSmartGroup *)smartGroup inTableView:(UITableView *)tableView {
  NSInteger insertIndex = [self effectiveIndexForInsertableSmartGroup:smartGroup];
  [effectiveSmartGroups insertObject:smartGroup atIndex:insertIndex];
  [smartGroup commitUpdates];
  [tableView insertSections:[NSIndexSet indexSetWithIndex:insertIndex] withRowAnimation:UITableViewRowAnimationNone];
}

- (void(^)(NSInteger count, NSIndexSet* reloads, NSIndexSet* removes, NSIndexSet* inserts))buildUITableViewUpdateBlockForTableView:(UITableView *)tableView smartGroup:(MCCSmartGroup*)smartGroup {
  __block typeof(tableView) __tableView = tableView;
  __block typeof(smartGroup) __smartGroup = smartGroup;
  __block typeof(self) __self = self;
  
  return [[^void(NSInteger count, NSIndexSet* reloads, NSIndexSet* removes, NSIndexSet* inserts) {
    if ((count == 0) && __smartGroup.shouldHideWhenEmpty) {
      if ([__self.effectiveSmartGroups indexOfObject:__smartGroup] != NSNotFound) [__self hideSmartGroup:__smartGroup inTableView:__tableView];
      return;
    }
    
    if ([__self.effectiveSmartGroups indexOfObject:__smartGroup] == NSNotFound) {
      [__self showSmartGroup:__smartGroup inTableView:__tableView];
      return;
    }
          
    NSInteger section = [__self effectiveIndexOfSmartGroup:__smartGroup];
    
    if (__smartGroup.debug) { NSLog(@"Will flush updates for smartgroup: %@ at section index: %d", __smartGroup, section); }

    [__smartGroup commitUpdates];
    [__tableView beginUpdates];
    
    if (reloads && reloads.count) {
      if (__smartGroup.debug) { NSLog(@"Flushing reloads for smartgroup %@", __smartGroup); }
      [__tableView reloadRowsAtIndexPaths:indexPathsForSectionWithIndexSet(section, reloads)
                       withRowAnimation:UITableViewRowAnimationNone];
    }
    if (removes && removes.count) {
      if (__smartGroup.debug) { NSLog(@"Flushing deletes for smartgroup %@", __smartGroup); }
      [__tableView deleteRowsAtIndexPaths:indexPathsForSectionWithIndexSet(section, removes)
                       withRowAnimation:UITableViewRowAnimationTop];
    }
    if (inserts && inserts.count) {
      if (__smartGroup.debug) { NSLog(@"Flushing inserts for smartgroup %@", __smartGroup); }
      [__tableView insertRowsAtIndexPaths:indexPathsForSectionWithIndexSet(section, inserts)
                       withRowAnimation:UITableViewRowAnimationNone];
    }
    
    if (__smartGroup.debug) { NSLog(@"Commiting updates for smartgroup %@", __smartGroup); }
    [__tableView endUpdates];
    
    if (__smartGroup.debug) { NSLog(@"Did flush updates for smartgroup %@", __smartGroup); }
  } copy]autorelease];
}

@end
