//
//  R2RResultsViewController.m
//  Rome2Rio
//
//  Created by Ash Verdoorn on 6/09/12.
//  Copyright (c) 2012 Rome2Rio. All rights reserved.
//

#import "R2RResultsViewController.h"
#import "R2RDetailViewController.h"
#import "R2RTransitSegmentViewController.h"
#import "R2RWalkDriveSegmentViewController.h"

#import "R2RStatusButton.h"
#import "R2RResultSectionHeader.h"
#import "R2RResultsCell.h"

#import "R2RStringFormatter.h"
#import "R2RSegmentHelper.h"
#import "R2RConstants.h"
#import "R2RSprite.h"

@interface R2RResultsViewController ()

@property (strong, nonatomic) R2RResultSectionHeader *header;
@property (strong, nonatomic) R2RStatusButton *statusButton;

@end

@implementation R2RResultsViewController

@synthesize searchManager, searchStore;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    self.navigationItem.title = NSLocalizedString(@"Results", nil);
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshTitle:) name:@"refreshTitle" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshResults:) name:@"refreshResults" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshStatusMessage:) name:@"refreshStatusMessage" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(refreshSearchMessage:) name:@"refreshSearchMessage" object:nil];
    
    [self.tableView setSectionHeaderHeight:37.0];
    CGRect rect = CGRectMake(0, 0, self.view.bounds.size.width, self.tableView.sectionHeaderHeight);
    
    self.header = [[R2RResultSectionHeader alloc] initWithFrame:rect];

    [self refreshResultsViewTitle];
    
    [self.view setBackgroundColor:[R2RConstants getBackgroundColor]];

    self.statusButton = [[R2RStatusButton alloc] initWithFrame:CGRectMake(0.0, (self.view.bounds.size.height- self.navigationController.navigationBar.bounds.size.height-30), self.view.bounds.size.width, 30.0)];
    [self.statusButton addTarget:self action:@selector(statusButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.statusButton];
    
    UIView *footer = [[UIView alloc] initWithFrame:CGRectZero];
    self.tableView.tableFooterView = footer;
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshTitle" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshResults" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshStatusMessage" object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"refreshSearchMessage" object:nil];
    
    [super viewDidUnload];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    //if there is a status message show it otherwise show search message
    if ([self.searchStore.statusMessage length] > 0)
    {
        [self setStatusMessage:self.searchStore.statusMessage];
    }
    else
    {
        [self setStatusMessage:self.searchStore.searchMessage];
        if ([self.searchManager isSearching]) [self.searchManager setSearchMessage:NSLocalizedString(@"Searching", nil)];
    }
}

-(void) viewWillDisappear:(BOOL)animated
{
    if ([self.searchManager isSearching]) [self.searchManager setSearchMessage:@""];
    [super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - Table view data source

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return self.header;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.searchStore.searchResponse.routes count];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setBackgroundColor:[R2RConstants getCellColor]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    R2RRoute *route = [self.searchStore.searchResponse.routes objectAtIndex:indexPath.row];
    R2RSegmentHelper *segmentHandler  = [[R2RSegmentHelper alloc] init];
    NSString *CellIdentifier = @"ResultsCell";
    
    if ([route.segments count] == 1)
    {
        NSString *kind = [segmentHandler getSegmentKind:[route.segments objectAtIndex:0]];
        if ([kind isEqualToString:@"bus"] || [kind isEqualToString:@"train"] || [kind isEqualToString:@"ferry"])
        {
            CellIdentifier = @"ResultsCellTransit";
        }
        else if ([kind isEqualToString:@"car"] || [kind isEqualToString:@"walk"])
        {
            CellIdentifier = @"ResultsCellWalkDrive";
        }
    }
    
    R2RResultsCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    [cell.resultDescripionLabel setText:route.name];
    [cell.resultDurationLabel setText:[R2RStringFormatter formatDuration:route.duration]];
    
    NSInteger iconCount = 0;
    float xOffset = 0;
    for (id segment in route.segments)
    {
        if (iconCount >= MAX_ICONS) break;
        
        if ([segmentHandler getSegmentIsMajor:segment])
        {
            UIImageView *iconView = [cell.icons objectAtIndex:iconCount];
            
            if (xOffset == 0)
            {
                xOffset = iconView.frame.origin.x;
            }
            
            R2RSprite *sprite = [segmentHandler getSegmentResultSprite:segment];
            
            CGRect iconFrame = CGRectMake(xOffset, iconView.frame.origin.y, sprite.size.width/2, sprite.size.height/2);
            [iconView setFrame:iconFrame];
            
            [self.searchStore.spriteStore setSpriteInView:sprite :iconView];
            
            xOffset = iconView.frame.origin.x + iconView.frame.size.width + 7; //xPos of next icon

            iconCount++;
        }
    }

    cell.iconCount = iconCount;
     
    return cell;
}

#pragma mark - Table view delegate

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showRouteDetails"])
    {
        R2RDetailViewController *detailsViewController = [segue destinationViewController];
        detailsViewController.searchManager = self.searchManager;
        detailsViewController.searchStore = self.searchStore;
        detailsViewController.route = [self.searchStore.searchResponse.routes objectAtIndex:[self.tableView indexPathForSelectedRow].row];
    }
    if ([[segue identifier] isEqualToString:@"showTransitSegment"])
    {
        R2RTransitSegmentViewController *segmentViewController = [segue destinationViewController];
        R2RRoute *route = [self.searchStore.searchResponse.routes objectAtIndex:[self.tableView indexPathForSelectedRow].row];
        segmentViewController.searchManager = self.searchManager;
        segmentViewController.searchStore = self.searchStore;
        segmentViewController.route = route;
        segmentViewController.transitSegment = [route.segments objectAtIndex:0];
    }
    if ([[segue identifier] isEqualToString:@"showWalkDriveSegment"])
    {
        R2RWalkDriveSegmentViewController *segmentViewController = [segue destinationViewController];
        R2RRoute *route = [self.searchStore.searchResponse.routes objectAtIndex:[self.tableView indexPathForSelectedRow].row];
        segmentViewController.searchManager = self.searchManager;
        segmentViewController.searchStore = self.searchStore;
        segmentViewController.route = route;
        segmentViewController.walkDriveSegment = [route.segments objectAtIndex:0];
    }
}

-(void) statusButtonClicked
{
    [self.navigationController popViewControllerAnimated:true];
}

-(void) refreshResultsViewTitle
{

    NSString *from;
    if (self.searchStore.fromPlace)
    {
        from = self.searchStore.fromPlace.shortName;
    }
    else
    {
        from = NSLocalizedString(@"finding", nil);
    }
    NSString *to;
    if (self.searchStore.toPlace)
    {
        to = self.searchStore.toPlace.shortName;
    }
    else
    {
        to = NSLocalizedString(@"finding", nil);
    }
    
    NSString *joiner = NSLocalizedString(@" to ", nil);
    CGSize joinerSize = [joiner sizeWithFont:[UIFont systemFontOfSize:17.0]];
    joinerSize.width += 2;
    CGSize fromSize = [from sizeWithFont:[UIFont systemFontOfSize:17.0]];
    CGSize toSize = [to sizeWithFont:[UIFont systemFontOfSize:17.0]];
    
    NSInteger viewWidth = self.view.bounds.size.width;
    NSInteger fromWidth = fromSize.width;
    NSInteger toWidth = toSize.width;
    
    if (fromSize.width+joinerSize.width+toSize.width > viewWidth)
    {
        fromWidth = (fromSize.width/(fromSize.width+toSize.width))*(viewWidth-joinerSize.width);
        toWidth = (toSize.width/(fromSize.width+toSize.width))*(viewWidth-joinerSize.width);
    }
    
    CGRect fromFrame = self.header.fromLabel.frame;
    fromFrame.size.width = fromWidth;
    fromFrame.origin.x = (viewWidth-(fromWidth+joinerSize.width+toWidth))/2;
    [self.header.fromLabel setFrame:fromFrame];
    
    CGRect joinerFrame = self.header.joinerLabel.frame;
    joinerFrame.size.width = joinerSize.width;
    joinerFrame.origin.x = fromFrame.origin.x + fromFrame.size.width;
    [self.header.joinerLabel setFrame:joinerFrame];
    
    CGRect toFrame = self.header.toLabel.frame;
    toFrame.size.width = toWidth;
    toFrame.origin.x = joinerFrame.origin.x + joinerFrame.size.width;
    [self.header.toLabel setFrame:toFrame];
    
    [self.header.fromLabel setText:from];
    [self.header.toLabel setText:to];
    [self.header.joinerLabel setText:joiner];
    
}

-(void) refreshTitle:(NSNotification *) notification
{
    [self refreshResultsViewTitle];
}

-(void) refreshResults:(NSNotification *) notification
{
    [self.tableView reloadData];
}

-(void) refreshStatusMessage:(NSNotification *) notification
{
    [self setStatusMessage:self.searchStore.statusMessage];
}

-(void) refreshSearchMessage:(NSNotification *) notification
{
    [self setStatusMessage:self.searchStore.searchMessage];
}

-(void) setStatusMessage: (NSString *) message
{
    [self.statusButton setTitle:message forState:UIControlStateNormal];
}

- (IBAction)returnToSearch:(id)sender
{
    [self.navigationController popToRootViewControllerAnimated:YES];
}

@end
