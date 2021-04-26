#import <UIKit/UIKit.h>


/////////////// INTERFACES ///////////

@interface SSServerClub: NSObject
	@property (nonatomic,copy) NSString* name;
@end


@interface SSServerChannel: NSObject
	@property (nonatomic,copy) NSString* topic;
	@property (nonatomic,copy) SSServerClub* club;
@end


@interface SSServerChannelInFeed: SSServerChannel
@end


@interface SSServerEvent: NSObject
	@property (nonatomic,copy) NSString* name;
	@property (nonatomic,copy) NSString* eventDescription;
	@property (nonatomic,copy) SSServerClub* club;
@end


@interface ChannelsTableViewDataSource: NSObject
	-(void)updateChannels:(NSMutableArray*)channels events:(NSMutableArray*)events featuredEvent:(id)featuredEvent;
@end


@interface ChannelsTableView: UIView <UISearchBarDelegate>
	@property (nonatomic,copy) ChannelsTableViewDataSource* dataSource;
	@property (nonatomic,copy) UITableView *tableView;

	-(void)reloadData;
	-(void)refreshAction;
@end


@interface ChannelListViewController: UIViewController
	@property (nonatomic,copy) ChannelsTableView *channelsTableView;
@end










//////// NEW VARAIABLES ////////

static NSMutableArray* channelBackup;
static NSMutableArray* eventBackup;
static id featuredEventBackup;
static NSString* currentFilter = @"";



/////////////// HOOKS ///////////

%hook ChannelsTableViewDataSource
-(void)updateChannels:(NSMutableArray*)channels events:(NSMutableArray*)events featuredEvent:(id)featuredEvent {
	
	// make a copy of the data before we filter it
	channelBackup = [[NSMutableArray alloc] initWithArray: channels copyItems:NO];
	eventBackup = [[NSMutableArray alloc] initWithArray: events copyItems:NO];
	featuredEventBackup = featuredEvent;

	if (![currentFilter isEqualToString: @""]) {

		//do filtering and create new mutable arrays based on filtered data
		NSMutableArray *filteredChannels = [[NSMutableArray alloc] init];
		NSMutableArray *filteredEvents = [[NSMutableArray alloc] init];

		for (SSServerChannelInFeed *channel in channels) {
			if([[channel.topic lowercaseString] containsString:currentFilter]) {
				[filteredChannels addObject: channel];
			}
		}

		for (SSServerEvent *event in events) {
			if([[event.name lowercaseString] containsString:currentFilter]) {
				[filteredEvents addObject: event];
			}
		}

		%orig(filteredChannels, filteredEvents, featuredEvent);
	} else {
		// no filter
		%orig(channels, events, featuredEvent);
	}

}
%end




%hook ChannelsTableView

	- (void)layoutSubviews {
		%orig;
		ChannelsTableView *origView= (ChannelsTableView*)self;	

		if (origView.tableView != nil && origView.tableView.tableHeaderView == nil) {

			///// SETUP SEARCH BAR /////

			int screenWidth = self.frame.size.width;

			ChannelsTableView *origView= (ChannelsTableView*)self;	

			UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, screenWidth, 50)];

			UISearchBar *bar = [[UISearchBar alloc] initWithFrame:CGRectMake(8, 0, screenWidth - 16, 59)];
			bar.backgroundImage = [[UIImage alloc] init];
			bar.barTintColor = [UIColor clearColor];
			bar.backgroundColor = [UIColor clearColor];
			bar.placeholder = @"Filter by Topic";
			bar.delegate = self;

			[header addSubview: bar];
			origView.tableView.tableHeaderView = header;
			origView.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
		}
	}



	//// NEW DELEGATE METHODS FOR SEARCHBAR ///////

	%new
	- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
		
		// dimiss keyboard when search is pressed
		[[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder) to:nil from:nil forEvent:nil];
	}

	%new
	- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {

		// update global filter text on every keypress
		currentFilter = [searchText lowercaseString];

		// force a table refresh
		ChannelsTableView *origView= (ChannelsTableView*)self;	
		[origView.dataSource updateChannels:channelBackup events:eventBackup featuredEvent:featuredEventBackup];
	}

%end



//////// SWIFT CLASS MAPPING ////////

%ctor {
    %init(ChannelsTableViewDataSource = objc_getClass("clubhouse.ChannelsTableViewDataSource"));
}