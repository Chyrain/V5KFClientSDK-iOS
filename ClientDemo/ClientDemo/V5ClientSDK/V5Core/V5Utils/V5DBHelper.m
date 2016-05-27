//
//  V5DBHelper.m
//  V5KFClientTest
//
//  Created by chyrain on 15/12/31.
//  Copyright © 2015年 V5KF. All rights reserved.
//

#import "V5DBHelper.h"
#import "V5FMDB.h"
#import "V5MessageManager.h"
#import "V5Macros.h"

@interface V5DBHelper () {
    V5FMDatabase *db;
    NSString *tableName;
}

@end

@implementation V5DBHelper

- (instancetype)initWithDBName:(NSString *)name tableName:(NSString *)table {
    self = [super init];
    if (self) {
        tableName = table;
        NSString *path = [self datebasePathInDocumentDir:name];
        db = [V5FMDatabase databaseWithPath:path];
        [self createTable:table];
    }
    return self;
}

/**
 *  插入消息
 *
 *  @param message 消息对象
 */
- (BOOL)insertMessage:(V5Message *)message {
    return [self insertMessage:message force:NO];
}

/**
 *  插入消息
 *
 *  @param message 消息对象
 *  @param force 强制保存
 */
- (BOOL)insertMessage:(V5Message *)message force:(BOOL)force {
    //V5Log(@"[DB] insert message_id(%lld) msg_id(%lld)", message.messageId, message.msgId);
    // 过滤空消息、相关问题消息和部分控制消息
    if (!message || message.direction == MessageDir_RelativeQuestion || message.messageType == MessageType_WXCS ||
        (message.messageType == MessageType_Control)) { //  && [(V5ControlMessage *)message code] != 1 [修改][转人工客服]不显示
        //V5Log(@"[DB] not insert -> not support type");
        return NO;
    }
    
    NSString *jsonContent = [message toJSONString];
    jsonContent = [jsonContent stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    if (!force) { // 非强制保存，需判断消息并排重
        // [修改]修复历史消息排重BUG，增加开场白提问消息过滤(通过msgId过滤10位数以内的为开场白，13位数的为发出的消息用于排重)
        if (message.msgId != 0) {
            if (message.msgId < OPEN_QUES_MAX_ID) { // 过滤开场提问消息(0开始增长，与会话消息数有关,10位数以内)，不做保存
                //V5Log(@"[DB] not insert message:%lld", message.messageId);
                return NO;
            }
            if (message.direction == MessageDir_ToWorker) {
                message.messageId = message.msgId;
            }
        }
        if ([self hasMessageContent:message.messageId]) {
            //V5Log(@"[DB] already has message:%lld", message.messageId);
            // 更新message_id的create_time
            return NO;
        }
    }
    
    if ([db open]) {
        NSString *sqlInsert = [NSString stringWithFormat:@"INSERT INTO %@ (session_tag, message_id, state, direction, message_type, create_time, json_content) VALUES (%ld, %lld, %ld, %ld, %ld, %ld, '%@')", tableName, (long)message.sessionStart, message.messageId, (long)message.state, (long)message.direction, (long)message.messageType, message.createTime, jsonContent];
        BOOL rst = [db executeUpdate:sqlInsert];
        if (rst) {
            //V5Log(@"[DB] insert message success");
        } else {
            //V5Log(@"[DB] insert message failure");
        }
        
        [db close];
        return rst;
    }
    return NO;
}

/**
 *  查询消息
 *
 *  @param msgs   消息列表
 *  @param offset 起始位置
 *  @param size   获取最大数量
 *
 *  @return 是否结束
 */
- (BOOL)queryMessages:(NSMutableArray<V5Message *> *)msgs offset:(NSInteger)offset size:(NSInteger)size {
    if (!msgs) {
        msgs = [NSMutableArray array];
    }
    if ([db open]) {
        NSString *sqlQuery = [NSString stringWithFormat:@"SELECT * from %@ ORDER BY id DESC LIMIT %ld OFFSET %ld", tableName, (long)size, (long)offset];
        //V5Log(@"sql:%@", sqlQuery);
        V5FMResultSet *rst = [db executeQuery:sqlQuery];
        NSUInteger count = 0;
        while ([rst next]) {
            count++;
            int state = [rst intForColumn:@"state"];
            int sessionTag = [rst intForColumn:@"session_tag"];
            int direction = [rst intForColumn:@"direction"];
            long createTime = [rst longForColumn:@"create_time"];
            NSString *jsonContent = [rst stringForColumn:@"json_content"];
            
            if (!jsonContent || [jsonContent isEqualToString:@""] || direction == MessageDir_RelativeQuestion) {
                continue;
            }
            
            NSData *data = [jsonContent dataUsingEncoding:NSUTF8StringEncoding];
            NSDictionary *jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
            V5Message *message = [V5MessageManager receiveMessageFromJSON:jsonData];
            message.state = state;
            message.sessionStart = sessionTag;
            message.createTime = createTime;
            
            [msgs addObject:message];
        }
        BOOL finish = count < size ? YES : NO;
        
        [db close];
        return finish;
    }
    return YES;
}

#pragma mark ------ 内部方法 ------
/**
 *  创建表
 *
 *  @param table 表名
 */
- (void)createTable:(NSString *)table {
    if ([db open]) {
        NSString *sqlCreateTable = [NSString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@ (id INTEGER PRIMARY KEY AUTOINCREMENT, session_tag INTEGER, message_id INTEGER, state INTEGER, direction INTEGER, message_type INTEGER, create_time INTEGER, json_content TEXT)", table];
        BOOL rst = [db executeUpdate:sqlCreateTable];
        if (rst) {
            //V5Log(@"Create table success");
        } else {
            V5Log(@"!!!Error createing table");
        }
        
        [db close];
    }
}

/**
 *  是否已存在此消息内容
 *
 *  @param jsonContent 转字符串存储的消息内容
 *
 *  @return BOOL 是否存在消息
 */
- (BOOL)hasMessageContent:(long long)messageId {
    if ([db open]) {
        NSString *sql = [NSString stringWithFormat:@"SELECT ID FROM %@ where message_id=%lld", tableName, messageId];
        V5FMResultSet *rs = [db executeQuery:sql];
        BOOL has = NO;
        if ([rs next]) {
            has = YES;
        }
        [db close];
        return has;
    }
    
    return NO;
}

/**
 *  数据库是否存在表
 *
 *  @param db        FMDatabase数据库
 *  @param tableName 表名
 *
 *  @return BOOL
 */
+ (BOOL)isDatabase:(V5FMDatabase *)db hasTable:(NSString *)tableName {
    V5FMResultSet *rs = [db executeQuery:@"select count(*) as 'count' from sqlite_master where type ='table' and name = ?", tableName];
    while ([rs next]) {
        // just print out what we've got in a number of formats.
        NSInteger count = [rs intForColumn:@"count"];
        
        if (0 == count) {
            return NO;
        } else {
            return YES;
        }
    }
    
    return NO;
}

/**
 *  数据库路径
 *
 *  @param name 数据库名
 *
 *  @return 路径
 */
- (NSString *)datebasePathInDocumentDir:(NSString *)name {
    return [PATH_OF_DOCUMENT stringByAppendingPathComponent:name];
}

/**
 *  清空数据库
 */
- (BOOL)clear {
    if ([db open]) {
        NSString *sql = [NSString stringWithFormat:@"TRUNCATE TABLE %@", tableName];
        BOOL rst = [db executeUpdate:sql];
        [db close];
        return rst;
    }
    
    return NO;
}

/**
 *  切换数据表
 *
 *  @param tableName NSString
 */
- (void)setTableName:(NSString *)table {
    tableName = table;
	[self createTable:tableName];
}

@end
