//
//  MainBoard.h
//  BeeTab_Nav
//
//  Created by again on 12/28/12.
//  Copyright (c) 2012 again. All rights reserved.
//

#import "Bee.h"

@interface Lession4InnerBoard : BeeUIBoard
{
	BeeUIButton *	_button1;
	BeeUIButton *	_button2;
}

AS_SIGNAL( BACK );
AS_SIGNAL( ENTER );

@end

@interface MainBoard : BeeUIBoard
{
    BeeUITabBar *   _tabbar;
    BeeUIStackGroup *   _nav;
}

@end
