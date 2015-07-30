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
#import "doDefines.h"

#define FONT_OBLIQUITY 15.0
#define CELL_HEIGHT 60.0f

@interface do_ComboBox_UIView ()<PopListViewDataSource, PopListViewDelegate>
@property (nonatomic , assign) NSInteger currentIndex;
@end

@implementation do_ComboBox_UIView
{
    NSMutableArray *_items;
    doPopListView *poplistview;
    
    NSInteger _fontSize;
    UIColor *_fontColor;
    NSString *_fontStyle;
    NSString *_myFontFlag;
}
@synthesize currentIndex=_currentIndex;
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    _items = [NSMutableArray array];
    
    self.userInteractionEnabled = YES;

    [self change_fontColor:[_model GetProperty:@"fontColor"].DefaultValue];
    [self change_index:[_model GetProperty:@"index"].DefaultValue];
    [self change_fontStyle:[_model GetProperty:@"fontStyle"].DefaultValue];
    [self change_textFlag:[_model GetProperty:@"textFlag"].DefaultValue];
    [self change_fontSize:[_model GetProperty:@"fontSize"].DefaultValue];
}
//销毁所有的全局对象
- (void) OnDispose
{
    //自定义的全局属性,view-model(UIModel)类销毁时会递归调用<子view-model(UIModel)>的该方法，将上层的引用切断。所以如果self类有非原生扩展，需主动调用view-model(UIModel)的该方法。(App || Page)-->强引用-->view-model(UIModel)-->强引用-->view
    poplistview = nil;
    [_items removeAllObjects];
    _items = nil;
    _model = nil;
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

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetStrokeColorWithColor(context, [UIColor grayColor].CGColor);
    CGContextSetLineWidth(context, 13.0);

    CGPoint sPoints[3];
    CGFloat h = CGRectGetHeight(rect);
    CGFloat w = CGRectGetWidth(rect);
    sPoints[0] =CGPointMake(w-30, h);
    sPoints[1] =CGPointMake(w, h-30);
    sPoints[2] =CGPointMake(w, h);

    CGContextAddLines(context, sPoints, 3);

    CGContextClosePath(context);
    CGContextDrawPath(context, kCGPathFillStroke);
}
- (void)change_fontColor:(NSString *)newValue
{
    //自己的代码实现
    _fontColor = [doUIModuleHelper GetColorFromString:newValue :[doUIModuleHelper GetColorFromString:[_model GetProperty:@"fontColor"].DefaultValue :[UIColor blackColor]]];
    [self setTitleColor:_fontColor forState:UIControlStateNormal];
    if (poplistview.isDisplay) {
        [poplistview reload];
    }
}
- (void)change_fontSize:(NSString *)newValue
{
    //自己的代码实现
    _fontSize = [doUIModuleHelper GetDeviceFontSize:[[doTextHelper Instance] StrToInt:newValue :[[_model GetProperty:@"fontSize"].DefaultValue intValue]] :_model.XZoom :_model.YZoom];
    self.titleLabel.font = [UIFont systemFontOfSize:_fontSize];
    if(_fontStyle)
        [self change_fontStyle:_fontStyle];
    if (_myFontFlag)
        [self change_textFlag:_myFontFlag];
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

- (void)change_textFlag:(NSString *)newValue
{
    //自己的代码实现
    _myFontFlag = [NSString stringWithFormat:@"%@",newValue];

    CGFloat fontSize = self.titleLabel.font.pointSize;
    [self setTextFlag:self.titleLabel :fontSize];
    [poplistview reload];
}
- (void)setTextFlag:(UILabel *)label :(CGFloat)fontSize
{
    if (!IOS_8 && _fontSize < 14) {
        return;
    }
    if (label.text==nil || [label.text isEqualToString:@""]) return;

    NSMutableAttributedString *content = [label.attributedText mutableCopy];
    [content beginEditing];
    NSRange contentRange = {0,[content length]};
    if ([_myFontFlag isEqualToString:@"normal" ]) {
        [content removeAttribute:NSUnderlineStyleAttributeName range:contentRange];
        [content removeAttribute:NSStrikethroughStyleAttributeName range:contentRange];
    }else if ([_myFontFlag isEqualToString:@"underline" ]) {
        [content addAttribute:NSUnderlineStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:contentRange];
    }else if ([_myFontFlag isEqualToString:@"strikethrough" ]) {
        [content addAttribute:NSStrikethroughStyleAttributeName value:[NSNumber numberWithInteger:NSUnderlineStyleSingle] range:contentRange];
    }
    label.attributedText = content;
    [content endEditing];
}

- (void)change_index:(NSString *)newValue
{
    //自己的代码实现
    NSInteger num = [newValue integerValue];
    _currentIndex = num;
    poplistview.index = self.currentIndex;
    [self resetContent];
}
- (NSInteger)currentIndex
{
    NSInteger num = _currentIndex;
    if (_items.count>0) {
        if (num<0) {
            num = 0;
        }else if(num >= _items.count)
            num = _items.count-1;
    }
    return num;
}

- (void)change_items:(NSString *)newValue
{
    //自己的代码实现
    _items = [NSMutableArray arrayWithArray:[newValue componentsSeparatedByString:@","]];
    poplistview.items = _items;

    [self change_index:[@(_currentIndex) stringValue]];
    [self resetContent];

    CGFloat fontSize = self.titleLabel.font.pointSize;
    [self setFontStyle:self.titleLabel :fontSize];
    [self setTextFlag:self.titleLabel :fontSize];

    [self resetPoplist];
    poplistview.index = self.currentIndex;
}
- (void)resetContent
{
    if (_items.count > 0) {
        [self setTitle:[_items objectAtIndex:self.currentIndex] forState:UIControlStateNormal];
    }
}
- (void)setFontStyle:(UILabel *)label :(CGFloat)fontSize
{
    //自己的代码实现
    if (label.text==nil || [label.text isEqualToString:@""]) return;

    if([_fontStyle isEqualToString:@"normal"])
        [label setFont:[UIFont systemFontOfSize:fontSize]];
    else if([_fontStyle isEqualToString:@"bold"])
        [label setFont:[UIFont boldSystemFontOfSize:fontSize]];
    else if([_fontStyle isEqualToString:@"italic"])
    {
        CGAffineTransform matrix =  CGAffineTransformMake(1, 0, tanf(FONT_OBLIQUITY * (CGFloat)M_PI / 180), 1, 0, 0);
        UIFontDescriptor *desc = [ UIFontDescriptor fontDescriptorWithName :[ UIFont systemFontOfSize :fontSize ]. fontName matrix :matrix];
        [label setFont:[ UIFont fontWithDescriptor :desc size :fontSize]];
    }
    else if([_fontStyle isEqualToString:@"bold_italic"]){}
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
    [self setTextFlag:label :fontSize];

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
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:999];
    [self setTitle:label.text forState:UIControlStateNormal];
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
