## Description

A Simple way to Bind UI Elements to Data Sources (iOS4+)

Ever had to deal with UITableView sections updating? Or UITableViewCells updating, inserting, reloading, deleting?

With these two classes you shall never fear UITableView updatings anymore! It just manages that for you.

## Example of UITableView updatings

Let's say you need to bind your UITableView content to an external data source. You will then need to reload or update the tableview when the data source changes.

Now let's see how you can do it with MCCSmartGroups. Suppose we have setup a tableview in our view did load callback like so:

```objective-c
- (void)viewDidLoad {
   [super viewDidLoad];
 
   UITableView *tableView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
   [self.view addSubview:[tableView autorelease]];
   
   /* Next steps... ;) */
 }

```

Then let's create a Smart Group that will display a list of names in the tableView (in the "Next steps..."):

```objective-c
// Initialize the names somewhere... 
self.names = [NSMutableArray array];

// Create a smart group
MCCSmartGroup *smartGroup1 = [[[MCCSmartGroup alloc]init]autorelease];
smartGroup1.title = @"Names"; // Section name

smartGroup1.dataBlock = ^id{
  return names; 
};
   
smartGroup1.viewBlock = ^UIView *(NSInteger index, id data) {
  static NSString *identifier1 = @"identifier1";
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier1];
  if (!cell) { cell = [[[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier1]autorelease]; }
  cell.textLabel.text = data;
  return cell;
};
```

We did three things here, first, we created a smart group and set it's section title, then we set the data block of the smart group, which it will call to get its data. And finaly, we set the view block to return a cell for each data entry. Notice that the view block receives two arguments, the index of the view and the data the view needs to present. This data object is not the one returned by the dataBlock, it is the data for __this__ index.

Now let's add this smart group to the tableView. 
To do so, we need an object that knows how to interract with a UITableView, this object is MCCSmartGroupManager.

```objective-c
self.manager = [[[MCCSmartGroupManager alloc]init]autorelease];
[manager addSmartGroup:smartGroup1 inTableView:tableView];
   
tableView.dataSource = manager;
```

Because the tableView dataSource is a weak reference to the manager, we must store the manager as a retained ivar of the controller.

At this point, the names will display in the tableView even if there are no names for the array is still empty. But suppose that at some point in the execution of the application, the names are updated like this:

```objective-c
[names addObject:@"Bar"];
[names insertObject:@"Foo" atIndex:0];
```

Then we would need to tell the smartgroup to update itself like this:

```objective-c
[smartGroup1 processUpdates];
```

Of course, if we did not keep a reference to the smartgroup we can register for a notification in the smartgroup setup:
```objective-c
[[NSNotificationCenter defaultCenter]addObserverForName:@"updateNames" object:nil queue:aQueue usingBlock:^(NSNotification *note) {
  [smartGroup1 processUpdates];
}];
```

And then, later in the application when the updating of names occurs, we may send a notification to trigger the smartgroup update.
```objective-c
[names insertObject:@"Foo" atIndex:0];
[[NSNotificationCenter defaultCenter] postNotificationName:@"updateNames" object:nil];
```

Now, whenever the names change, you just need to tell the corresponding smartGroup to update itself. You may now add 10 different smartgroups to your tableView, they will all handle the updating of their data in the tableView. Notice that if you don't specify a title the section header will not be displayed.

Also note that the MCCSmartGroupManager only roots the tableView data sourcing methods to the right smartgroup. You still need to implement the tableView delegate methods by other means. You may need to subclass MCCSmartGroupManager to provide the unimplemented datasource methods.


## License terms

Copyright (c), 2012 Thierry Passeron

The MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.