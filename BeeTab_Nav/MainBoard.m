//
//  MainBoard.m
//  BeeTab_Nav
//
//  Created by again on 12/28/12.
//  Copyright (c) 2012 again. All rights reserved.
//

#import "MainBoard.h"
@implementation Lession4InnerBoard

DEF_SIGNAL( BACK );
DEF_SIGNAL( ENTER );

- (void)handleUISignal:(BeeUISignal *)signal
{
	[super handleUISignal:signal];
}

- (void)handleBeeUIBoard:(BeeUISignal *)signal
{
	[super handleUISignal:signal];
	
	if ( [signal is:BeeUIBoard.CREATE_VIEWS] )
	{
		[self hideNavigationBarAnimated:NO];
		
//		_textView.contentInset = UIEdgeInsetsMake( 0, 0, 44.0f + 20.0f, 0.0f );
		_button1 = [[BeeUIButton alloc] initWithFrame:CGRectZero];
		_button1.backgroundColor = [UIColor blackColor];
		_button1.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
		_button1.stateNormal.title = @"< Back";
		_button1.stateNormal.titleColor = [UIColor whiteColor];
		[_button1 addSignal:Lession4InnerBoard.BACK forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:_button1];
		
		_button2 = [[BeeUIButton alloc] initWithFrame:CGRectZero];
		_button2.backgroundColor = [UIColor blackColor];
		_button2.titleLabel.font = [UIFont boldSystemFontOfSize:12.0f];
		_button2.stateNormal.title = @"Enter >";
		_button2.stateNormal.titleColor = [UIColor whiteColor];
		[_button2 addSignal:Lession4InnerBoard.ENTER forControlEvents:UIControlEventTouchUpInside];
		[self.view addSubview:_button2];
	}
	else if ( [signal is:BeeUIBoard.DELETE_VIEWS] )
	{
		SAFE_RELEASE_SUBVIEW( _button1 );
		SAFE_RELEASE_SUBVIEW( _button2 );
	}
	else if ( [signal is:BeeUIBoard.LAYOUT_VIEWS] )
	{
		CGRect buttonFrame;
		buttonFrame.size.width = (self.viewSize.width - 30.0f) / 2.0f;
		buttonFrame.size.height = 44.0f;
		buttonFrame.origin.x = 10.0f;
		buttonFrame.origin.y = self.viewSize.height - buttonFrame.size.height - 10.0f - 44.0f;
		
		_button1.frame = buttonFrame;
		_button2.frame = CGRectOffset(buttonFrame, buttonFrame.size.width + 10.0f, 0.0f);
	}
}

- (void)handleLession4InnerBoard:(BeeUISignal *)signal
{
	[super handleUISignal:signal];
	
	if ( [signal is:Lession4InnerBoard.ENTER] )
	{
		Lession4InnerBoard * board = [[[Lession4InnerBoard alloc] init] autorelease];
        board.titleString = @"next";
		[self.stack pushBoard:board animated:YES];
        self.stack.navigationBarHidden = NO;
	}
	else if ( [signal is:Lession4InnerBoard.BACK] )
	{
		[self.stack popBoardAnimated:YES];
	}
}

@end

#pragma mark -


@interface MainBoard ()

@end

@implementation MainBoard

- (void)handleUISignal:(BeeUISignal *)signal
{
	[super handleUISignal:signal];
}

- (void)handleBeeUIBoard:(BeeUISignal *)signal
{
	[super handleUISignal:signal];
    
	if ( [signal is:BeeUIBoard.CREATE_VIEWS] )
	{

        _tabbar = [BeeUITabBar spawn];
        [_tabbar addTitle:@"Page 1" tag:0];
        [_tabbar addTitle:@"Page 2" tag:1];
        _tabbar.selectedItem = [_tabbar.items objectAtIndex:0];
        [self.view addSubview:_tabbar];
        _nav = [BeeUIStackGroup stackGroup];
        Lession4InnerBoard *l1 = [[Lession4InnerBoard alloc]init];
//        l1.view.backgroundColor = RGB(200, 200, 200);
        l1.titleString = @"Page 1";
        BeeUIStack *stack1 = [BeeUIStack stack:@"first" firstBoard:l1];
        stack1.navigationBarHidden = NO;
		[_nav append:stack1];
        Lession4InnerBoard *l2 = [[Lession4InnerBoard alloc]init];
//        l2.view.backgroundColor = RGB(100, 100, 100);
        l2.titleString = @"Page 2";
        BeeUIStack *stack2 = [BeeUIStack stack:@"second" firstBoard:l2];
        stack2.navigationBarHidden = NO;
		[_nav append:stack2];
		[_nav present:[_nav.stacks objectAtIndex:0]];
        [self.view addSubview:_nav.view];
	}
	else if ( [signal is:BeeUIBoard.DELETE_VIEWS] )
	{
	}
    else if ( [signal is:BeeUIBoard.LAYOUT_VIEWS] )
	{
		_tabbar.frame = CGRectMake(0, self.view.frame.size.height-44, 320, 44);
        _nav.view.frame = CGRectMake(0, 0, 320, self.view.frame.size.height-44);
	}
}

- (void)handleBeeUITabBar:(BeeUISignal *)signal
{
	if ( [signal is:BeeUITabBar.HIGHLIGHT_CHANGED] )
	{
//		BeeUISegmentedControl * titleView = (BeeUISegmentedControl *)self.titleView;
		[_nav present:[_nav.stacks objectAtIndex:_tabbar.selectedIndex]];
	}
}

@end
