//
//  EFDataManager.h
//  EFDataModelExample
//
//  Created by Elton Faggett on 5/13/14.
//  Copyright (c) 2014 290 Design, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EFDataModel;
@interface EFDataManager : NSObject

#pragma mark - Save
+ (BOOL)saveItems:(NSArray *)items;

#pragma mark - Load
+ (NSArray *)itemsWithDBModel:(EFDataModel *)dbModel criteria:(NSString *)criteria arguments:(NSArray *)arguments;

@end