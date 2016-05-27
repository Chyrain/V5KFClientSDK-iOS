//
//  V5FMDatabaseQueue.h
//  fmdb
//
//  Created by August Mueller on 6/22/11.
//  Copyright 2011 Flying Meat Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#if V5FMDB_SQLITE_STANDALONE
#import <sqlite3/sqlite3.h>
#else
#import <sqlite3.h>
#endif

@class V5FMDatabase;

/** To perform queries and updates on multiple threads, you'll want to use `V5FMDatabaseQueue`.

 Using a single instance of `<V5FMDatabase>` from multiple threads at once is a bad idea.  It has always been OK to make a `<V5FMDatabase>` object *per thread*.  Just don't share a single instance across threads, and definitely not across multiple threads at the same time.

 Instead, use `V5FMDatabaseQueue`. Here's how to use it:

 First, make your queue.

    V5FMDatabaseQueue *queue = [V5FMDatabaseQueue databaseQueueWithPath:aPath];

 Then use it like so:

    [queue inDatabase:^(V5FMDatabase *db) {
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:1]];
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:2]];
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:3]];

        V5FMResultSet *rs = [db executeQuery:@"select * from foo"];
        while ([rs next]) {
            //…
        }
    }];

 An easy way to wrap things up in a transaction can be done like this:

    [queue inTransaction:^(V5FMDatabase *db, BOOL *rollback) {
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:1]];
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:2]];
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:3]];

        if (whoopsSomethingWrongHappened) {
            *rollback = YES;
            return;
        }
        // etc…
        [db executeUpdate:@"INSERT INTO myTable VALUES (?)", [NSNumber numberWithInt:4]];
    }];

 `V5FMDatabaseQueue` will run the blocks on a serialized queue (hence the name of the class).  So if you call `V5FMDatabaseQueue`'s methods from multiple threads at the same time, they will be executed in the order they are received.  This way queries and updates won't step on each other's toes, and every one is happy.

 ### See also

 - `<V5FMDatabase>`

 @warning Do not instantiate a single `<V5FMDatabase>` object and use it across multiple threads. Use `V5FMDatabaseQueue` instead.
 
 @warning The calls to `V5FMDatabaseQueue`'s methods are blocking.  So even though you are passing along blocks, they will **not** be run on another thread.

 */

@interface V5FMDatabaseQueue : NSObject {
    NSString            *_path;
    dispatch_queue_t    _queue;
    V5FMDatabase          *_db;
    int                 _openFlags;
}

/** Path of database */

@property (atomic, retain) NSString *path;

/** Open flags */

@property (atomic, readonly) int openFlags;

///----------------------------------------------------
/// @name Initialization, opening, and closing of queue
///----------------------------------------------------

/** Create queue using path.
 
 @param aPath The file path of the database.
 
 @return The `V5FMDatabaseQueue` object. `nil` on error.
 */

+ (instancetype)databaseQueueWithPath:(NSString*)aPath;

/** Create queue using path and specified flags.
 
 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database
 
 @return The `V5FMDatabaseQueue` object. `nil` on error.
 */
+ (instancetype)databaseQueueWithPath:(NSString*)aPath flags:(int)openFlags;

/** Create queue using path.

 @param aPath The file path of the database.

 @return The `V5FMDatabaseQueue` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString*)aPath;

/** Create queue using path and specified flags.
 
 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database
 
 @return The `V5FMDatabaseQueue` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString*)aPath flags:(int)openFlags;

/** Create queue using path and specified flags.
 
 @param aPath The file path of the database.
 @param openFlags Flags passed to the openWithFlags method of the database
 @param vfsName The name of a custom virtual file system
 
 @return The `V5FMDatabaseQueue` object. `nil` on error.
 */

- (instancetype)initWithPath:(NSString*)aPath flags:(int)openFlags vfs:(NSString *)vfsName;

/** Returns the Class of 'V5FMDatabase' subclass, that will be used to instantiate database object.
 
 Subclasses can override this method to return specified Class of 'V5FMDatabase' subclass.
 
 @return The Class of 'V5FMDatabase' subclass, that will be used to instantiate database object.
 */

+ (Class)databaseClass;

/** Close database used by queue. */

- (void)close;

///-----------------------------------------------
/// @name Dispatching database operations to queue
///-----------------------------------------------

/** Synchronously perform database operations on queue.
 
 @param block The code to be run on the queue of `V5FMDatabaseQueue`
 */

- (void)inDatabase:(void (^)(V5FMDatabase *db))block;

/** Synchronously perform database operations on queue, using transactions.

 @param block The code to be run on the queue of `V5FMDatabaseQueue`
 */

- (void)inTransaction:(void (^)(V5FMDatabase *db, BOOL *rollback))block;

/** Synchronously perform database operations on queue, using deferred transactions.

 @param block The code to be run on the queue of `V5FMDatabaseQueue`
 */

- (void)inDeferredTransaction:(void (^)(V5FMDatabase *db, BOOL *rollback))block;

///-----------------------------------------------
/// @name Dispatching database operations to queue
///-----------------------------------------------

/** Synchronously perform database operations using save point.

 @param block The code to be run on the queue of `V5FMDatabaseQueue`
 */

#if SQLITE_VERSION_NUMBER >= 3007000
// NOTE: you can not nest these, since calling it will pull another database out of the pool and you'll get a deadlock.
// If you need to nest, use V5FMDatabase's startSavePointWithName:error: instead.
- (NSError*)inSavePoint:(void (^)(V5FMDatabase *db, BOOL *rollback))block;
#endif

@end

