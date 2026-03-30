#import "BHLibraryBasketController.h"
#import "BHLibraryBasketStore.h"

@interface LSApplicationWorkspace : NSObject
+ (instancetype)defaultWorkspace;
- (BOOL)openApplicationWithBundleID:(NSString *)bundleID;
@end

@interface BHLibraryBasketController ()
@property (nonatomic, strong) BHLibraryBasketItem *item;
@property (nonatomic, strong) UIView *panel;
@end

@implementation BHLibraryBasketController

- (instancetype)initWithItem:(BHLibraryBasketItem *)item {
    self = [super init];
    if (self) {
        _item = item;
        self.modalPresentationStyle = UIModalPresentationOverFullScreen;
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.35];

    UITapGestureRecognizer *dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)];
    [self.view addGestureRecognizer:dismissTap];

    CGFloat panelWidth = MIN(self.view.bounds.size.width - 32.0, 360.0);
    CGFloat panelHeight = MIN(self.view.bounds.size.height - 180.0, 420.0);
    self.panel = [[UIView alloc] initWithFrame:CGRectMake((self.view.bounds.size.width - panelWidth) / 2.0,
                                                          110.0,
                                                          panelWidth,
                                                          panelHeight)];
    self.panel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.panel.layer.cornerRadius = 26.0;
    self.panel.clipsToBounds = YES;
    self.panel.backgroundColor = [UIColor systemBackgroundColor];
    [self.view addSubview:self.panel];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 18.0, panelWidth - 40.0, 30.0)];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    titleLabel.font = [UIFont boldSystemFontOfSize:24.0];
    titleLabel.text = self.item.title;
    [self.panel addSubview:titleLabel];

    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 60.0, panelWidth, panelHeight - 60.0)];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.panel addSubview:scrollView];

    CGFloat padding = 16.0;
    CGFloat gap = 12.0;
    NSInteger columns = 2;
    CGFloat buttonWidth = floor((panelWidth - padding * 2.0 - gap * (columns - 1)) / columns);
    CGFloat buttonHeight = 64.0;

    [self.item.bundleIDs enumerateObjectsUsingBlock:^(NSString *bundleID, NSUInteger idx, BOOL *stop) {
        NSInteger row = idx / columns;
        NSInteger col = idx % columns;

        UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
        button.frame = CGRectMake(padding + col * (buttonWidth + gap),
                                  6.0 + row * (buttonHeight + gap),
                                  buttonWidth,
                                  buttonHeight);
        button.layer.cornerRadius = 16.0;
        button.backgroundColor = [UIColor secondarySystemBackgroundColor];
        [button setTitle:bundleID forState:UIControlStateNormal];
        button.titleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
        button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        button.accessibilityIdentifier = bundleID;
        [button addTarget:self action:@selector(openApp:) forControlEvents:UIControlEventTouchUpInside];
        [scrollView addSubview:button];
    }];

    NSInteger rowCount = (self.item.bundleIDs.count + columns - 1) / columns;
    CGFloat contentHeight = 12.0 + rowCount * (buttonHeight + gap);
    scrollView.contentSize = CGSizeMake(panelWidth, MAX(CGRectGetHeight(scrollView.bounds) + 1.0, contentHeight));
}

- (void)close {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)openApp:(UIButton *)sender {
    NSString *bundleID = sender.accessibilityIdentifier;
    if (bundleID.length == 0) {
        return;
    }

    Class workspaceClass = NSClassFromString(@"LSApplicationWorkspace");
    if (workspaceClass && [workspaceClass respondsToSelector:@selector(defaultWorkspace)]) {
        id workspace = [workspaceClass performSelector:@selector(defaultWorkspace)];
        if ([workspace respondsToSelector:@selector(openApplicationWithBundleID:)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [workspace performSelector:@selector(openApplicationWithBundleID:) withObject:bundleID];
#pragma clang diagnostic pop
        }
    }

    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
