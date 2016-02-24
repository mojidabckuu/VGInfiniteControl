//
//  VGViewController.m
//  VGInfiniteControl
//
//  Created by Vlad Gorbenko on 02/24/2016.
//  Copyright (c) 2016 Vlad Gorbenko. All rights reserved.
//

#import "VGViewController.h"

#import "VGInfiniteControl.h"

@interface VGViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSMutableArray *dataSource;

@end

@implementation VGViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self setupDataSource];
    
    //    UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
    //    [self.tableView addSubview:refreshControl];
    //
    //    [refreshControl addTarget:self action:@selector(refresh:) forControlEvents:UIControlEventValueChanged];
    
    VGInfiniteControl *infiniteControl = [[VGInfiniteControl alloc] init];
    [self.tableView addSubview:infiniteControl];
    
    [infiniteControl addTarget:self action:@selector(loadMore:) forControlEvents:UIControlEventValueChanged];
}

- (void)refresh:(UIRefreshControl *)refreshControl {
    NSLog(@"refresh");
}

- (void)loadMore:(VGInfiniteControl *)infiniteControl {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [infiniteControl stopAnimating];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        
    });
}

- (void)viewDidAppear:(BOOL)animated {
    //    [tableView triggerPullToRefresh];
    [super viewDidAppear:animated];
}

#pragma mark - Actions

- (void)setupDataSource {
    self.dataSource = [NSMutableArray array];
    for(int i=0; i<15; i++)
        [self.dataSource addObject:[NSDate dateWithTimeIntervalSinceNow:-(i*90)]];
}

- (void)insertRowAtTop {
    __weak VGViewController *welf = self;
    
    int64_t delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [welf.tableView beginUpdates];
        [welf.dataSource insertObject:[NSDate date] atIndex:0];
        [welf.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
        [welf.tableView endUpdates];
    });
}


- (void)insertRowAtBottom {
    __weak VGViewController *welf = self;
    
    int64_t delayInSeconds = 2.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [welf.tableView beginUpdates];
        [welf.dataSource addObject:[welf.dataSource.lastObject dateByAddingTimeInterval:-90]];
        [welf.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:welf.dataSource.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
        [welf.tableView endUpdates];
    });
}
#pragma mark -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataSource.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"Cell";
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:identifier];
    
    if (cell == nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    
    NSDate *date = [self.dataSource objectAtIndex:indexPath.row];
    cell.textLabel.text = [NSDateFormatter localizedStringFromDate:date dateStyle:NSDateFormatterNoStyle timeStyle:NSDateFormatterMediumStyle];
    return cell;
}

@end
