//
//  EFDataModelTests.m
//  EFDataModelTests
//
//  Created by Elton Faggett on 5/13/14.
//  Copyright (c) 2014 290 Design, LLC. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "EFDataModel.h"
#import "EFDataManager.h"
#import "EFTestItem1.h"
#import "FMDB.h"

#define EXP_SHORTHAND
#import "Expecta.h"

#define TEST_DB @"testDB.sqlite"

@interface EFDataModelTests : XCTestCase

@end

@implementation EFDataModelTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    NSString *dbName = TEST_DB;
    [EFDataManager setDatabaseName:dbName];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    
    [EFDataManager deleteDatabaseWitName:TEST_DB];
    
    [super tearDown];
}

- (void)testSave
{
    EFTestItem1 *item = [self createSampleItem];
    EFDataModel *dbModel = [EFDataModel modelWithClass:[EFTestItem1 class]];
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@", dbModel.table];
    __block NSInteger count1;
    [[EFDataManager databaseQueue] inDatabase:^(FMDatabase *db) {
        count1 = [db intForQuery:query];
    }];
    [EFDataManager saveItems:@[item]];
    
    __block NSInteger count2;
    [[EFDataManager databaseQueue] inDatabase:^(FMDatabase *db) {
        count2 = [db intForQuery:query];
    }];
    
    expect(count1).to.beLessThan(count2);
}

- (void)testDeleteDatabase
{
    NSString *testFile = @"testfile.db";
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *file = [documentsDirectory stringByAppendingPathComponent:testFile];
    [[NSData data] writeToFile:file options:NSDataWritingAtomic error:nil];
    
    expect([self fileExists:testFile]).to.equal(YES);
    
    [EFDataManager deleteDatabaseWitName:testFile];
    
    expect([self fileExists:testFile]).to.equal(NO);
}

#pragma mark - Private Helpers

- (BOOL)fileExists:(NSString *)fileName
{
    NSString *filePath = [self filePathWithFileName:fileName];
    return [[NSFileManager defaultManager] fileExistsAtPath:filePath];
}

- (NSString *)filePathWithFileName:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    return filePath;
}

- (EFTestItem1 *)createSampleItem
{
    NSInteger primaryKey1 = [self randomIntegerFrom:0 to:1000];
    NSInteger primaryKey2 = [self randomIntegerFrom:1001 to:2000];
    NSInteger primaryKey3 = [self randomIntegerFrom:2001 to:3000];
    EFTestItem1 *sampleItem = [[EFTestItem1 alloc] initWithPrimaryKey1:primaryKey1 primaryKey2:primaryKey2 primaryKey3:primaryKey3];
    sampleItem.stringValue = [self randomText];
    sampleItem.doubleValue = [self randomIntegerFrom:0 to:1000] + drand48();
    sampleItem.integerValue = [self randomIntegerFrom:0 to:1000];
    sampleItem.boolValue = [self randomBool];
    sampleItem.dateValue = [self randomDate];
    
    return sampleItem;
}

- (NSString *)randomText
{
    return [NSString stringWithFormat:@"text: %0.f", [self randomIntegerFrom:0 to:1000]];
}

- (NSDate *)randomDate
{
    return [NSDate dateWithTimeIntervalSinceNow:[self randomIntegerFrom:0 to:10000]];
}

- (BOOL)randomBool
{
    NSInteger number = [self randomIntegerFrom:0 to:2];
    return [[NSNumber numberWithInteger:number] boolValue];
}

- (CGFloat)randomIntegerFrom:(NSInteger)from to:(NSInteger)to
{
    //    return (arc4random() % to) + from;
    return (arc4random() % (to - from)) + from;
}

- (NSArray *)itemsWithPrimaryKey1:(NSInteger)primaryKey1 primaryKey2:(NSInteger)primaryKey2 primaryKey3:(NSInteger)primaryKey3
{
    EFDataModel *dbModel = [EFDataModel modelWithClass:[EFTestItem1 class]];
    NSMutableString *criteria = [NSMutableString stringWithFormat:@"%@ = ? AND %@ = ? AND %@ = ?",
                                 [dbModel columnForKey:@"primaryKeyPart1"], [dbModel columnForKey:@"primaryKeyPart2"], [dbModel columnForKey:@"primaryKeyPart3"]];
    NSArray *arguments = @[@(primaryKey1), @(primaryKey2), @(primaryKey3)];
    return [EFDataManager itemsWithClass:[EFTestItem1 class] criteria:criteria arguments:arguments];
}

- (NSArray *)allItems
{
    return [EFDataManager itemsWithClass:[EFTestItem1 class] criteria:nil arguments:nil];
}

@end
