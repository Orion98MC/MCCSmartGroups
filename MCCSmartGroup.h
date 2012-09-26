//
//  MCCSmartGroup.h
//  MCCSmartGroupDemo
//
//  Created by Thierry Passeron on 14/09/12.
//  Copyright (c) 2012 Monte-Carlo Computing. All rights reserved.
//

/*
 
  A SmartGroup is a group of Views bound to a datasource that may dynamically change
 
  You may use it to create complex UITableViews with different sections that can respond to datasources changes and reload/delete/insert rows accordingly
  The best way to do that is to add smartGroups to a SmartGroup manager (MCCSmartGroupManager) and then set the manager as the tableView datasource.
 
 Example:
 
 - (void)viewDidLoad {
   [super viewDidLoad];
 
   UITableView *tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
   [self.view addSubview:[tableView autorelease]];
 
   self.manager = [[[MCCSmartGroupManager alloc]init]autorelease];
   
   self.smartGroup1 = [[[MCCSmartGroup alloc]init]autorelease];
   smartGroup1.title = @"Names"; // Section name
   smartGroup1.dataBlock = ^id{
     return names; // A names ivar (NSMutableArray*) in the controller that stores ... names :)
   };
   
   smartGroup1.viewBlock = ^UIView *(NSInteger index, id data) {
     static NSString *identifier1 = @"identifier1";
     UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier1];
     if (!cell) { cell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier1]autorelease]; }
     cell.textLabel.text = data;
     return cell;
   };
   smartGroup1.shouldHideWhenEmpty = TRUE;
 
   [manager addSmartGroup:smartGroup1 inTableView:tableView];
   
   tableView.dataSource = manager;
 }
 
 // Later on... somewhere in the controller code ...
 
 [names removeObject:@"Homer"];
 [names insertObject:@"Barth" atIndex:0];
 [smartGroup1 processUpdates]; 
 
 // At this point the new data is analysed and the futur inserts/deletes/reloads are stores, 
 // then the onUpdate block automatically created by the manager is run and commits the updates before animating the tableview inserts and deletes

 
 */

#import <Foundation/Foundation.h>

@interface MCCSmartGroup : NSObject

#pragma mark mandatory settings
@property (copy, nonatomic) UIView*(^viewBlock)(NSInteger rowIndex, id rowData); /* Return a view for the row and data */
@property (copy, nonatomic) id(^dataBlock)(void); /* If nil is returned, the row is assumed empty and thus will not be visible. 
                                                   If you wish to show an empty row, return [NSNull null] and check for it in the viewBlock */
@property (copy, nonatomic) void(^onUpdate)(NSInteger count, NSIndexSet* reloads, NSIndexSet* removes, NSIndexSet* inserts); /* called when an update has been triggered. If you add the group to manager (MCCSmartGroupManager*) with the method - (void)addSmartGroup:(MCCSmartGroup*)smartGroup inTableView:(UITableView *)aTableView; it will automatically create the onUpdate callback to update the tableView with the changes */

#pragma mark optional settings
@property (retain, nonatomic) NSString *title; /* name of the section, used in the context of a UITableView */
@property (assign, nonatomic) BOOL shouldHideWhenEmpty; /* used by the SmartGroup manager to determine if it should show an empty group or hide it in the context of a UITableView */

#pragma mark query the smartGroup
- (NSInteger)numberOfRows;
- (id)viewForRowAtIndex:(NSInteger)rowIndex;

#pragma mark smartGroup updating
- (void)processUpdates; /* reprocesses the data returned by the dataBlock and sets pending updates. A commit is needed in order to set the pending updates effective */
- (void)commitUpdates; /* commit the pending updates */
@end
