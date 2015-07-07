//
//  do_ComboBox_UI.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol do_ComboBox_IView <NSObject>

@required
//属性方法
- (void)change_fontColor:(NSString *)newValue;
- (void)change_fontSize:(NSString *)newValue;
- (void)change_fontStyle:(NSString *)newValue;
- (void)change_index:(NSString *)newValue;
- (void)change_items:(NSString *)newValue;

//同步或异步方法


@end