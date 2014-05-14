//
//  EFDataManager.m
//  EFDataModelExample
//
//  Created by Elton Faggett on 5/13/14.
//  Copyright (c) 2014 290 Design, LLC. All rights reserved.
//

#import "EFDataManager.h"
#import "EFDataModel.h"
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
    
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *dbMapFilePath = [bundle pathForResource:@"EFDataModelDatabaseMap" ofType:@"plist"];
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
    EFDataModel *dbModel = [[firstObject class] dbModel];
    return [self saveUsingDatabaseQueue:_databaseQueue items:items dbModel:dbModel];
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

#pragma mark - Private Methods

+ (NSString *)tableForDataType:(NSString *)dataType
{
    NSDictionary *itemMap = [_databaseMap objectForKey:dataType];
    return [itemMap objectForKey:@"table"];
}

+ (NSDictionary *)columnMapForDataType:(NSString *)dataType
{
    NSDictionary *itemMap = [_databaseMap objectForKey:dataType];
    return [itemMap objectForKey:@"columnMap"];
}

+ (NSString *)classNameForDataType:(NSString *)dataType
{
    NSDictionary *itemMap = [_databaseMap objectForKey:dataType];
    return [itemMap objectForKey:@"className"];
}

+ (BOOL)dropIfInvalidForDataType:(NSString *)dataType
{
    NSDictionary *itemMap = [_databaseMap objectForKey:dataType];
    return [[itemMap objectForKey:@"dropIfInvalidSchema"] boolValue];
}

+ (BOOL)validateTableForDBModel:(EFDataModel *)dbModel database:(FMDatabase *)database
{
    if (![database tableExists:dbModel.table]) {
        DDLogWarn(@"Table [%@] does NOT exist for dataType [%@]", dbModel.table, dbModel.dataType);
        return NO;
    } else {
        NSMutableSet *dbColumns = [NSMutableSet new];
        NSMutableSet *primaryKeys = [NSMutableSet new];
        NSString *query = [NSString stringWithFormat:@"PRAGMA table_info('%@')", dbModel.table];
        FMResultSet *rs = [database executeQuery:query];
        while ([rs next]) {
            NSString *column = [rs stringForColumn:@"name"];
            [dbColumns addObject:column];
            NSInteger primaryKeyIndex = [rs intForColumn:@"pk"];
            if (primaryKeyIndex > 0) {
                [primaryKeys addObject:column];
            }
        }
        
        NSSet *modelColumns = [dbModel columns];
        NSSet *modelPrimaryKeys = [dbModel primaryKeys];
        return [modelColumns isSubsetOfSet:dbColumns] && [modelPrimaryKeys isEqualToSet:primaryKeys];
    }
}

+ (BOOL)createTableForDBModel:(EFDataModel *)dbModel object:(id)object database:(FMDatabase *)database
{
    DDLogInfo(@"CREATE_TABLE [%@] for dataType [%@]", dbModel.table, dbModel.dataType);
    NSString *query = [dbModel createTableQueryForModel:object];
    DDLogDebug(@"CREATE_TABLE_QUERY [%@]", query);
    return [database executeUpdate:query];
}

+ (BOOL)dropTableForDBModel:(EFDataModel *)dbModel database:(FMDatabase *)database
{
    DDLogInfo(@"DROP_TABLE [%@] for dataType [%@]", dbModel.table, dbModel.dataType);
    NSString *query = [NSString stringWithFormat:@"DROP TABLE %@", dbModel.table];
    return [database executeUpdate:query];
}

+ (BOOL)saveUsingDatabaseQueue:(FMDatabaseQueue *)databaseQueue items:(NSArray *)items dbModel:(EFDataModel *)dbModel
{
#ifdef DEBUG
	NSDate *time1 = [NSDate date];
#endif
    
    if ([items count] == 0) {
        return YES;
    }
    
    __block BOOL schemaAcceptable = NO;
    if (!dbModel.table) {
        DDLogError(@"ERROR No table defined for dataType [%@]", dbModel.dataType);
        return NO;
    }
    
    [databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        schemaAcceptable = [self validateTableForDBModel:dbModel database:db];
        if (!schemaAcceptable) {
            if ([dbModel dropIfInvalidSchema]) {
                [self dropTableForDBModel:dbModel database:db];
            }
            schemaAcceptable = [self createTableForDBModel:dbModel object:[items firstObject] database:db];
        }
    }];
    
    if (!schemaAcceptable) {
        DDLogError(@"Table schema invalid for dataType [%@]", dbModel.dataType);
        return NO;
    }
    
    __block BOOL success = NO;
    [databaseQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
        NSArray *keys = [dbModel columnKeys];
        for (NSObject *item in items)
        {
            NSParameterAssert([item conformsToProtocol:@protocol(DBModelProtocol)]);
            NSMutableString *query = [NSMutableString stringWithFormat:@"INSERT OR REPLACE INTO %@", dbModel.table];
            NSMutableString *columnMutableString;
            NSMutableString *valueMutableString;
            
            for (NSString *key in keys)
            {
                NSString *column = [dbModel columnForKey:key];
                if (columnMutableString == nil)
                    columnMutableString = [NSMutableString stringWithFormat:@"`%@`", column];
                else
                    [columnMutableString appendFormat:@", `%@`", column];
                
                NSValue *value = [item valueForKey:key];
                NSMutableString *eachValueString;
                if (value != nil && (NSNull *)value != [NSNull null])
                {
                    if ([value isKindOfClass:[NSDate class]])
                    {
                        if (db.hasDateFormatter)
                            eachValueString = [NSMutableString stringWithString:[db stringFromDate:(NSDate *)value]];
                        else
                            eachValueString = [NSMutableString stringWithFormat:@"%f", [(NSDate *)value timeIntervalSince1970]];
                    }
                    else
                        eachValueString = [NSMutableString stringWithFormat:@"%@", value];
                    
                    // Escape single quotes
                    NSRange range = NSMakeRange(0, [eachValueString length]);
                    [eachValueString replaceOccurrencesOfString:@"'" withString:@"''" options:NSCaseInsensitiveSearch range:range];
                }
                else
                {
                    eachValueString = [NSMutableString stringWithString:@""];
                }
                
                if (valueMutableString == nil)
                    valueMutableString = [NSMutableString stringWithFormat:@"'%@'", eachValueString];
                else
                    [valueMutableString appendFormat:@", '%@'", eachValueString];
            }
            
            [query appendFormat:@" (%@) VALUES (%@)", columnMutableString, valueMutableString];
            DDLogVerbose(@"QUERY: %@", query);
            success = [db executeUpdate:query];
            if (!success)
            {
                DDLogError(@"ERROR: SAVE_DATA (%@) failed", dbModel.dataType);
                DDLogError(@"Err %d: %@", [db lastErrorCode], [db lastErrorMessage]);
                *rollback = YES;
                return;
            }
        }
    }];
	
#ifdef DEBUG
	NSDate *time2 = [NSDate date];
	NSTimeInterval elapsedTime1 = [time2 timeIntervalSinceDate:time1];
	DDLogInfo(@"SAVE_DATA (%@): %f seconds | itemCount: %lu", dbModel.dataType, elapsedTime1, (unsigned long)[items count]);
#endif
    
    return YES;
}

@end
