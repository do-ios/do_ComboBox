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
#import "doModuleBase.h"
#import "doJsonHelper.h"
#import "doServiceContainer.h"
#import "doILogEngine.h"


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
    //对齐标识
    NSInteger _alignFlag;
    
    id<doIListData> _dataArrays;
    
    int _no;
}
@synthesize currentIndex=_currentIndex;
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    _items = [NSMutableArray array];
    
    self.userInteractionEnabled = YES;
    [self setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
    [self change_fontColor:[_model GetProperty:@"fontColor"].DefaultValue];
    _currentIndex = 0;
    _no = 0;
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

    UIImage *image = [UIImage imageNamed:@"do_ComboBox_UI.bundle/icon_combo"];


//    icon.contentMode = UIViewContentModeScaleToFill;
    CGRect r = self.bounds;
    CGFloat h = CGRectGetHeight(r);
    CGFloat w = CGRectGetWidth(r);
    CGRect frame = CGRectMake(w-h*0.1, h*0.9, h*0.1, h*0.1);
    UIImageView *icon = [[UIImageView alloc] initWithFrame:frame];
//    icon.backgroundColor  = [UIColor blueColor];
    icon.image = image;
    [self addSubview:icon];
}

#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */
- (void)change_textAlign:(NSString *)newValue
{
    
    if ([newValue isEqualToString:@"left"]) {
        
        [self setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        _alignFlag = 0;
    }
    else if ([newValue isEqualToString:@"center"])
    {
        [self setContentHorizontalAlignment:UIControlContentHorizontalAlignmentCenter];
        _alignFlag = 1;
    }
    else if([newValue isEqualToString:@"right"])
    {
        [self setContentHorizontalAlignment:UIControlContentHorizontalAlignmentRight];
        _alignFlag = 2;
    }
}
- (void)change_fontColor:(NSString *)newValue
{
    //自己的代码实现
    if (self.currentAttributedTitle.length <= 0) {
        NSMutableAttributedString *curTitle = [[NSMutableAttributedString alloc]initWithString:@" "];
        [self setAttributedTitle:curTitle forState:UIControlStateNormal];
    }
    _fontColor = [doUIModuleHelper GetColorFromString:newValue :[doUIModuleHelper GetColorFromString:[_model GetProperty:@"fontColor"].DefaultValue :[UIColor blackColor]]];
    NSMutableAttributedString *attriString = [[NSMutableAttributedString alloc]initWithAttributedString:self.currentAttributedTitle];
    [attriString addAttribute:NSForegroundColorAttributeName
                        value:_fontColor
                        range:NSMakeRange(0, self.currentAttributedTitle.length)];

    [self setAttributedTitle:attriString forState:UIControlStateNormal];
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
//    [self setTextFlag:self.titleLabel :fontSize];
    [self setTextFlags:self.currentAttributedTitle :fontSize];
    [poplistview reload];
}
- (void)setTextFlag:(UILabel *)label :(CGFloat)fontSize
{
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
    [self setAttributedTitle:content forState:UIControlStateNormal];
    [content endEditing];
}
- (void)setTextFlags:(NSAttributedString *)attributedText :(CGFloat)fontSize
{
    NSMutableAttributedString *content = [attributedText mutableCopy];
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
    [self setAttributedTitle:content forState:UIControlStateNormal];
    [content endEditing];
}
- (void)change_index:(NSString *)newValue
{
    //自己的代码实现
    if (!newValue) {
        return;
    }
    NSInteger num = [newValue integerValue];
    NSInteger selIndex = _no;
    
    _currentIndex = num;
    poplistview.index = self.currentIndex;
    [_model SetPropertyValue:@"index" :[@(self.currentIndex) stringValue]];

    if (self.currentIndex == selIndex) {
        return;
    }
    [self resetContent:self.currentIndex];
    doInvokeResult *_invokeResult = [[doInvokeResult alloc] init:_model.UniqueKey];
    [_invokeResult SetResultInteger:(int)self.currentIndex];
    [_model.EventCenter FireEvent:@"selectChanged" :_invokeResult];
    
}
- (NSInteger)currentIndex
{
    NSInteger num = _currentIndex;
    if (_items.count>0) {
        if (num<0) {
            num = 0;
        }else if(num >= _items.count)
            num = _items.count-1;
    }else
        num = 0;
    return num;
}

- (void)change_items:(NSString *)newValue
{
    //自己的代码实现
    if (newValue.length == 0) {
        _items = nil;
        NSAttributedString *attri = [[NSAttributedString alloc]initWithString:@""];
        [self setAttributedTitle:attri forState:UIControlStateNormal];
    }
    else
    {
       _items = [NSMutableArray arrayWithArray:[newValue componentsSeparatedByString:@","]];
    }
    poplistview.items = _items;
    NSString  *iii = [_model GetPropertyValue:@"index"];
    [self resetPoplist];
    doInvokeResult *_invokeResult = [[doInvokeResult alloc] init:_model.UniqueKey];
    if ([iii integerValue] > self.currentIndex) {
        [_invokeResult SetResultInteger:(int)self.currentIndex];
        poplistview.index = self.currentIndex;
        [self resetContent:self.currentIndex];
        [_model SetPropertyValue:@"index" :[@(self.currentIndex) stringValue]];
    }
    else
    {
        [_invokeResult SetResultInteger:(int)[iii integerValue]];
        poplistview.index = [iii integerValue];
        [self resetContent:[iii integerValue]];
        [_model SetPropertyValue:@"index" :iii];
    }
    [_model.EventCenter FireEvent:@"selectChanged" :_invokeResult];
}
- (void)setAttributedTitle:(nullable NSAttributedString *)title forState:(UIControlState)state
{
    _no = self.currentIndex;
    [super setAttributedTitle:title forState:state];
}
- (void)resetContent:(NSInteger )curIndex
{
    if (_items.count > 0) {
        NSRange range = NSMakeRange(0, 1);
        NSDictionary *arrDict = [self.currentAttributedTitle attributesAtIndex:0 effectiveRange:&range];
        [self setAttributedTitle:[[NSAttributedString alloc]initWithString:[_items objectAtIndex:curIndex] attributes:arrDict] forState:UIControlStateNormal];
        CGFloat fontSize = self.titleLabel.font.pointSize;
        [self setFontStyle:self.titleLabel :fontSize];
        [self setTextFlags:self.currentAttributedTitle :fontSize];
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
#pragma mark -
#pragma mark - 同步异步方法的实现
//同步
- (void)bindItems:(NSArray *)parms
{
    NSDictionary * _dictParas = [parms objectAtIndex:0];
    id<doIScriptEngine> _scriptEngine = [parms objectAtIndex:1];
    NSString* _address = [doJsonHelper GetOneText: _dictParas :@"data": nil];
    @try {
        if (_address == nil || _address.length <= 0) [NSException raise:@"doCombox" format:@"未指定相关的doCombox data参数！",nil];
        id bindingModule = [doScriptEngineHelper ParseMultitonModule: _scriptEngine : _address];
        if (bindingModule == nil) [NSException raise:@"doCombox" format:@"data参数无效！",nil];
        if([bindingModule conformsToProtocol:@protocol(doIListData)])
        {
            if(_dataArrays!= bindingModule)
                _dataArrays = bindingModule;
            if ([_dataArrays GetCount]>0) {
                [self refreshItems:parms];
            }
        }
        
    }
    @catch (NSException *exception) {
        [[doServiceContainer Instance].LogEngine WriteError:exception :exception.description];
        doInvokeResult* _result = [[doInvokeResult alloc]init];
        [_result SetException:exception];
        
    }
    
}
- (void)refreshItems:(NSArray *)parms
{
    //清空数据
    [_items removeAllObjects];
    for (int i = 0; i < [_dataArrays GetCount]; i ++) {
        id node = [_dataArrays GetData:i];
        if (![node isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSString *text = [doJsonHelper GetOneText:node :@"text" :@""];
//        if (![_items containsObject:text]) {
//            [_items addObject:text];
//        }
        
        [_items addObject:text];
        
    }
    if (_items.count == 0) { // 若所有数据清空，button label显示空字符串
        self.titleLabel.text = @"";
        
    }
    poplistview.items = _items;
    NSString  *iii = [_model GetPropertyValue:@"index"];
    [self resetPoplist];
    doInvokeResult *_invokeResult = [[doInvokeResult alloc] init:_model.UniqueKey];
    if ([iii integerValue] > self.currentIndex) {
        [_invokeResult SetResultInteger:(int)self.currentIndex];
        poplistview.index = self.currentIndex;
        [self resetContent:self.currentIndex];
        [_model SetPropertyValue:@"index" :[NSString stringWithFormat:@"%ld",(long)self.currentIndex]];
    }
    else
    {
        [_invokeResult SetResultInteger:(int)[iii integerValue]];
        poplistview.index = [iii integerValue];
        [self resetContent:[iii integerValue]];
        [_model SetPropertyValue:@"index" :[NSString stringWithFormat:@"%ld",(long)[iii integerValue]]];
        
    }
    [_model.EventCenter FireEvent:@"selectChanged" :_invokeResult];
}

#pragma mark - UIPopoverListViewDataSource

- (UITableViewCell *)popListView:(doPopListView *)popoverListView cellForIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"cell";
    UITableViewCell *cell = [popoverListView.listView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                      reuseIdentifier:identifier];
        //ipad下cell的width为320
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 10, CGRectGetWidth([UIScreen mainScreen].bounds)-80, CGRectGetHeight(cell.frame)-10)];
        label.tag = 999;
        if (_alignFlag == 1) {
            label.textAlignment = NSTextAlignmentCenter;
        }
        else if(_alignFlag == 2)
        {
            label.textAlignment = NSTextAlignmentRight;
        }
        else
        {
            label.textAlignment = NSTextAlignmentLeft;
        }
        [cell.contentView addSubview:label];
    }
    
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:999];
    label.font = [UIFont systemFontOfSize:_fontSize];
    label.textColor = _fontColor;
    label.text = [_items objectAtIndex:indexPath.row];
    
    CGFloat fontSize = label.font.pointSize;
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
    UILabel *label = (UILabel *)[cell.contentView viewWithTag:999];
    NSRange range = NSMakeRange(0, 1);
    NSDictionary *arrDict = [self.currentAttributedTitle attributesAtIndex:0 effectiveRange:&range];
    [self setAttributedTitle:[[NSAttributedString alloc]initWithString:label.text attributes:arrDict] forState:UIControlStateNormal];
//    [self setAttributedTitle:label.attributedText forState:UIControlStateNormal];
    CGFloat fontSize = label.font.pointSize;
    [self setFontStyle:self.titleLabel :fontSize];
    [self setTextFlag:self.titleLabel :fontSize];
    
    //得到内存中得值
    NSString  *iii = [_model GetPropertyValue:@"index"];
    
    if (indexPath.row == [iii integerValue]) {
        return;
    }
    doInvokeResult *_invokeResult = [[doInvokeResult alloc] init:_model.UniqueKey];
    [_invokeResult SetResultInteger:(int)indexPath.row];
    [_model.EventCenter FireEvent:@"selectChanged" :_invokeResult];
    //设置内存中index得值
    [_model SetPropertyValue:@"index" :[NSString stringWithFormat:@"%ld",(long)indexPath.row]];
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
