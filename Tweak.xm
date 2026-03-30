#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "BHLibraryBasketStore.h"
#import "BHLibraryBasketController.h"

@interface SBIconListView : UIView
@end

static const NSInteger kBHBasketTagBase = 991000;

@interface BHBasketIconView : UIControl
@property (nonatomic, strong) BHLibraryBasketItem *item;
- (instancetype)initWithFrame:(CGRect)frame item:(BHLibraryBasketItem *)item;
@end

@implementation BHBasketIconView {
    UIView *_previewBox;
    UILabel *_titleLabel;
}

- (instancetype)initWithFrame:(CGRect)frame item:(BHLibraryBasketItem *)item {
    self = [super initWithFrame:frame];
    if (self) {
        _item = item;

        CGFloat previewSize = frame.size.width - 12.0;
        _previewBox = [[UIView alloc] initWithFrame:CGRectMake(6.0, 0.0, previewSize, previewSize)];
        _previewBox.backgroundColor = [UIColor secondarySystemBackgroundColor];
        _previewBox.layer.cornerRadius = 19.0;
        _previewBox.clipsToBounds = YES;
        [self addSubview:_previewBox];

        CGFloat innerPadding = 7.0;
        CGFloat cellGap = 6.0;
        CGFloat cell = floor((previewSize - innerPadding * 2.0 - cellGap) / 2.0);

        NSInteger previewCount = MIN(4, (NSInteger)item.bundleIDs.count);
        for (NSInteger i = 0; i < previewCount; i++) {
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
            NSString *bundleID = i < item.bundleIDs.count ? item.bundleIDs[i] : @"";
            miniLabel.text = bundleID.length ? [[bundleID componentsSeparatedByString:@"."] lastObject].uppercaseString : @"APP";
            [iconStub addSubview:miniLabel];
        }

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, CGRectGetMaxY(_previewBox.frame) + 6.0, frame.size.width, 18.0)];
        _titleLabel.textAlignment = NSTextAlignmentCenter;
        _titleLabel.font = [UIFont systemFontOfSize:12.0];
        _titleLabel.text = item.title;
        _titleLabel.numberOfLines = 1;
        [self addSubview:_titleLabel];
    }
    return self;
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

%hook SBIconListView

- (void)layoutSubviews {
    %orig;

    NSInteger pageIndex = BHGuessPageIndexForListView(self);
    NSArray<BHLibraryBasketItem *> *items = [[BHLibraryBasketStore sharedInstance] allItems];

    NSMutableSet<NSNumber *> *validTags = [NSMutableSet set];

    for (BHLibraryBasketItem *item in items) {
        if (item.pageIndex != pageIndex) {
            continue;
        }

        NSInteger tag = kBHBasketTagBase + item.slotIndex;
        [validTags addObject:@(tag)];

        BHBasketIconView *basket = (BHBasketIconView *)[self viewWithTag:tag];
        if (![basket isKindOfClass:[BHBasketIconView class]]) {
            basket = [[BHBasketIconView alloc] initWithFrame:BHFrameForSlotIndex(item.slotIndex) item:item];
            basket.tag = tag;
            [basket addTarget:self action:@selector(_bh_openBasket:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:basket];
        } else {
            basket.frame = BHFrameForSlotIndex(item.slotIndex);
            basket.item = item;
        }
    }

    for (UIView *subview in self.subviews.copy) {
        if (subview.tag >= kBHBasketTagBase && ![validTags containsObject:@(subview.tag)]) {
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

%end
