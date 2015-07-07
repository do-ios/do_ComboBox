//
//  do_ComboBox_View.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "do_ComboBox_IView.h"
#import "do_ComboBox_UIModel.h"
#import "doIUIModuleView.h"

@interface do_ComboBox_UIView : UIButton<do_ComboBox_IView, doIUIModuleView>
//可根据具体实现替换UIView
{
	@private
		__weak do_ComboBox_UIModel *_model;
}

@end
