#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "BHLibraryBasketStore.h"
#import "BHLibraryBasketController.h"

@interface SBIconListView : UIView
@end

static const NSInteger kBHBasketTagBase = 991000;
static const NSInteger kBHBasketCreateTag = 994000;

@interface BHBasketIconView : UIControl
@property (nonatomic, strong) BHLibraryBasketItem *item;
- (instancetype)initWithFrame:(CGRect)frame item:(BHLibraryBasketItem *)item;
- (void)refresh;
@end

@implementation BHBasketIconView {
    UIView *_previewBox;
    UILabel *_titleLabel;
}

- (instancetype)initWithFrame:(CGRect)frame item:(BHLibraryBasketItem *)item {
    self = [super initWithFrame:frame];
    if (self) {
        self.item = item;

        CGFloat previewSize = frame.size.width - 12.0;
        _previewBox = [[UIView alloc] initWithFrame:CGRectMake(6.0, 0.0, previewSize, previewSize)];
        _previewBox.backgroundColor = [UIColor secondarySystemBackgroundColor];
        _previewBox.layer.cornerRadius = 19.0;
        _previewBox.clipsToBounds = YES;
        [self addSubview:_previewBox];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(_previewBox.frame) + 6.0, frame.size.width, 18.0)];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:12.0];
        _titleLabel.numberOfLines = 1;
        [self addSubview:_titleLabel];

        [self refresh];
    }
    return self;
}

- (void)setItem:(BHLibraryBasketItem *)item {
    _item = item;
    [self refresh];
}

- (void)refresh {
    if (!_previewBox || !_titleLabel) {
        return;
    }

    for (UIView *subview in _previewBox.subviews.copy) {
        [subview removeFromSuperview];
    }

    _titleLabel.text = self.item.title ?: @"收纳筐";

    CGFloat previewSize = _previewBox.bounds.size.width;
    CGFloat innerPadding = 7.0;
    CGFloat cellGap = 6.0;
    CGFloat cell = floor((previewSize - innerPadding * 2.0 - cellGap) / 2.0);

    NSInteger previewCount = MIN(4, (NSInteger)self.item.bundleIDs.count);
    for (NSInteger i = 0; i < MAX(1, previewCount); i++) {
        NSInteger row = i / 2;
        NSInteger col = i % 2;
        UIView *iconStub = [[UIView alloc] initWithFrame:CGRectMake(innerPadding + col * (cell + cellGap),
                                                                   innerPadding + row * (cell + cellGap),
                                                                   cell,
                                                                   cell)];
        iconStub.backgroundColor = [UIColor tertiarySystemFillColor];
        iconStub.layer.cornerRadius = 13.0;
        [_previewBox addSubview:iconStub];

        UILabel *miniLabel = [[UILabel alloc] initWithFrame:iconStub.bounds];
        miniLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        miniLabel.font = [UIFont systemFontOfSize:9.0 weight:UIFontWeightSemibold];
        miniLabel.textAlignment = NSTextAlignmentCenter;
        miniLabel.textColor = [UIColor secondaryLabelColor];
        NSString *bundleID = i < self.item.bundleIDs.count ? self.item.bundleIDs[i] : @"+";
        miniLabel.text = bundleID.length ? [[bundleID componentsSeparatedByString:@"."] lastObject].uppercaseString : @"APP";
        [iconStub addSubview:miniLabel];
    }
}

@end

static UIViewController *BHTopMostController(void) {
    UIWindow *targetWindow = nil;
    for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (![scene isKindOfClass:[UIWindowScene class]]) {
            continue;
        }
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) {
                targetWindow = window;
                break;
            }
        }
        if (targetWindow) {
            break;
        }
    }

    UIViewController *vc = targetWindow.rootViewController;
    while (vc.presentedViewController) {
        vc = vc.presentedViewController;
    }
    return vc;
}

static NSInteger BHGuessPageIndexForListView(UIView *listView) {
    id candidate = nil;
    @try {
        candidate = [listView valueForKey:@"iconListIndex"];
    } @catch (__unused NSException *e) {}

    if ([candidate respondsToSelector:@selector(integerValue)]) {
        return [candidate integerValue];
    }
    return 0;
}

static CGRect BHFrameForSlotIndex(NSInteger slotIndex) {
    CGFloat iconWidth = 76.0;
    CGFloat iconHeight = 94.0;
    CGFloat startX = 20.0;
    CGFloat startY = 18.0;
    CGFloat gapX = 14.0;
    CGFloat gapY = 18.0;
    NSInteger columns = 4;

    NSInteger row = MAX(0, (int)(slotIndex / columns));
    NSInteger col = MAX(0, (int)(slotIndex % columns));
    return CGRectMake(startX + col * (iconWidth + gapX),
                      startY + row * (iconHeight + gapY),
                      iconWidth,
                      iconHeight);
}

static NSArray<NSString *> *BHSanitizedBundleList(NSString *rawText) {
    NSMutableArray<NSString *> *result = [NSMutableArray array];
    NSCharacterSet *separatorSet = [NSCharacterSet characterSetWithCharactersInString:@",\n;，； "];
    NSArray<NSString *> *parts = [rawText componentsSeparatedByCharactersInSet:separatorSet];
    for (NSString *part in parts) {
        NSString *trimmed = [part stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length > 0) {
            [result addObject:trimmed];
        }
    }
    return result.copy;
}

static void BHShowQuickTips(void) {
    UIViewController *top = BHTopMostController();
    if (!top) return;

    UIAlertController *tips = [UIAlertController alertControllerWithTitle:@"LibraryBasket 手势"
                                                                  message:@"点按：打开收纳筐\n长按收纳筐：编辑标题和 bundleID\n双击桌面空白处：新建收纳筐并刷新"
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [tips addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:nil]];
    [top presentViewController:tips animated:YES completion:nil];
}

static void BHPresentEditMenu(BHLibraryBasketItem *item, UIView *hostView) {
    UIViewController *top = BHTopMostController();
    if (!top || !item) {
        return;
    }

    UIAlertController *sheet = [UIAlertController alertControllerWithTitle:item.title ?: @"收纳筐"
                                                                   message:@"编辑这个收纳筐"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    UIAlertAction *renameAction = [UIAlertAction actionWithTitle:@"改标题" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        UIViewController *top2 = BHTopMostController();
        if (!top2) return;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"修改标题"
                                                                       message:@"输入新的收纳筐标题"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.text = item.title;
            textField.placeholder = @"例如：社交 / 工具 / 学习";
        }];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *saveAction) {
            NSString *title = [alert.textFields.firstObject.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            item.title = title.length ? title : @"收纳筐";
            [[BHLibraryBasketStore sharedInstance] saveOrUpdateItem:item];
            [hostView setNeedsLayout];
            [hostView layoutIfNeeded];
        }]];
        [top2 presentViewController:alert animated:YES completion:nil];
    }];

    UIAlertAction *bundleAction = [UIAlertAction actionWithTitle:@"编辑 App 列表" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        UIViewController *top2 = BHTopMostController();
        if (!top2) return;
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"编辑 bundleID"
                                                                       message:@"用逗号或换行分隔，例如：\ncom.tencent.xin\ncom.apple.mobilesafari"
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.text = [item.bundleIDs componentsJoinedByString:@", "];
            textField.placeholder = @"com.tencent.xin, com.apple.MobileSMS";
        }];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"保存" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *saveAction) {
            NSArray<NSString *> *bundleIDs = BHSanitizedBundleList(alert.textFields.firstObject.text ?: @"");
            item.bundleIDs = bundleIDs;
            [[BHLibraryBasketStore sharedInstance] saveOrUpdateItem:item];
            [hostView setNeedsLayout];
            [hostView layoutIfNeeded];
        }]];
        [top2 presentViewController:alert animated:YES completion:nil];
    }];

    UIAlertAction *deleteAction = [UIAlertAction actionWithTitle:@"删除收纳筐" style:UIAlertActionStyleDestructive handler:^(__unused UIAlertAction *action) {
        [[BHLibraryBasketStore sharedInstance] removeItemWithIdentifier:item.identifier];
        [hostView setNeedsLayout];
        [hostView layoutIfNeeded];
    }];

    UIAlertAction *tipsAction = [UIAlertAction actionWithTitle:@"查看手势说明" style:UIAlertActionStyleDefault handler:^(__unused UIAlertAction *action) {
        BHShowQuickTips();
    }];

    [sheet addAction:renameAction];
    [sheet addAction:bundleAction];
    [sheet addAction:deleteAction];
    [sheet addAction:tipsAction];
    [sheet addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    UIPopoverPresentationController *popover = sheet.popoverPresentationController;
    if (popover && hostView) {
        popover.sourceView = hostView;
        popover.sourceRect = hostView.bounds;
    }

    [top presentViewController:sheet animated:YES completion:nil];
}

%hook SBIconListView

- (void)layoutSubviews {
    %orig;

    NSInteger pageIndex = BHGuessPageIndexForListView(self);
    NSArray<BHLibraryBasketItem *> *items = [[BHLibraryBasketStore sharedInstance] itemsForPage:pageIndex];
    NSMutableSet<NSNumber *> *validTags = [NSMutableSet set];

    objc_setAssociatedObject(self, "bh_pageIndex", @(pageIndex), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    UITapGestureRecognizer *doubleTap = objc_getAssociatedObject(self, "bh_createBasketDoubleTap");
    if (!doubleTap) {
        doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_bh_createBasketFromGesture:)];
        doubleTap.numberOfTapsRequired = 2;
        doubleTap.cancelsTouchesInView = NO;
        [self addGestureRecognizer:doubleTap];
        objc_setAssociatedObject(self, "bh_createBasketDoubleTap", doubleTap, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    UILongPressGestureRecognizer *helpLongPress = objc_getAssociatedObject(self, "bh_helpLongPress");
    if (!helpLongPress) {
        helpLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_bh_showTipsFromGesture:)];
        helpLongPress.minimumPressDuration = 1.0;
        helpLongPress.cancelsTouchesInView = NO;
        [self addGestureRecognizer:helpLongPress];
        objc_setAssociatedObject(self, "bh_helpLongPress", helpLongPress, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    for (BHLibraryBasketItem *item in items) {
        NSInteger tag = kBHBasketTagBase + item.slotIndex;
        [validTags addObject:@(tag)];

        BHBasketIconView *basket = (BHBasketIconView *)[self viewWithTag:tag];
        if (![basket isKindOfClass:[BHBasketIconView class]]) {
            basket = [[BHBasketIconView alloc] initWithFrame:BHFrameForSlotIndex(item.slotIndex) item:item];
            basket.tag = tag;
            [basket addTarget:self action:@selector(_bh_openBasket:) forControlEvents:UIControlEventTouchUpInside];

            UILongPressGestureRecognizer *iconLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_bh_editBasketFromGesture:)];
            [basket addGestureRecognizer:iconLongPress];
            [self addSubview:basket];
        } else {
            basket.frame = BHFrameForSlotIndex(item.slotIndex);
            basket.item = item;
            [basket refresh];
        }
    }

    for (UIView *subview in self.subviews.copy) {
        if (subview.tag >= kBHBasketTagBase && subview.tag < kBHBasketCreateTag && ![validTags containsObject:@(subview.tag)]) {
            [subview removeFromSuperview];
        }
    }
}

%new
- (void)_bh_openBasket:(BHBasketIconView *)sender {
    if (!sender.item) {
        return;
    }
    UIViewController *top = BHTopMostController();
    if (!top) {
        return;
    }
    BHLibraryBasketController *controller = [[BHLibraryBasketController alloc] initWithItem:sender.item];
    [top presentViewController:controller animated:YES completion:nil];
}

%new
- (void)_bh_editBasketFromGesture:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) {
        return;
    }
    if (![gesture.view isKindOfClass:[BHBasketIconView class]]) {
        return;
    }
    BHBasketIconView *basket = (BHBasketIconView *)gesture.view;
    BHPresentEditMenu(basket.item, self);
}

%new
- (void)_bh_createBasketFromGesture:(UITapGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateRecognized) {
        return;
    }

    CGPoint point = [gesture locationInView:self];
    UIView *hitView = [self hitTest:point withEvent:nil];
    if ([hitView isKindOfClass:[BHBasketIconView class]] || [hitView.superview isKindOfClass:[BHBasketIconView class]]) {
        return;
    }

    NSInteger pageIndex = [objc_getAssociatedObject(self, "bh_pageIndex") integerValue];
    BHLibraryBasketItem *item = [[BHLibraryBasketStore sharedInstance] createBasketOnPage:pageIndex];
    [self setNeedsLayout];
    [self layoutIfNeeded];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        BHPresentEditMenu(item, self);
    });
}

%new
- (void)_bh_showTipsFromGesture:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) {
        return;
    }
    CGPoint point = [gesture locationInView:self];
    UIView *hitView = [self hitTest:point withEvent:nil];
    if ([hitView isKindOfClass:[BHBasketIconView class]] || [hitView.superview isKindOfClass:[BHBasketIconView class]]) {
        return;
    }
    BHShowQuickTips();
}

%end
