//
//  EFSampleItem1TableViewController.m
//  EFDataModelExample
//
//  Created by Elton Faggett on 5/13/14.
//  Copyright (c) 2014 290 Design, LLC. All rights reserved.
//

#import "EFSampleItem1TableViewController.h"
#import "EFDataManager.h"
#import "EFSampleItem1.h"

@interface EFSampleItem1TableViewController ()

@property (nonatomic, strong) NSArray *sampleItems;

@end

@implementation EFSampleItem1TableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addSampleItem:)];
    self.navigationItem.rightBarButtonItem = addButton;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self refreshView];
}

- (void)refreshView
{
    //    self.sampleItems = [self itemsWithPrimaryKey1:1 primaryKey2:2 primaryKey3:3];
    self.sampleItems = [self allItems];
    [self.tableView reloadData];
}

- (void)addSampleItem:(id)sender
{
    NSInteger primaryKey1 = [self randomIntegerFrom:0 to:1000];
    NSInteger primaryKey2 = [self randomIntegerFrom:1001 to:2000];
    NSInteger primaryKey3 = [self randomIntegerFrom:2001 to:3000];
    EFSampleItem1 *sampleItem = [[EFSampleItem1 alloc] initWithPrimaryKey1:primaryKey1 primaryKey2:primaryKey2 primaryKey3:primaryKey3];
    sampleItem.stringValue = [self randomText];
    sampleItem.doubleValue = [self randomIntegerFrom:0 to:1000] + drand48();
    sampleItem.integerValue = [self randomIntegerFrom:0 to:1000];
    sampleItem.boolValue = [self randomBool];
    sampleItem.dateValue = [self randomDate];
    [EFDataManager saveItems:@[sampleItem]];
    
    [self refreshView];
}

- (NSString *)randomText
{
    return [NSString stringWithFormat:@"text: %0.f", [self randomIntegerFrom:0 to:1000]];
}

- (NSDate *)randomDate
{
    return [NSDate dateWithTimeIntervalSinceNow:[self randomIntegerFrom:0 to:10000]];
}

- (CGFloat)randomIntegerFrom:(NSInteger)from to:(NSInteger)to
{
    //    return (arc4random() % to) + from;
    return (arc4random() % (to - from)) + from;
}

- (BOOL)randomBool
{
    NSInteger number = [self randomIntegerFrom:0 to:2];
    return [[NSNumber numberWithInteger:number] boolValue];
}

- (NSArray *)itemsWithPrimaryKey1:(NSInteger)primaryKey1 primaryKey2:(NSInteger)primaryKey2 primaryKey3:(NSInteger)primaryKey3
{
    EFDataModel *dbModel = [EFDataModel modelWithTable:[EFSampleItem1 tableName] primaryKeys:[EFSampleItem1 primaryKeys] columnMap:[EFSampleItem1 databaseColumnsByPropertyKey]];
    NSMutableString *criteria = [NSMutableString stringWithFormat:@"%@ = ? AND %@ = ? AND %@ = ?",
                                 [dbModel columnForKey:@"primaryKeyPart1"], [dbModel columnForKey:@"primaryKeyPart2"], [dbModel columnForKey:@"primaryKeyPart3"]];
    NSArray *arguments = @[@(primaryKey1), @(primaryKey2), @(primaryKey3)];
    return [EFDataManager itemsWithClass:[EFSampleItem1 class] criteria:criteria arguments:arguments];
}

- (NSArray *)allItems
{
    return [EFDataManager itemsWithClass:[EFSampleItem1 class] criteria:nil arguments:nil];
}

#pragma mark - Table view data source

- (EFSampleItem1 *)itemAtIndexPath:(NSIndexPath *)indexPath
{
    return self.sampleItems[indexPath.row];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.sampleItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SampleItemCell" forIndexPath:indexPath];
    
    // Configure the cell...
    EFSampleItem1 *item = [self itemAtIndexPath:indexPath];
    cell.textLabel.text = [NSString stringWithFormat:@"key1 [%ld], key2 [%ld], key3 [%ld]", (long)item.primaryKeyPart1, (long)item.primaryKeyPart2, (long)item.primaryKeyPart3];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"s [%@], i [%ld], b [%@], d [%@]", item.stringValue, (long)item.integerValue, item.boolValue ? @"YES" : @"NO", item.dateValue];
    
    return cell;
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
