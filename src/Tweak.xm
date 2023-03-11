// See http://iphonedevwiki.net/index.php/Logos

 
#import <UIKit/UIKit.h>
#import <objc/objc-runtime.h>
#import <Foundation/Foundation.h>

#import "PushPackage.h"
#import "GJIMMessageModel.h"
#import "GJIMSessionService.h"
#import "GJIMMessageService.h"
#import "GJIMDBService.h"
#import "GJIMSessionToken.h"

#import "BDEncrypt.h"
#import "BDChatBasicCell.h"
#import "BDChatTextAndFaceCellPrivateOther.h"
#import "BDChatImageCellPrivateOther.h"

%hook GJIMSessionService
- (void)addMessageService:(id)arg1 { %log; %orig; }
- (void)deleteMessage:(id)arg1 { %log; %orig; }
- (void)updateMessage:(id)arg1 { %log; %orig; }
- (void)addMessages:(id)arg1 { %log; %orig; }
- (void)addMessage:(id)arg1 { %log; %orig; }

- (id)p_handlePushPackage:(PushPackage*)arg1{
    %log;
    NSLog(@"====== p_handlePushPackage arg1: %@", arg1);
    
    // 1:文本,2:图片,24:闪照,55:撤回
   if(arg1.messageType == 24){
       arg1.contents = [objc_getClass("BDEncrypt") decryptVideoUrl:arg1.contents];
        arg1.messageType = 2;
        arg1.msgExtra = @{@"tip": @"[对方发送了一张闪照，已自动转换为普通照片]"};
        [self addSystemChat:arg1.msgExtra[@"tip"]];
   }
   if(arg1.messageType == 55){
       GJIMSessionToken *token = [objc_getClass("GJIMSessionToken") gji_sessionTokenWithId: arg1.sessionId type:2];
       [objc_getClass("GJIMDBService") gji_getMessagesWithToken:token complete:^(id data) {
           for (GJIMMessageModel *msg in data) {
               if (msg.msgId == arg1.messageId) {
                   GJIMMessageModel *origMsg = msg;
                   [self updateMessage:origMsg];
                    origMsg.msgExtra = @{@"tip":@"[已拦截到对方撤回该消息]"};
                   [self addSystemChat:origMsg.msgExtra[@"tip"]];
                   return;
               }
           }
       }];
       return nil;
   }

    id res = %orig;
    NSLog(@"====== p_handlePushPackage res: %@", res);
    return res;
}

%new
- (void)addSystemChat:(NSString *)text {
    // TODO
    NSLog(@"====== addSystemChat text: %@",text);
}

%end




%hook BDChatTextAndFaceCellPrivateOther

- (id)contentView { 
    %log; 

    UIView *cv = %orig; 

    GJIMMessageModel *msg = [[self message] copy];
    if (msg == nil || msg.msgId == 0) {
        return cv;
    }
 
    CGFloat x = [cv subviews][2].frame.origin.x;
    CGFloat y = cv.frame.size.height-12;
    CGFloat width = cv.frame.size.width;
    CGFloat height = 12;
    CGRect frame = CGRectMake(x, y, width, height);
    
    UILabel *tipLabel = [self viewWithTag:6666];
    if(tipLabel == nil){
        tipLabel = [[UILabel alloc] init];
    }
    
    tipLabel.tag = 6666;
    tipLabel.text = msg.msgExtra[@"tip"];
    tipLabel.textColor = [UIColor grayColor];
    [tipLabel setFrame:frame];
    [tipLabel setFont:[UIFont systemFontOfSize:9]];
    [self addSubview:tipLabel];

    return cv; 
}

%end

 

%hook BDChatImageCellPrivateOther

- (id)contentView { 
    %log; 
    
    UIView *cv = %orig; 

    GJIMMessageModel *msg = [[self message] copy];
    if (msg == nil || msg.msgId == 0) {
        return cv;
    }
 
    CGFloat x = [cv subviews][2].frame.origin.x;
    CGFloat y = cv.frame.size.height-12;
    CGRect frame = CGRectMake(x, y, cv.frame.size.width, 12);
    
    UILabel *tipLabel = [self viewWithTag:6666];
    if(tipLabel == nil){
        tipLabel = [[UILabel alloc] init];
    }
    
    tipLabel.tag = 6666;
    tipLabel.text = msg.msgExtra[@"tip"];
    tipLabel.textColor = [UIColor grayColor];
    [tipLabel setFrame:frame];
    [tipLabel setFont:[UIFont systemFontOfSize:9]];
    [self addSubview:tipLabel];

    // UIView *v1 =[cv subviews][2];
    // [v1 setFrame: CGRectMake(v1.frame.origin.x, v1.frame.origin.y, v1.frame.size.width, v1.frame.size.height-15)];

    return cv; 
}

%end


