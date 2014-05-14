//
//  EFDataManager.m
//  EFDataModelExample
//
//  Created by Elton Faggett on 5/13/14.
//  Copyright (c) 2014 290 Design, LLC. All rights reserved.
//

#import "EFDataManager.h"
#import "EFDataModel.h"
#import "EFDataDBHelper.h"
#import "FMDB.h"
#import "DDLog.h"

static const int ddLogLevel = LOG_LEVEL_VERBOSE;

static FMDatabaseQueue *_databaseQueue;
static NSDictionary *_databaseMap;

@implementation EFDataManager

#pragma mark - Initialization

+ (void)initialize
{
    [super initialize];
    
    NSString *dbMapFilePath = [[NSBundle mainBundle] pathForResource:@"EFDataModelDatabaseMap" ofType:@"plist"];
    _databaseMap = [NSDictionary dictionaryWithContentsOfFile:dbMapFilePath];
    
//    NSString * dbFilePath = [self databaseFilePathWithFileName:@"EFDataDB.sqlite"];
//    _databaseQueue = [FMDatabaseQueue databaseQueueWithPath:dbFilePath];
}

+ (void)setDatabaseName:(NSString *)databaseName
{
    if (_databaseQueue) {
        [_databaseQueue close];
    }
    NSString *dbFilePath = [self databaseFilePathWithFileName:databaseName];
    _databaseQueue = [FMDatabaseQueue databaseQueueWithPath:dbFilePath];
}

+ (void)setDatabaseMap:(NSDictionary *)databaseMap
{
    _databaseMap = databaseMap;
}

+ (BOOL)deleteDatabaseWitName:(NSString *)databaseName
{
    BOOL deleteSuccess;
    NSString *filePath = [self databaseFilePathWithFileName:databaseName];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSError *error = nil;
        deleteSuccess = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (!deleteSuccess) {
            DDLogError(@"ERROR: Failed to delete data: %@", filePath);
        }
    } else {
        deleteSuccess = YES;
        DDLogVerbose(@"Nothing to delete. No file exists at: %@", filePath);
    }
    
    return deleteSuccess;
}

+ (NSString *)databaseFilePathWithFileName:(NSString *)fileName
{
    if (fileName == nil)
    {
        DDLogError(@"databaseFilePathWithFileName called with nil file name");
        return nil;
    }
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:fileName];
    
	DDLogVerbose(@"File path (%@): %@", fileName, filePath);
    
    return filePath;
}

+ (FMDatabaseQueue *)databaseQueue
{
    return _databaseQueue;
}

+ (void)logLastError:(FMDatabase *)db
{
    NSString *errMessage = [NSString stringWithFormat:@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]];
    DDLogError(@"%@", errMessage);
}

#pragma mark - Save Data

+ (BOOL)saveItems:(NSArray *)items
{
    id <DBModelProtocol> firstObject = [items firstObject];
    NSString *dataType = [[firstObject class] dbModelDataType];
    return [EFDataDBHelper saveUsingDatabaseQueue:_databaseQueue items:items dataType:dataType];
}

#pragma mark - Retrieve Data

+ (NSArray *)itemsWithDBModel:(EFDataModel *)dbModel criteria:(NSString *)criteria arguments:(NSArray *)arguments
{
    NSMutableString *query = [NSMutableString stringWithFormat:@"SELECT * FROM %@ WHERE %@", dbModel.table, [criteria length] > 0 ? criteria : @"1"];
    return [self itemsWithDataType:dbModel.dataType query:query arguments:arguments];
}

+ (NSArray *)itemsWithDataType:(NSString *)dataType query:(NSString *)query arguments:(NSArray *)arguments
{
    __block NSMutableArray *result = [NSMutableArray new];
    [_databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:query withArgumentsInArray:arguments];
        
        if ([db hadError]) {
            [self logLastError:db];
            return;
        }
        
        while ([rs next]) {
            id item = [self itemWithDataType:dataType fromResultSet:rs];
            if (item)
                [result addObject:item];
        }
    }];
    return result;
}

+ (id)itemWithDataType:(NSString *)dataType query:(NSString *)query arguments:(NSArray *)arguments
{
    __block id item;
    [_databaseQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *rs = [db executeQuery:query withArgumentsInArray:arguments];
        
        if ([db hadError]) {
            [self logLastError:db];
            return;
        }
        
        if ([rs next]) {
            item = [self itemWithDataType:dataType fromResultSet:rs];
        }
        
        [rs close];
    }];
    return item;
}

+ (id)itemWithDataType:(NSString *)dataType fromResultSet:(FMResultSet *)rs
{
    EFDataModel *dbModel = [EFDataModel modelForDataType:dataType];
    Class class = [dbModel classForDBModelObject];
    id item = [class new];
    [dbModel setValuesOnTarget:item fromResultSet:rs];
    
    return item;
}

@end
