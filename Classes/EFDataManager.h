//
//  EFDataManager.h
//  EFDataModelExample
//
//  Created by Elton Faggett on 5/13/14.
//  Copyright (c) 2014 290 Design, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EFDataModel;
@class FMDatabaseQueue;
@protocol DBModelProtocol;
@interface EFDataManager : NSObject

+ (FMDatabaseQueue *)databaseQueue;
+ (void)setDatabaseName:(NSString *)databaseName;
+ (BOOL)deleteDatabaseWitName:(NSString *)databaseName;

#pragma mark - Save
+ (BOOL)saveItems:(NSArray *)items;

#pragma mark - Load
+ (NSArray *)itemsWithClass:(Class)class criteria:(NSString *)criteria arguments:(NSArray *)arguments;

@end

@protocol DBModelProtocol <NSObject>

@required
//+ (EFDataModel *)dbModel;

+ (NSString *)tableName;
+ (NSSet *)primaryKeys;
+ (NSDictionary *)columnsByPropertyKey;

@end
