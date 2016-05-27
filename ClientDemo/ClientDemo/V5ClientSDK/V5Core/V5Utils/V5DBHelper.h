//
//  V5DBHelper.h
//  V5KFClientTest
//
//  Created by chyrain on 15/12/31.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import <Foundation/Foundation.h>

@class V5Message,FMDatabase;

@interface V5DBHelper : NSObject

- (instancetype)initWithDBName:(NSString *)name tableName:(NSString *)table;

- (BOOL)insertMessage:(V5Message *)message;
- (BOOL)insertMessage:(V5Message *)message force:(BOOL)force;

- (BOOL)queryMessages:(NSMutableArray<V5Message *> *)msgs offset:(NSInteger)offset size:(NSInteger)size;

- (BOOL)clear;

+ (BOOL)isDatabase:(FMDatabase *)db hasTable:(NSString *)tableName;

- (void)setTableName:(NSString *)table;

@end
