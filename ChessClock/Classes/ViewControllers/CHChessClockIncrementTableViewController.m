//
//  CHIncrementTableViewController.m
//  Chess.com
//
//  Created by Pedro Bolaños on 11/1/12.
//  Copyright (c) 2012 psbt. All rights reserved.
//

#import "CHChessClockIncrementTableViewController.h"
#import "CHChessClockIncrement.h"
#import "CHChessClockTimeViewController.h"
#import "CHUtil.h"

//------------------------------------------------------------------------------
#pragma mark - Private methods declarations
//------------------------------------------------------------------------------
@interface CHChessClockIncrementTableViewController()
<CHChessClockTimeViewControllerDelegate, UIPopoverControllerDelegate>

@property (retain, nonatomic) NSDictionary* incrementsTypesDictionary;
@property (assign, nonatomic) NSUInteger selectedIncrementValue;

@end

//------------------------------------------------------------------------------
#pragma mark - CHChessClockIncrementTableViewController implementation
//------------------------------------------------------------------------------
@implementation CHChessClockIncrementTableViewController

static const NSUInteger CHIncrementTypeSection = 0;
static const NSUInteger CHIncrementValueSection = 1;
static const NSUInteger CHIncrementTypeSegmentedControlTag = 1;

static const NSUInteger CHDelaySegmentIndex = 0;
static const NSUInteger CHBronsteinSegmentIndex = 1;
static const NSUInteger CHFischerSegmentIndex = 2;

- (void)dealloc
{
    _delegate = nil;
    [_increment release];
    [_incrementsTypesDictionary release];
    
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Increment", nil);
    self.selectedIncrementValue = self.increment.incrementValue;
}

//------------------------------------------------------------------------------
#pragma mark - Private methods definitions
//------------------------------------------------------------------------------
- (NSDictionary*)incrementsTypesDictionary
{
    if (_incrementsTypesDictionary == nil) {
        self.incrementsTypesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSNumber numberWithInt:CHDelaySegmentIndex], @"CHChessClockDelayIncrement",
                                          [NSNumber numberWithInt:CHBronsteinSegmentIndex], @"CHChessClockBronsteinIncrement",
                                          [NSNumber numberWithInt:CHFischerSegmentIndex], @"CHChessClockFischerIncrement",
                                          nil];
    }
    
    return _incrementsTypesDictionary;
}

- (void)incrementTypeChanged:(UISegmentedControl*)sender
{
    NSString* selectedIncrementClassName = nil;
    
    for (NSString* incrementClassName in self.incrementsTypesDictionary) {
        if ([[self.incrementsTypesDictionary objectForKey:incrementClassName] integerValue] == sender.selectedSegmentIndex) {
            selectedIncrementClassName = incrementClassName;
            break;
        }
    }
    
    CHChessClockIncrement* increment = [[NSClassFromString(selectedIncrementClassName) alloc]
                                        initWithIncrementValue:self.selectedIncrementValue];
    self.increment = increment;
    [increment release];
    
    [self.delegate chessClockIncrementTableViewControllerUpdatedIncrement:self];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:CHIncrementTypeSection]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (UITableViewCell*)incrementTypeCell
{
    NSString* reuseIdentifier = @"CHIncrementTypeCell";
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        // This removes the cell rounded background
        UIView* backgroundView = [[UIView alloc] initWithFrame:cell.bounds];
        cell.backgroundView = backgroundView;
        [backgroundView release];

        UISegmentedControl* segmentedControl = [[UISegmentedControl alloc] initWithItems:
                                                [NSArray arrayWithObjects:@"Delay",
                                                 @"Bronstein", @"Fischer", nil]];
        
        segmentedControl.frame = cell.bounds;
        segmentedControl.tag = CHIncrementTypeSegmentedControlTag;
        segmentedControl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        [segmentedControl addTarget:self action:@selector(incrementTypeChanged:) forControlEvents:UIControlEventValueChanged];
        [cell.contentView addSubview:segmentedControl];
        [segmentedControl release];
    }
    
    NSString* incrementClassName = NSStringFromClass([self.increment class]);
    UISegmentedControl* segmentedControl = (UISegmentedControl*)[cell viewWithTag:CHIncrementTypeSegmentedControlTag];
    [segmentedControl setSelectedSegmentIndex:[[self.incrementsTypesDictionary objectForKey:incrementClassName] integerValue]];

    return cell;
}

- (UITableViewCell*)incrementValueCell
{
    NSString* reuseIdentifier = @"CHIncrementValueCell";
    UITableViewCell* cell = [self.tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier] autorelease];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:15.0f];
        
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    
    cell.textLabel.text = NSLocalizedString(@"Value", nil);
    
    NSUInteger incrementValue = self.increment.incrementValue;
    NSString* incrementValueString = [CHUtil formatTime:incrementValue showTenths:NO];
    
    if (incrementValue < 60) {
        NSString* secondsString = NSLocalizedString(@"secs", @"Abbreviation for seconds");
        if (incrementValue == 1) {
            secondsString = NSLocalizedString(@"sec", @"Abbreviation for second");
        }
        
        incrementValueString = [NSString stringWithFormat:@"%d %@", incrementValue, secondsString];
    }
    
    cell.detailTextLabel.text = incrementValueString;
    
    return cell;
}

- (void)selectedIncrementValueCell:(UITableViewCell*)cell
{
    NSString* nibName = [CHUtil nibNameWithBaseName:@"CHChessClockTimeView"];
    CHChessClockTimeViewController* timeViewController = [[CHChessClockTimeViewController alloc]
                                                          initWithNibName:nibName bundle:nil];
    timeViewController.maximumMinutes = 60;
    timeViewController.maximumSeconds = 60;
    timeViewController.zeroSelectionAllowed = YES;
    timeViewController.selectedTime = self.increment.incrementValue;
    timeViewController.title = NSLocalizedString(@"Value", nil);
    timeViewController.delegate = self;
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UIPopoverController* popover = [[UIPopoverController alloc] initWithContentViewController:timeViewController];
        popover.delegate = self;
        [popover presentPopoverFromRect:cell.bounds inView:cell
               permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
    }
    else {
        [self.navigationController pushViewController:timeViewController animated:YES];
    }
    
    [timeViewController release];
}

//------------------------------------------------------------------------------
#pragma mark - UITableViewDataSource methods
//------------------------------------------------------------------------------
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7)
    {
        tableView.tintColor = [UIColor blackColor];
    }
    UITableViewCell* cell = nil;
    switch (indexPath.section) {
        case CHIncrementTypeSection:
            cell = [self incrementTypeCell];
            break;

        case CHIncrementValueSection:
            cell = [self incrementValueCell];
            
        default:
            break;
    }

    [cell setFont:[UIFont boldSystemFontOfSize:15]];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == CHIncrementTypeSection) {
        return NSLocalizedString(@"Type", nil);
    }
    
    return nil;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {

    if (section == CHIncrementTypeSection) {
        return [self.increment incrementDescription];
    }
    
    return nil;
}

//------------------------------------------------------------------------------
#pragma mark - UITableViewDelegate methods
//------------------------------------------------------------------------------
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case CHIncrementValueSection:
            [self selectedIncrementValueCell:[tableView cellForRowAtIndexPath:indexPath]];
            break;
            
        default:
            break;
    }
}

//------------------------------------------------------------------------------
#pragma mark - UIPopoverControllerDelegate methods
//------------------------------------------------------------------------------
- (void)popoverControllerDidDismissPopover:(UIPopoverController*)popoverController
{
    NSIndexPath* selectedIndexPath = [self.tableView indexPathForSelectedRow];
    [self.tableView deselectRowAtIndexPath:selectedIndexPath animated:YES];
    [popoverController release];
}

//------------------------------------------------------------------------------
#pragma mark - CHChessClockTimeViewControllerDelegate methods
//------------------------------------------------------------------------------
- (void)chessClockTimeViewController:(CHChessClockTimeViewController*)timeViewController
              closedWithSelectedTime:(NSUInteger)timeInSeconds
{
    self.increment.incrementValue = timeInSeconds;
    self.selectedIncrementValue = timeInSeconds;
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:CHIncrementValueSection]
                  withRowAnimation:UITableViewRowAnimationAutomatic];
    
    [self.delegate chessClockIncrementTableViewControllerUpdatedIncrement:self];
}

@end
