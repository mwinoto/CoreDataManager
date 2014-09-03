//
//  Created by Marc Winoto on 10/11/10.
//  Copyright 2010 Marc Winoto. All rights reserved.
//

#import "CoreDataManager.h"

@interface CoreDataManager ()

-(NSString*) documentsFolder;

-(void) checkDatabase;

@end

@implementation CoreDataManager

-(id)init
{
    if ((self = [super init]))
    {
        _createdNewDatabase = NO;
        [self checkDatabase];
    }
    return self;
}



#pragma mark - CoreDataManager

static CoreDataManager * dataManager;

+(CoreDataManager *) defaultDataManager
{
    @synchronized(self)
    {
        if (!dataManager)
            dataManager = [[CoreDataManager alloc] init];
        
        return dataManager;
    }
}

static NSString * _model=nil;
static NSString * _store=nil;
static NSString * _exampleData=nil;

+(void)initialiseWithModel:(NSString*)model dataStore:(NSString*)store exampleData:(NSString*)exampleData
{
    _model=model;
    _store=store;
    _exampleData=exampleData;    
}


- (void)saveContext
{
    NSError *error = nil;
    if (_managedObjectContext != nil)
    {
        if ([_managedObjectContext hasChanges] && ![_managedObjectContext save:&error])
        {
            //Replace this implementation with code to handle the error appropriately.
            //abort() causes the application to generate a crash log and terminate. 
            //You should not use this function in a shipping application, although it 
            //may be useful during development. If it is not possible to recover from 
            //the error, display an alert panel that instructs the user to quit the 
            //application by pressing the Home button.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            //abort();
        } 
    }
}

-(void) deleteObject:(NSManagedObject *)object andSave:(BOOL) save
{
    [self.managedObjectContext deleteObject:object];
    if(save)
        [self saveContext];
}

#pragma mark - Private

-(void) checkDatabase
{
    NSFileManager * fileManager = [NSFileManager defaultManager];
    // This checks the existance of the Documents folder. Is this neccesary??
	NSString * docFolder = [self documentsFolder];
	if(![fileManager fileExistsAtPath:docFolder])
	{
		// Deprecated
		//[fileManager createDirectoryAtPath:docFolder attributes:nil];
		NSError * error = nil;
		if(![fileManager createDirectoryAtPath:docFolder
				   withIntermediateDirectories:NO
									attributes:nil
										 error:&error])
		{
			NSLog(@"%@:%@ Error copying file %@", [self class], NSStringFromSelector(_cmd), [error localizedDescription]);
		}
	}
	
	// Get the path to the application store and check if it is there. 
	// If not, check the supplied store. If that is there, copy it.
	// Other wise it has to be generated later.
	NSString * dataStorePath = nil;
	dataStorePath = [docFolder stringByAppendingPathComponent:_store];
    
	if(![fileManager fileExistsAtPath:dataStorePath])
	{
        if(_exampleData!=nil)
        {
            NSString * sampleStorePath = [[NSBundle mainBundle] pathForResource:_exampleData ofType:@"sqlite"];
            NSError * error = nil;
            if (![[NSFileManager defaultManager] copyItemAtPath:sampleStorePath 
                                                         toPath:dataStorePath 
                                                          error:&error])
            {
                NSLog(@"%@:%@ Error copying file %@", [self class], NSStringFromSelector(_cmd), error);
            }
            _createdNewDatabase = NO;
        }
        else
        {
            _createdNewDatabase = YES;
        }
	}
    else
    {
        _createdNewDatabase = NO;
    }
}

-(NSManagedObjectModel*) managedObjectModel
{
	if (_managedObjectModel) return _managedObjectModel;
	
	NSString * path = [[NSBundle mainBundle] pathForResource:_model ofType:@"momd"];
	if(!path)
	{
		path = [[NSBundle mainBundle] pathForResource:_model ofType:@"mom"];
	}
	
	NSAssert(path!=nil, @"Unable to find DataModel in main bundle");
	NSURL * url = [NSURL fileURLWithPath:path];
	_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:url];
	return _managedObjectModel;
}

// This is where we will put the persistent store. Just like regular SQLite stuff
// Returns the documents folder
-(NSString*) documentsFolder
{
	NSArray * paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, 
														  NSUserDomainMask, 
														  YES);
	NSString * filePath = [paths objectAtIndex:0];
	return filePath;
}

// TODO: 
-(NSPersistentStoreCoordinator*) persistentStoreCoordinator
{
	if(_persistentStoreCoordinator) 
		return _persistentStoreCoordinator;
	
	// This checks the existance of the Documents folder. Is this neccesary??
	NSString * docFolder = [self documentsFolder];
    NSString * dataStorePath = nil;
	dataStorePath = [docFolder stringByAppendingPathComponent:_store];
	 
	// Try and create the persistent store co-ordinator and return it if successful.
	// Other wise we clean up and spit out errors.
	NSURL * url = [NSURL fileURLWithPath:dataStorePath];
	NSManagedObjectModel * mom = [self managedObjectModel];
	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
	NSError * error = nil;
	if ([_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType 
												 configuration:nil 
														   URL:url 
													   options:nil 
														 error:&error]) 
	{
		return _persistentStoreCoordinator;
	}
	
    // Something wrong happened, bail
	_persistentStoreCoordinator = nil;
	NSDictionary * ui = [error userInfo];
	if (![ui valueForKey:NSDetailedErrorsKey]) 
	{
		NSLog(@"%@:%@ Error adding store %@", [self class], NSStringFromSelector(_cmd), [error localizedDescription]);
	}
	else 
	{
		for (NSError * subError in [ui valueForKey:NSDetailedErrorsKey]) 
		{
			NSLog(@"%@:%@ Error adding store %@", [self class], NSStringFromSelector(_cmd), [subError localizedDescription]);
		}
	}
	NSAssert(NO, @"Failed to initialise the persistent store");
	return nil;
}

-(NSManagedObjectContext *) managedObjectContext 
{
	if (_managedObjectContext) 
	{
		return _managedObjectContext;
	}
	
	NSPersistentStoreCoordinator *storeCoordinator = [self persistentStoreCoordinator];
	if (!storeCoordinator)
	{
		return nil;
	}
	
	self.managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:storeCoordinator];
		
	return _managedObjectContext;
}

@end
