//
//  Created by Marc Winoto on 10/11/10.
//  Copyright 2010 Marc Winoto. All rights reserved.
//

#import <CoreData/CoreData.h>

@class DataGenerator;
@interface CoreDataManager : NSObject {
}

@property (nonatomic, strong) NSManagedObjectContext * managedObjectContext;
@property (nonatomic, assign) BOOL createdNewDatabase;
@property (nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;


+(CoreDataManager *) defaultDataManager;
+(void)initialiseWithModel:(NSString*)model dataStore:(NSString*)store exampleData:(NSString*)exampleData;

-(void)saveContext;
-(void) deleteObject:(NSManagedObject *)object andSave:(BOOL) save;

@end
