#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <XCTest/XCTest.h>
#import "ALIterativeMigrator.h"

@interface CoreDataMigrationTests : XCTestCase

@end

@implementation CoreDataMigrationTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testModelUrl {
    NSURL *url = [self urlForModelName:@"WordPress 20" inDirectory:nil];
    
    XCTAssertNotNil(url);
}

- (void)testMigrate19to21Failure
{
    NSURL *model19Url = [self urlForModelName:@"WordPress 19" inDirectory:nil];
    NSURL *model21Url = [self urlForModelName:@"WordPress 21" inDirectory:nil];
    NSURL *storeUrl = [self urlForStoreWithName:@"WordPress20.sqlite"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:model19Url];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    NSDictionary *options = @{
                              NSInferMappingModelAutomaticallyOption            : @(YES),
                              NSMigratePersistentStoresAutomaticallyOption    : @(YES)
                              };
    
    NSError *error = nil;
    NSPersistentStore * ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                                    configuration:nil
                                              URL:storeUrl
                                          options:options
                                            error:&error];
    
    XCTAssertNotNil(ps);
    //make sure we remove the persistent store to make sure it releases the file.
    [psc removePersistentStore:ps error:&error];
    
    psc = nil;
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:model21Url];
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSPersistentStore * psFail = [psc addPersistentStoreWithType:NSSQLiteStoreType
                               configuration:nil
                                         URL:storeUrl
                                     options:options
                                       error:&error];
    
    XCTAssertNil(psFail);
}

- (void)testMigrate19to21Success {
    NSURL *model19Url = [self urlForModelName:@"WordPress 19" inDirectory:nil];
    NSURL *model21Url = [self urlForModelName:@"WordPress 21" inDirectory:nil];
    NSURL *storeUrl = [self urlForStoreWithName:@"WordPress20.sqlite"];
    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:model19Url];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    
    NSDictionary *options = @{
                              NSInferMappingModelAutomaticallyOption            : @(YES),
                              NSMigratePersistentStoresAutomaticallyOption    : @(YES)
                              };
    
    NSError *error = nil;
    NSPersistentStore * ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                                    configuration:nil
                                              URL:storeUrl
                                          options:options
                                            error:&error];
    
    if (!ps) {
        NSLog(@"Error while openning Persistent Store: %@", [error localizedDescription]);
    }

    XCTAssertNotNil(ps);
    
    psc = nil;
    
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:model21Url];
    BOOL migrateResult = [ALIterativeMigrator iterativeMigrateURL:storeUrl
                                                           ofType:NSSQLiteStoreType
                                                          toModel:model
                                                orderedModelNames:@[@"WordPress 18", @"WordPress 19", @"WordPress 20", @"WordPress 21"]
                                                            error:&error];
    if (!migrateResult) {
        NSLog(@"Error while migrating: %@", error);
    }
    XCTAssertTrue(migrateResult);
    
    psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    ps = [psc addPersistentStoreWithType:NSSQLiteStoreType
                               configuration:nil
                                         URL:storeUrl
                                     options:options
                                       error:&error];
    
    if (!ps) {
        NSLog(@"Error while openning Persistent Store: %@", [error localizedDescription]);
    }
    XCTAssertNotNil(ps);
    
    //make sure we remove the persistent store to make sure it releases the file.
    [psc removePersistentStore:ps error:&error];
}

// Returns the URL for a model file with the given name in the given directory.
// @param directory The name of the bundle directory to search.  If nil,
//    searches default paths.
- (NSURL *)urlForModelName:(NSString*)modelName
               inDirectory:(NSString*)directory
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSURL *url = [bundle URLForResource:modelName
                          withExtension:@"mom"
                           subdirectory:directory];
    if (nil == url) {
        // Get mom file paths from momd directories.
        NSArray *momdPaths = [[NSBundle mainBundle] pathsForResourcesOfType:@"momd"
                                                                inDirectory:directory];
        for (NSString *momdPath in momdPaths) {
            url = [bundle URLForResource:modelName
                           withExtension:@"mom"
                            subdirectory:[momdPath lastPathComponent]];
        }
    }
    
    return url;
}

- (NSURL *)urlForStoreWithName:(NSString *)fileName
{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                                        NSUserDomainMask,
                                                                        YES) lastObject];
    NSURL *storeURL = [NSURL fileURLWithPath:[documentsDirectory stringByAppendingPathComponent:fileName]];
    NSError *error = nil;
    if (![[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error]) {
        NSLog(@"Error removing file: %@", [error localizedDescription]);
    }
    
    return storeURL;
}


@end
