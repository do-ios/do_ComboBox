//
//  PoperListView.m
//  Do_Test
//
//  Created by wl on 15/7/6.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "doPopListView.h"
#import <QuartzCore/QuartzCore.h>

//#define FRAME_X_INSET 20.0f
//#define FRAME_Y_INSET 40.0f

@interface doPopListView ()

- (void)defalutInit;
- (void)fadeIn;
- (void)fadeOut;

@end

@implementation doPopListView

@synthesize datasource = _datasource;
@synthesize delegate = _delegate;

@synthesize listView = _listView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self defalutInit];
    }
    return self;
}

- (void)defalutInit
{
    self.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    self.layer.borderWidth = 1.0f;
    self.layer.cornerRadius = 10.0f;
    self.clipsToBounds = YES;

    CGFloat xWidth = self.bounds.size.width;
    
    CGRect tableFrame = CGRectMake(0, 0, xWidth, self.bounds.size.height);
    _listView = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
    _listView.dataSource = self;
    _listView.delegate = self;
    [self addSubview:_listView];

    _overlayView = [[UIControl alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _overlayView.backgroundColor = [UIColor colorWithRed:.16 green:.17 blue:.21 alpha:.5];
    [_overlayView addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setCellHeight:(CGFloat)cellHeight
{
    _listView.rowHeight = cellHeight;
}

- (void)setItems:(NSArray *)items
{
    _items = [items mutableCopy];
    [_listView reloadData];
}

#pragma mark - property
- (void)setIndex:(NSInteger)newValue
{
    NSIndexPath *index = [NSIndexPath indexPathForRow:newValue inSection:0];
    [_listView scrollToRowAtIndexPath:index atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

- (void)reload
{
    [_listView reloadData];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.datasource &&
       [self.datasource respondsToSelector:@selector(popListView:numberOfRowsInSection:)])
    {
        return [self.datasource popListView:self numberOfRowsInSection:section];
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.datasource &&
       [self.datasource respondsToSelector:@selector(popListView:cellForIndexPath:)])
    {
        return [self.datasource popListView:self cellForIndexPath:indexPath];
    }
    return nil;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.delegate &&
       [self.delegate respondsToSelector:@selector(popListView:didSelectIndexPath:)])
    {
        [self.delegate popListView:self didSelectIndexPath:indexPath];
    }
    [self dismiss];
}

#pragma mark - animations

- (void)fadeIn
{
    self.alpha = 0;
    [UIView animateWithDuration:.35 animations:^{
        self.alpha = 1;
    }];
}
- (void)fadeOut
{
    [UIView animateWithDuration:.35 animations:^{\
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (finished) {
            [_overlayView removeFromSuperview];
            [self removeFromSuperview];
        }
    }];
}

- (void)setTitle:(NSString *)title
{
    _titleView.text = title;
}

- (void)show
{
    self.isDisplay = YES;
    UIWindow *keywindow = [[UIApplication sharedApplication] keyWindow];
    [keywindow addSubview:_overlayView];
    [keywindow addSubview:self];
    
    self.center = CGPointMake(keywindow.bounds.size.width/2.0f,
                              keywindow.bounds.size.height/2.0f);
    [_listView reloadData];
    
    [self fadeIn];
}

- (void)dismiss
{
    self.isDisplay = NO;
    [self fadeOut];
}

@end
