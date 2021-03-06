//
//  SIProductsViewController.m
//  SUS Inspector
//
//  Created by Juutilainen Hannes on 7.3.2013.
//  Copyright (c) 2013 Hannes Juutilainen. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


#import "SIProductsViewController.h"
#import "SIProductInfoWindowController.h"
#import "SIPkginfoWindowController.h"
#import "SIPkginfoMultipleWindowController.h"
#import "SIOperationManager.h"
#import "SIMunkiAdminBridge.h"

@interface SIProductsViewController ()

@end

@implementation SIProductsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.pkginfoWindowControllers = [NSMutableArray new];
        self.productInfoWindowControllers = [NSMutableArray new];
    }
    
    return self;
}


+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
    /*
     Update the mainCompoundPredicate everytime the subcomponents are updated
     */
    if ([key isEqualToString:@"mainCompoundPredicate"])
    {
        NSSet *affectingKeys = [NSSet setWithObjects:@"productsMainFilterPredicate", @"searchFieldPredicate", nil];
        keyPaths = [keyPaths setByAddingObjectsFromSet:affectingKeys];
    }
	
    return keyPaths;
}


- (NSPredicate *)mainCompoundPredicate
{
    /*
     Combine the selected source list item predicate and the possible search field predicate
     */
    return [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:self.productsMainFilterPredicate, self.searchFieldPredicate, nil]];
}


- (void)openGetInfoWindow
{
    for (SIProductMO *aProduct in [self.productsArrayController selectedObjects]) {
        SIProductInfoWindowController *newInfoWindow = [[SIProductInfoWindowController alloc] initWithWindowNibName:@"SIProductInfoWindowController"];
        newInfoWindow.delegate = self;
        [self.productInfoWindowControllers addObject:newInfoWindow];
        [newInfoWindow setProduct:aProduct];
        [newInfoWindow showWindow:nil];
    }
}

- (IBAction)getInfoAction:(id)sender
{
    /*
     Only open the info window if user double clicked a row
     */
    NSInteger clickedRow = [self.productsTableView clickedRow];
    if (clickedRow >= 0) {
        [self openGetInfoWindow];
    }
}

- (IBAction)copyProductIDAction:(id)sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSArray *pb_types = [NSArray arrayWithObjects:NSStringPboardType, nil];
    [pb declareTypes:pb_types owner:nil];
    
    NSMutableArray *productIDStrings = [[NSMutableArray alloc] init];
    for (SIProductMO *aProduct in [self.productsArrayController selectedObjects]) {
        [productIDStrings addObject:aProduct.productID];
    }
    
    if ([productIDStrings count] > 1) {
        NSString *combinedIDs = [productIDStrings componentsJoinedByString:@" "];
        [pb setString:combinedIDs forType:NSStringPboardType];
    } else if ([productIDStrings count] == 1) {
        [pb setString:[productIDStrings objectAtIndex:0] forType:NSStringPboardType];
    }
}

- (IBAction)copyTitleAction:(id)sender
{
    NSPasteboard *pb = [NSPasteboard generalPasteboard];
    NSArray *pb_types = [NSArray arrayWithObjects:NSStringPboardType, nil];
    [pb declareTypes:pb_types owner:nil];
    
    NSMutableArray *productIDStrings = [[NSMutableArray alloc] init];
    for (SIProductMO *aProduct in [self.productsArrayController selectedObjects]) {
        [productIDStrings addObject:aProduct.productTitle];
    }
    
    if ([productIDStrings count] > 1) {
        NSString *combinedIDs = [productIDStrings componentsJoinedByString:@" "];
        [pb setString:combinedIDs forType:NSStringPboardType];
    } else if ([productIDStrings count] == 1) {
        [pb setString:[productIDStrings objectAtIndex:0] forType:NSStringPboardType];
    }
}

- (void)openDistributionFile:(SIDistributionMO *)aDist
{
    // Check if we have a cached copy
    if (aDist.objectIsCachedValue) {
        NSString *appPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"distFileViewerPath"];
        [[NSWorkspace sharedWorkspace] openFile:aDist.objectCachedPath withApplication:appPath];
    } else {
        NSURL *distURL = [NSURL URLWithString:aDist.objectURL];
        [aDist setPerformPostDownloadActionValue:YES];
        [[SIOperationManager sharedManager] cacheDownloadableObjectWithURL:distURL];
    }
}

- (void)openPreferredDistributionForSelectedProducts
{
    for (SIProductMO *aProduct in [self.productsArrayController selectedObjects]) {
        SIDistributionMO *preferred = aProduct.preferredDistribution;
        [self openDistributionFile:preferred];
    }
}


- (void)openPkginfoWindow
{
    if ([[self.productsArrayController selectedObjects] count] == 1) {
        SIProductMO *selectedProduct = [[self.productsArrayController selectedObjects] objectAtIndex:0];
        SIPkginfoWindowController *controller = [SIPkginfoWindowController controllerWithProduct:selectedProduct];
        controller.delegate = self;
        [self.pkginfoWindowControllers addObject:controller];
    } else {
        [self.multiplePkginfoController setProducts:[self.productsArrayController selectedObjects]];
        [self.multiplePkginfoController showWindow:nil];
    }
}

- (IBAction)createPkginfoAction:(id)sender
{
    [self openPkginfoWindow];
}

- (void)removeProductInfoWindowController:(id)sender
{
    [self.productInfoWindowControllers removeObject:sender];
}

- (void)removePkginfoWindowController:(id)sender
{
    [self.pkginfoWindowControllers removeObject:sender];
}

- (void)sendSelectedItemsToMunkiAdmin
{
    NSMutableArray *productsToSend = [[NSMutableArray alloc] init];
    for (SIProductMO *aProduct in [self.productsArrayController selectedObjects]) {
        [productsToSend addObject:aProduct];
    }
    [[SIMunkiAdminBridge sharedBridge] sendProducts:[NSArray arrayWithArray:productsToSend]];
}

- (IBAction)sendToMunkiAdminAction:(id)sender
{
    [self sendSelectedItemsToMunkiAdmin];
}

- (void)distributionFilesMenuAction:(id)sender
{
    if ([[sender representedObject] isKindOfClass:[SIDistributionMO class]]) {
        [self openDistributionFile:[sender representedObject]];
    }
}

- (void)packagesMenuAction:(id)sender
{
    // Get the selected package
    SIPackageMO *selectedPackage = [sender representedObject];
    
    // Check if we have a cached copy
    if (selectedPackage.objectIsCachedValue) {
        [[NSWorkspace sharedWorkspace] selectFile:selectedPackage.objectCachedPath inFileViewerRootedAtPath:@""];
        
    } else {
        NSURL *packageURL = [NSURL URLWithString:selectedPackage.objectURL];
        [selectedPackage setPerformPostDownloadActionValue:YES];
        [[SIOperationManager sharedManager] cacheDownloadableObjectWithURL:packageURL];
    }
}

- (void)menuWillOpen:(NSMenu *)menu
{
    if (menu == self.productsListMenu) {
        
        SIMunkiAdminBridge *maBridge = [SIMunkiAdminBridge sharedBridge];
        
        [self.sendToMunkiAdminMenuItem setHidden:![maBridge munkiAdminInstalled]];
        [self.sendToMunkiAdminMenuItem setEnabled:[maBridge munkiAdminRunning]];
        
        [self.distributionFilesMenu removeAllItems];
        [self.distributionFilesMenu setAutoenablesItems:NO];
        SIProductMO *selectedProduct = [[self.productsArrayController selectedObjects] objectAtIndex:0];
        NSSortDescriptor *sortByLanguage = [NSSortDescriptor sortDescriptorWithKey:@"distributionLanguageDisplayName" ascending:YES selector:@selector(localizedStandardCompare:)];
        NSArray *sortedDistributions = [selectedProduct.distributions sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortByLanguage]];
        [sortedDistributions enumerateObjectsWithOptions:0 usingBlock:^(SIDistributionMO *obj, NSUInteger idx, BOOL *stop) {
            NSString *language = obj.distributionLanguageDisplayName;
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:language action:@selector(distributionFilesMenuAction:) keyEquivalent:@""];
            [item setTarget:self];
            [item setRepresentedObject:obj];
            [self.distributionFilesMenu addItem:item];
        }];
        
        [self.packagesMenu removeAllItems];
        [self.packagesMenu setAutoenablesItems:NO];
        NSSortDescriptor *sortByFileName = [NSSortDescriptor sortDescriptorWithKey:@"packageFilename" ascending:YES selector:@selector(localizedStandardCompare:)];
        NSArray *sortedPackages = [selectedProduct.packages sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortByFileName]];
        [sortedPackages enumerateObjectsWithOptions:0 usingBlock:^(SIPackageMO *obj, NSUInteger idx, BOOL *stop) {
            NSString *title;
            /*
             if (obj.objectIsCachedValue) {
             title = [NSString stringWithFormat:@"Show %@ in Finder", [obj packageFilename]];
             } else {
             title = [NSString stringWithFormat:@"Download %@ and Show in Finder", [obj packageFilename]];
             }
             */
            title = [NSString stringWithFormat:@"%@", [obj packageFilename]];
            
            NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:@selector(packagesMenuAction:) keyEquivalent:@""];
            [item setTarget:self];
            [item setRepresentedObject:obj];
            NSImage *icon = [obj iconImage];
            [icon setSize:NSMakeSize(16.0, 16.0)];
            [item setImage:icon];
            [self.packagesMenu addItem:item];
        }];
    }
}

- (void)awakeFromNib
{
    NSSortDescriptor *sortByDate = [NSSortDescriptor sortDescriptorWithKey:@"productPostDate" ascending:NO selector:@selector(compare:)];
    NSSortDescriptor *sortByTitle = [NSSortDescriptor sortDescriptorWithKey:@"productTitle" ascending:YES selector:@selector(localizedStandardCompare:)];
    NSSortDescriptor *sortByID = [NSSortDescriptor sortDescriptorWithKey:@"productID" ascending:YES selector:@selector(localizedStandardCompare:)];
    [self.productsArrayController setSortDescriptors:[NSArray arrayWithObjects:sortByDate, sortByTitle, sortByID, nil]];
    
    [self.productsTableView setTarget:self];
    [self.productsTableView setDoubleAction:@selector(getInfoAction:)];
    
    [self.productsListMenu setDelegate:self];
    
    //self.productInfoWindowController = [[[SIProductInfoWindowController alloc] initWithWindowNibName:@"SIProductInfoWindowController"] autorelease];
    //self.pkginfoWindowController = [[[SIPkginfoWindowController alloc] initWithWindowNibName:@"SIPkginfoWindowController"] autorelease];
    
    self.multiplePkginfoController = [[SIPkginfoMultipleWindowController alloc] initWithWindowNibName:@"SIPkginfoMultipleWindowController"];
    (void)[self.multiplePkginfoController window];
}

@end
