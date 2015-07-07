//
//  do_ComboBox_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_ComboBox_UIView.h"

#import "doInvokeResult.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doPopListView.h"
#import "doTextHelper.h"

#define CELL_HEIGHT 60.0f

@interface do_ComboBox_UIView ()<PopListViewDataSource, PopListViewDelegate>

@end

@implementation do_ComboBox_UIView
{
    NSArray *_items;
    doPopListView *poplistview;
    
    NSInteger _fontSize;
    UIColor *_fontColor;
    NSString *_fontStyle;
}
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    _items = [NSArray array];
    
    self.userInteractionEnabled = YES;
}
//销毁所有的全局对象
- (void) OnDispose
{
    //自定义的全局属性,view-model(UIModel)类销毁时会递归调用<子view-model(UIModel)>的该方法，将上层的引用切断。所以如果self类有非原生扩展，需主动调用view-model(UIModel)的该方法。(App || Page)-->强引用-->view-model(UIModel)-->强引用-->view
}
//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改,如果添加了非原生的view需要主动调用该view的OnRedraw，递归完成布局。view(OnRedraw)<显示布局>-->调用-->view-model(UIModel)<OnRedraw>
    
    //重新调整视图的x,y,w,h
    [doUIModuleHelper OnRedraw:_model];
    
    poplistview = [[doPopListView alloc] initWithFrame:CGRectZero];
    poplistview.cellHeight = CELL_HEIGHT;
    poplistview.isDisplay = NO;
    poplistview.delegate = self;
    poplistview.datasource = self;
}

#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */
- (void)change_fontColor:(NSString *)newValue
{
    //自己的代码实现
    _fontColor = [doUIModuleHelper GetColorFromString:newValue :[doUIModuleHelper GetColorFromString:[_model GetProperty:@"fontStyle"].DefaultValue :[UIColor blackColor]]];
    self.tintColor = _fontColor;
    if (poplistview.isDisplay) {
        [poplistview reload];
    }
}
- (void)change_fontSize:(NSString *)newValue
{
    //自己的代码实现
    _fontSize = [doUIModuleHelper GetDeviceFontSize:[[doTextHelper Instance] StrToInt:newValue :[[_model GetProperty:@"fontSize"].DefaultValue intValue]] :_model.XZoom :_model.YZoom];
    self.titleLabel.font = [UIFont systemFontOfSize:_fontSize];
    if (poplistview.isDisplay) {
        [poplistview reload];
    }
}
- (void)change_fontStyle:(NSString *)newValue
{
    //自己的代码实现
    _fontStyle = [NSString stringWithFormat:@"%@",newValue];
    CGFloat fontSize = self.titleLabel.font.pointSize;
    [self setFontStyle:self.titleLabel :fontSize];
    [poplistview reload];
}
- (void)change_index:(NSString *)newValue
{
    //自己的代码实现
    poplistview.index = [newValue integerValue];
}
- (void)change_items:(NSString *)newValue
{
    //自己的代码实现
    _items = [newValue componentsSeparatedByString:@","];
    poplistview.items = _items;
    [self resetPoplist];
}

- (void)setFontStyle:(UILabel *)label :(CGFloat)fontSize
{
    //fontStyle
    if (label.text==nil || [label.text isEqualToString:@""]) return;
    NSRange range = {0,[label.text length]};
    NSMutableAttributedString *str = [label.attributedText mutableCopy];
    [str removeAttribute:NSUnderlineStyleAttributeName range:range];
    label.attributedText = str;
    
    if([_fontStyle isEqualToString:@"normal"])
        [label setFont:[UIFont systemFontOfSize:fontSize]];
    else if([_fontStyle isEqualToString:@"bold"])
        [label setFont:[UIFont boldSystemFontOfSize:fontSize]];
    else if([_fontStyle isEqualToString:@"italic"])
        [label setFont:[UIFont italicSystemFontOfSize:fontSize]];
    else if([_fontStyle isEqualToString:@"underline"])
    {
        NSMutableAttributedString *content = [label.attributedText mutableCopy];
        NSRange contentRange = {0,[content length]};
        [content addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:contentRange];
        label.attributedText = content;
        [content endEditing];
    }
}

- (void)resetPoplist
{
    CGRect rect = [UIApplication sharedApplication].keyWindow.bounds;
    CGFloat edage = 40.0f;
    CGFloat xWidth = CGRectGetWidth(rect) - edage;
    CGFloat yHeight = MIN(_items.count*CELL_HEIGHT,CGRectGetHeight(rect)-edage);
    CGFloat yOffset = (CGRectGetHeight(rect) - yHeight)/2.0f;
    poplistview.frame = CGRectMake(20, yOffset, xWidth, yHeight);

    poplistview.listView.frame = CGRectMake(0,0, xWidth, yHeight);
    [poplistview layoutSubviews];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (!poplistview.isDisplay) {
        if (_items.count <= 0) {
            return;
        }
        [self resetPoplist];
        [poplistview show];
    }else
        [poplistview dismiss];
}

#pragma mark - UIPopoverListViewDataSource

- (UITableViewCell *)popListView:(doPopListView *)popoverListView cellForIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"cell";
    UITableViewCell *cell = [popoverListView.listView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:identifier];
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, CGRectGetWidth(cell.contentView.frame)-40, CGRectGetHeight(cell.contentView.frame)-20)];
        label.tag = 999;
        [cell.contentView addSubview:label];
    }
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:999];
    label.font = [UIFont systemFontOfSize:_fontSize];
    label.textColor = _fontColor;
    label.text = [_items objectAtIndex:indexPath.row];
    
    CGFloat fontSize = label.font.pointSize;
    [self setFontStyle:label :fontSize];

    return cell;
}

- (NSInteger)popListView:(doPopListView *)popoverListView numberOfRowsInSection:(NSInteger)section
{
    return _items.count;
}

#pragma mark - UIPopoverListViewDelegate
- (void)popListView:(doPopListView *)popListView didSelectIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell  = [popListView.listView cellForRowAtIndexPath:indexPath];
    [self setTitle:cell.textLabel.text forState:UIControlStateNormal];
    doInvokeResult *_invokeResult = [[doInvokeResult alloc] init:_model.UniqueKey];
    [_invokeResult SetResultInteger:(int)indexPath.row];
    [_model.EventCenter FireEvent:@"selectChanged" :_invokeResult];
}

#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}

@end
