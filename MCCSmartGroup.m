//
//  MCCSmartGroup.m
//  MCCSmartGroupDemo
//
//  Created by Thierry Passeron on 14/09/12.
//  Copyright (c) 2012 Monte-Carlo Computing. All rights reserved.
//

#import "MCCSmartGroup.h"

@interface MCCSmartGroup ()
@property (assign, nonatomic) BOOL cached;

@property (retain, nonatomic) id data;
@property (retain, nonatomic) id pendingData;
@property (assign, nonatomic) NSUInteger count;
@property (assign, nonatomic) NSUInteger pendingCount;

@property (retain, nonatomic) NSArray *visibleIndexes;
@property (retain, nonatomic) NSArray *pendingVisibleIndexes;

@property (retain, nonatomic) NSIndexSet *reloadIndexes;
@property (retain, nonatomic) NSIndexSet *removeIndexes;
@property (retain, nonatomic) NSIndexSet *insertIndexes;

@end

@implementation MCCSmartGroup
@synthesize viewBlock, dataBlock, onUpdate, title;
@synthesize data, cached, count, reloadIndexes, removeIndexes, insertIndexes, visibleIndexes, pendingCount, pendingData, pendingVisibleIndexes, shouldHideWhenEmpty;

- (id)init {
  self = [super init];
  if (!self) return nil;
  return self;
}

- (void)dealloc {
  self.title = nil;
  self.data = nil;
  self.pendingData = nil;
  self.viewBlock = nil;
  self.dataBlock = nil;
  self.onUpdate = nil;
  
  self.reloadIndexes = nil;
  self.removeIndexes = nil;
  self.insertIndexes = nil;
  
  self.visibleIndexes = nil;
  self.pendingVisibleIndexes = nil;

  [super dealloc];
}

- (void)processUpdates {
  cached = FALSE;
  [self cacheData];
  
  onUpdate(self.pendingData ? pendingCount : count, reloadIndexes, removeIndexes, insertIndexes);
}

- (void)cacheData {
  NSAssert(dataBlock, @"no data block");
  if (cached) return;
  
  id oldData = [[data copy]autorelease];
  id newData = [[dataBlock() copy]autorelease];
  
  NSAssert(newData, @"dataBlock must return an object. Empty or not.");
  
  // Make the diff
  NSIndexSet *reloads = nil;
  NSIndexSet *removes = nil;
  NSIndexSet *inserts = nil;
  
  NSInteger oldCount = self.count;
  
  NSInteger _count = [self diffFromData:oldData toData:newData reloads:&reloads removes:&removes inserts:&inserts];
  if (!data) { // t0 (the first time the smartGroup is queried)
    self.count = _count;
    self.data = newData;
    if ([data isKindOfClass:[NSDictionary class]]) {
      self.visibleIndexes = [self visibleIndexesForDictionaryData:newData];
    } else self.visibleIndexes = nil;
  } else { // An update
    self.pendingCount = _count;
    self.pendingData = newData;
    if ([data isKindOfClass:[NSDictionary class]]) {
      self.pendingVisibleIndexes = [self visibleIndexesForDictionaryData:newData];
    } else self.pendingVisibleIndexes = nil;
  }
  
  self.reloadIndexes = reloads;
  self.removeIndexes = removes;
  self.insertIndexes = inserts;
  
  NSAssert(oldCount + inserts.count - removes.count == _count, @"oups!");
  
  cached = TRUE;
}

- (void)commitUpdates {
  self.count = pendingCount;
  self.data = pendingData;
  self.visibleIndexes = pendingVisibleIndexes;
  
  self.pendingCount = 0;
  self.pendingData = nil;
  self.pendingVisibleIndexes = nil;
}

- (NSUInteger)countForData:(id)aData {
  if ([aData isKindOfClass:[NSDictionary class]]) {
    return [(NSDictionary*)aData allKeys].count;
  }
  
  NSAssert([aData isKindOfClass:[NSArray class]], @"Only manage NSArray and NSDictionary");
  return [aData count];
}


#pragma mark indexSets

- (NSArray *)visibleIndexesForDictionaryData:(NSDictionary *)aData {
  return [[aData allKeys]sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
    return [(NSNumber *)obj1 integerValue] > [(NSNumber *)obj2 integerValue] ? NSOrderedDescending : NSOrderedAscending;
  }];
}

#pragma mark Diff

- (NSInteger)diffFromData:(id)oldData toData:(id)newData reloads:(NSIndexSet **)reloads removes:(NSIndexSet **)removes inserts:(NSIndexSet **)inserts {
  if (!oldData) {
    NSInteger _count = [self countForData:newData];
    *inserts = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _count)];
    return _count;
  }
  
  if (!newData) {
    NSInteger _count = [self countForData:oldData];
    *removes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, _count)];
    return _count;
  }
  
  NSAssert([oldData class] == [newData class], @"mutating data type is not allowed");
  
  NSInteger _count = [self countForData:newData];
  
  // Now let's do the diffs
  NSMutableIndexSet *toRemove = [[NSMutableIndexSet alloc]init];
  NSMutableIndexSet *toInsert = [[NSMutableIndexSet alloc]init];
  NSMutableIndexSet *toReload = [[NSMutableIndexSet alloc]init];

  if ([oldData isKindOfClass:[NSDictionary class]]) {
    NSSet *previousSet = [NSSet setWithArray:[oldData allKeys]];
    NSSet *newSet = [NSSet setWithArray:[newData allKeys]];

    NSMutableSet *addedSet = [[newSet mutableCopy]autorelease];
    [addedSet minusSet:previousSet];
    
    NSMutableSet *removedSet = [[previousSet mutableCopy]autorelease];
    [removedSet minusSet:newSet];

    NSMutableSet *remainingSet = [[newSet mutableCopy]autorelease];
    [remainingSet intersectSet:previousSet];
    
    
    [remainingSet enumerateObjectsUsingBlock:^(NSNumber *index, BOOL *stop){
      if (![[oldData objectForKey:index] isEqual:[newData objectForKey:index]]) {
        [toReload addIndex:[index integerValue]];
      }
    }];
    
    [removedSet enumerateObjectsUsingBlock:^(NSNumber *index, BOOL *stop){
      [toRemove addIndex:[index integerValue]];
    }];
    
    [addedSet enumerateObjectsUsingBlock:^(NSNumber *index, BOOL *stop){
      [toInsert addIndex:[index integerValue]];
    }];
    
    
    *reloads = [toReload autorelease];
    *removes = [toRemove autorelease];
    *inserts = [toInsert autorelease];

    return _count;
  }

  NSAssert([oldData isKindOfClass:[NSArray class]], @"Only manage NSArray and NSDictionary");
  
  NSSet *previousSet = [NSSet setWithArray:oldData];
  NSSet *newSet = [NSSet setWithArray:newData];

  NSMutableSet *addedSet = [[newSet mutableCopy]autorelease];
  [addedSet minusSet:previousSet];
  NSMutableSet *removedSet = [[previousSet mutableCopy]autorelease];
  [removedSet minusSet:newSet];
      
  [removedSet enumerateObjectsUsingBlock:^(id object, BOOL *stop){
    [toRemove addIndex:[oldData indexOfObject:object]];
  }];
  
  [addedSet enumerateObjectsUsingBlock:^(id object, BOOL *stop){
    [toInsert addIndex:[newData indexOfObject:object]];
  }];
  
  *reloads = [toReload autorelease];
  *removes = [toRemove autorelease];
  *inserts = [toInsert autorelease];
  
  return _count;
}

- (NSInteger)numberOfRows {
  if (!cached) [self cacheData];
  return count;
}

- (id)dataForRowAtIndex:(NSInteger)rowIndex {
  if ([data isKindOfClass:[NSDictionary class]]) {
    return [data objectForKey:[NSNumber numberWithInt:rowIndex]];
  }
  
  return [data objectAtIndex:rowIndex];
}

- (id)viewForRowAtIndex:(NSInteger)rowIndex {
  if (!cached) [self cacheData];
  NSAssert(viewBlock, @"no view block");
  NSInteger realIndex = visibleIndexes ? [[visibleIndexes objectAtIndex:rowIndex]integerValue] : rowIndex;
  return viewBlock(realIndex, [self dataForRowAtIndex:realIndex]);
}

@end
