//
//  R2RFlightSegmentViewController.m
//  Rome2Rio
//
//  Created by Ash Verdoorn on 14/09/12.
//  Copyright (c) 2012 Rome2Rio. All rights reserved.
//

#import "R2RFlightSegmentViewController.h"
#import "R2RFlightSegmentCell.h"
#import "R2RExpandedFlightSegmentCell.h"
#import "R2RFlightSegmentSectionHeader.h"
#import "R2RFlightGroup.h"

#import "R2RSpriteCache.h"
#import "R2RStringFormatter.h"
#import "R2RConstants.h"


@interface R2RFlightSegmentViewController ()

@property (strong, nonatomic) R2RSpriteCache *spriteCache;
@property (strong, nonatomic) NSMutableArray *flightGroups;
@property (strong, nonatomic) NSIndexPath *selectedRowIndex; //current selected row. used for unselecting cell on second click

@property (strong, nonatomic) UIActionSheet *linkMenuSheet;
@property (strong, nonatomic) NSMutableArray *links;

@end

@implementation R2RFlightSegmentViewController

@synthesize searchStore, route, flightSegment;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"Fly", nil);
    
    [self.view setBackgroundColor:[R2RConstants getBackgroundColor]];
    
    self.spriteCache = [[R2RSpriteCache alloc] init];
    
    [self.tableView setSectionHeaderHeight:55];
}

- (void)viewDidUnload
{
    self.spriteCache = nil;
    
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.flightGroups count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    R2RFlightGroup *flightGroup = [self.flightGroups objectAtIndex:section];
    return [flightGroup.flights count];
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGRect rect = CGRectMake(0, 0, self.view.frame.size.width, 50);
    
    R2RFlightSegmentSectionHeader *header = [[R2RFlightSegmentSectionHeader alloc] initWithFrame:rect];

    R2RFlightGroup *flightGroup = [self.flightGroups objectAtIndex:section];
    [header.titleLabel setText:flightGroup.name];
    
    NSString *from = [[NSString alloc] initWithString:self.flightSegment.sCode];
    NSString *to = [[NSString alloc] initWithString:self.flightSegment.tCode];

    [header.fromLabel setText:from];
   
    [header.toLabel setText:to];
    
    return header;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.selectedRowIndex && indexPath.section == self.selectedRowIndex.section && indexPath.row == self.selectedRowIndex.row)
    {
        [cell setBackgroundColor:[R2RConstants getExpandedCellColor]];
    }
    else	
    {
        [cell setBackgroundColor:[R2RConstants getCellColor]];
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *cellIdentifier;
    
    R2RFlightGroup *flightGroup = [self.flightGroups objectAtIndex:indexPath.section];
    
    R2RFlightItinerary *flightItinerary = [flightGroup.flights objectAtIndex:indexPath.row];
    
    R2RFlightLeg *flightLeg = ([flightItinerary.legs count] > 0) ? [flightItinerary.legs objectAtIndex:0] : nil;
    
    if (indexPath.section == self.selectedRowIndex.section && indexPath.row == self.selectedRowIndex.row)
    {
        cellIdentifier = @"ExpandedFlightSegmentCell";
        R2RExpandedFlightSegmentCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        [self configureExpandedFlightSegmentCell:cell :flightLeg];
        
        return cell;
    }

    //else default cell
    cellIdentifier = @"FlightSegmentCell";
    R2RFlightSegmentCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    [self configureFlightSegmentCell:cell :flightLeg];
    
    return cell;
}

-(void) configureFlightSegmentCell: (R2RFlightSegmentCell *) cell: (R2RFlightLeg *) flightLeg
{
    NSInteger hops = [flightLeg.hops count];
    
    NSString *sTime = [[flightLeg.hops objectAtIndex:0] sTime];
    NSString *tTime = [[flightLeg.hops objectAtIndex:(hops-1)] tTime];
    
    [cell.sTimeLabel setText:sTime];
    [cell.tTimeLabel setText:tTime];
    
    float duration = 0.0;
    NSString *firstAirlineCode = nil;
    NSString *secondAirlineCode = nil;
    int hopNumber = 0;
    
    for (R2RFlightHop *flightHop in flightLeg.hops)
    {
        duration += flightHop.duration;
        if (flightHop.lDuration > 0)
        {
            duration += flightHop.lDuration;
        }
        
        if (firstAirlineCode == nil)
        {
            [cell setDisplaySingleIcon];
            firstAirlineCode = flightHop.airline;
        }
        else if (secondAirlineCode == nil && ![flightHop.airline isEqualToString:firstAirlineCode])
        {
            [cell setDisplayDoubleIcon];
            secondAirlineCode = flightHop.airline;
        }
        hopNumber++;
    }
    
    [cell.durationLabel setText:[R2RStringFormatter formatDurationZeroPadded:duration]];
    
    for (R2RAirline *airline in self.searchStore.searchResponse.airlines)
    {
        if ([airline.code isEqualToString:firstAirlineCode])
        {
            R2RSprite *sprite = [self.spriteCache getSprite :airline.iconPath :airline.iconOffset :airline.iconSize];
            [self.searchStore.spriteStore setSpriteInView:sprite :cell.firstAirlineIcon];
        }
        if ([airline.code isEqualToString:secondAirlineCode])
        {
            R2RSprite *sprite = [self.spriteCache getSprite :airline.iconPath :airline.iconOffset :airline.iconSize];
            [self.searchStore.spriteStore setSpriteInView:sprite :cell.secondAirlineIcon];
        }
    }
}

-(void) configureExpandedFlightSegmentCell: (R2RExpandedFlightSegmentCell *) cell: (R2RFlightLeg *) flightLeg
{
    NSInteger hops = [flightLeg.hops count];
    
    NSString *sTime = [[flightLeg.hops objectAtIndex:0] sTime];
    NSString *tTime = [[flightLeg.hops objectAtIndex:(hops-1)] tTime];
    
    [cell.sTimeLabel setText:sTime];
    [cell.tTimeLabel setText:tTime];
    
    CGRect frame = cell.linkButton.frame;
    frame.origin.y = 75 + (50* (hops-1));
    
    [cell.linkButton setFrame:frame];
    [cell.linkButton setImage:[UIImage imageNamed:@"externalLinkIconGray"] forState:UIControlStateNormal];
    [cell.linkButton addTarget:self action:@selector(showLinkMenu) forControlEvents:UIControlEventTouchUpInside];
    
    frame = cell.frequencyLabel.frame;
    frame.origin.y = 75 + (50* (hops-1));
    [cell.frequencyLabel setFrame:frame];
    
    [cell.frequencyLabel setText:[R2RStringFormatter formatDays:flightLeg.days]];
    
    float duration = 0.0;
    NSString *firstAirlineCode = nil;
    NSString *secondAirlineCode = nil;
    int hopNumber = 0;
    
    for (R2RFlightHop *flightHop in flightLeg.hops)
    {
        duration += flightHop.duration;
        if (flightHop.lDuration > 0)
        {
            duration += flightHop.lDuration;
        }
        
        if (firstAirlineCode == nil)
        {
            [cell setDisplaySingleIcon];
            firstAirlineCode = flightHop.airline;
        }
        else if (secondAirlineCode == nil && ![flightHop.airline isEqualToString:firstAirlineCode])
        {
            [cell setDisplayDoubleIcon];
            secondAirlineCode = flightHop.airline;
        }
        
        [self setExpandedCellValues:cell :flightHop :hopNumber];
        
        hopNumber++;
    }
    
    [cell.durationLabel setText:[R2RStringFormatter formatDurationZeroPadded:duration]];
    
    for (R2RAirline *airline in self.searchStore.searchResponse.airlines)
    {
        if ([airline.code isEqualToString:firstAirlineCode])
        {
            R2RSprite *sprite = [self.spriteCache getSprite :airline.iconPath :airline.iconOffset :airline.iconSize];
            [self.searchStore.spriteStore setSpriteInView:sprite :cell.firstAirlineIcon];
        }
        if ([airline.code isEqualToString:secondAirlineCode])
        {
            R2RSprite *sprite = [self.spriteCache getSprite :airline.iconPath :airline.iconOffset :airline.iconSize];
            [self.searchStore.spriteStore setSpriteInView:sprite :cell.secondAirlineIcon];
        }
    }
    
    [self setUnusedViewsHidden:cell :hops];
}

-(void) setExpandedCellValues:(R2RExpandedFlightSegmentCell *)cell :(R2RFlightHop *)flightHop :(NSInteger) hopNumber
{
    UILabel *label;
    
    if (flightHop.lDuration > 0 && hopNumber > 0) //the layover should always be in the second hop but adding this for safety
    {
        R2RAirport *airport = [self.searchStore getAirport:flightHop.sCode];
        
        label = [cell.layoverNameLabels objectAtIndex:(hopNumber -1)];
        [label setText:[NSString stringWithFormat:NSLocalizedString(@"Layover at %@", nil), airport.name]];
        [label setHidden:NO];
        
        label = [cell.layoverDurationLabels objectAtIndex:(hopNumber - 1)];
        [label setText:[R2RStringFormatter formatDurationZeroPadded:flightHop.lDuration]];
        [label setHidden:NO];
    }
    
    R2RAirline *airline = [self.searchStore getAirline:flightHop.airline];
    UIImageView *imageView = [cell.airlineIcons objectAtIndex:hopNumber];
    R2RSprite *sprite = [self.spriteCache getSprite :airline.iconPath :airline.iconOffset :airline.iconSize];
    [self.searchStore.spriteStore setSpriteInView:sprite :imageView];
    [imageView setHidden:NO];
    
    label = [cell.sAirportLabels objectAtIndex:hopNumber];
    [label setText:flightHop.sCode];
    [label setHidden:NO];
    
    label = [cell.tAirportLabels objectAtIndex:hopNumber];
    [label setText:flightHop.tCode];
    [label setHidden:NO];
    
    label = [cell.hopDurationLabels objectAtIndex:hopNumber];
    [label setText:[R2RStringFormatter formatDurationZeroPadded:flightHop.duration]];
    [label setHidden:NO];
}

-(void) setUnusedViewsHidden:(R2RExpandedFlightSegmentCell *) cell: (NSInteger) hops
{
    //1 less layover than stops
    for (int i = hops; i < MAX_FLIGHT_STOPS; i++)
    {
        UILabel *label = [cell.layoverNameLabels objectAtIndex:(i-1)];
        [label setHidden:YES];
        label = [cell.layoverDurationLabels objectAtIndex:(i-1)];
        [label setHidden:YES];
        
        UIImageView *view = [cell.airlineIcons objectAtIndex:i];
        [view setHidden:YES];
        label = [cell.flightNameLabels objectAtIndex:i];
        [label setHidden:YES];
        label = [cell.hopDurationLabels objectAtIndex:i];
        [label setHidden:YES];
        label = [cell.sAirportLabels objectAtIndex:i];
        [label setHidden:YES];
        label = [cell.tAirportLabels objectAtIndex:i];
        [label setHidden:YES];
        label = [cell.joinerLabels objectAtIndex:i];
        [label setHidden:YES];
    }
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{    
    NSIndexPath *prevIndex = self.selectedRowIndex;

    if ([self isSelectedRowIndex:indexPath])
    {
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        self.selectedRowIndex = nil;
    }
    else
    {
        self.selectedRowIndex = indexPath;
    }

    NSMutableArray *indexPaths = [[NSMutableArray alloc] initWithCapacity:2];
    if (prevIndex)
        [indexPaths addObject:prevIndex];
    if (self.selectedRowIndex)
        [indexPaths addObject:self.selectedRowIndex];
    
    [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if([self isSelectedRowIndex:indexPath])
    {
        R2RFlightGroup *flightGroup = [self.flightGroups objectAtIndex:indexPath.section];
        R2RFlightItinerary *flightItinerary = [flightGroup.flights objectAtIndex:indexPath.row];
        R2RFlightLeg *flightLeg = [flightItinerary.legs objectAtIndex:0];
        NSInteger hops = [flightLeg.hops count];
        return (115+(50*(hops-1)));
    }
    
    return 30;
}

-(BOOL) isSelectedRowIndex:(NSIndexPath *)indexPath
{
    return self.selectedRowIndex &&
        indexPath.section == self.selectedRowIndex.section &&
        indexPath.row == self.selectedRowIndex.row;
}

- (IBAction)returnToSearch:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

-(void) sortFlightSegment
{
    self.flightGroups = [[NSMutableArray alloc] init];
    
    for (R2RFlightItinerary *itinerary in flightSegment.itineraries)
    {
        if ([itinerary.legs count] == 0)
        {
            continue;
        }
        
        R2RFlightLeg *leg = [itinerary.legs objectAtIndex:0];
        int hops = [leg.hops count];
        if (hops == 0)
        {
            continue;
        }
        
        R2RFlightGroup *flightGroup = nil;
        
        for (R2RFlightGroup *group in self.flightGroups)
        {
            if (group.hops == hops)
            {
                flightGroup = group;
                break;
            }
        }
        
        if (flightGroup == nil)
        {
            flightGroup = [[R2RFlightGroup alloc] initWithHops:hops];
            [self.flightGroups addObject:flightGroup];
        }
        
        [flightGroup.flights addObject:itinerary];
    }
    
    for (R2RFlightGroup *flightGroup in self.flightGroups)
    {
        [flightGroup.flights sortUsingComparator:^(R2RFlightItinerary *itin1, R2RFlightItinerary *itin2){
            R2RFlightLeg *leg1 = [itin1.legs objectAtIndex:0];
            R2RFlightLeg *leg2 = [itin2.legs objectAtIndex:0];
            R2RFlightHop *hop1 = [leg1.hops objectAtIndex:0];
            R2RFlightHop *hop2 = [leg2.hops objectAtIndex:0];
            return [hop1.sTime compare:hop2.sTime];
        }];
        
        [flightGroup.flights sortUsingComparator:^(R2RFlightItinerary *itin1, R2RFlightItinerary *itin2){
            R2RFlightLeg *leg1 = [itin1.legs objectAtIndex:0];
            R2RFlightLeg *leg2 = [itin2.legs objectAtIndex:0];
            R2RFlightHop *hop1 = [leg1.hops objectAtIndex:0];
            R2RFlightHop *hop2 = [leg2.hops objectAtIndex:0];
            return [hop1.airline compare:hop2.airline];
        }];
    }
}

- (void) showLinkMenu
{
    self.links = [[NSMutableArray alloc] init];
    
    NSIndexPath *indexPath = self.selectedRowIndex;
    
    R2RFlightGroup *flightGroup = [self.flightGroups objectAtIndex:indexPath.section];
    R2RFlightItinerary *flightItinerary = [flightGroup.flights objectAtIndex:indexPath.row];
    R2RFlightLeg *flightLeg = [flightItinerary.legs objectAtIndex:0];
    
    
    self.linkMenuSheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"External Links", nil)
                                                     delegate:self
                                            cancelButtonTitle:nil
                                       destructiveButtonTitle:nil
                                            otherButtonTitles:nil];

    NSMutableArray *airlines = [[NSMutableArray alloc] init];
    
    for (R2RFlightHop *flightHop in flightLeg.hops)
    {
        BOOL isDuplicateAirline = NO;
        for (R2RAirline *airline in airlines)
        {
            if ([flightHop.airline isEqualToString:airline.code])
            {
                isDuplicateAirline = YES;
                break;
            }
        }
        
        if (!isDuplicateAirline)
        {
            R2RAirline *airline = [self.searchStore getAirline:flightHop.airline];
            
            [airlines addObject:airline];
            
            [self.linkMenuSheet addButtonWithTitle:airline.name];
            [self.links addObject:airline.url];
        }
    }
    
    [self.linkMenuSheet addButtonWithTitle:NSLocalizedString(@"cancel", nil)];
    [self.linkMenuSheet setCancelButtonIndex:[airlines count]];
    
    [self.linkMenuSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == [self.links count])
        return;
    
    R2RLog(@"Button %d", buttonIndex);
    NSURL *url = [self.links objectAtIndex:buttonIndex];
    if ([[url absoluteString] length] > 0)
    {
        [[UIApplication sharedApplication] openURL:url];
    }
}

@end
