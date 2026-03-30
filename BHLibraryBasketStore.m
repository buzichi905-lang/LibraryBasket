#import "BHLibraryBasketStore.h"

@implementation BHLibraryBasketItem
@end

@interface BHLibraryBasketStore ()
@property (nonatomic, strong) NSArray<BHLibraryBasketItem *> *items;
@end

@implementation BHLibraryBasketStore

+ (instancetype)sharedInstance {
    static BHLibraryBasketStore *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [self new];
        [shared reload];
    });
    return shared;
}

- (NSString *)configPath {
    return @"/var/jb/var/mobile/Library/Preferences/com.buzichi.librarybasket.plist";
}

- (void)reload {
    NSDictionary *root = [NSDictionary dictionaryWithContentsOfFile:[self configPath]];
    NSArray *rawItems = [root isKindOfClass:[NSDictionary class]] ? root[@"items"] : nil;

    NSMutableArray<BHLibraryBasketItem *> *parsed = [NSMutableArray array];
    for (NSDictionary *dict in [rawItems isKindOfClass:[NSArray class]] ? rawItems : @[]) {
        if (![dict isKindOfClass:[NSDictionary class]]) {
            continue;
        }

        BHLibraryBasketItem *item = [BHLibraryBasketItem new];
        item.identifier = [dict[@"identifier"] isKindOfClass:[NSString class]] ? dict[@"identifier"] : [[NSUUID UUID] UUIDString];
        item.title = [dict[@"title"] isKindOfClass:[NSString class]] ? dict[@"title"] : @"收纳筐";
        item.bundleIDs = [dict[@"bundleIDs"] isKindOfClass:[NSArray class]] ? dict[@"bundleIDs"] : @[];
        item.pageIndex = [dict[@"pageIndex"] respondsToSelector:@selector(integerValue)] ? [dict[@"pageIndex"] integerValue] : 0;
        item.slotIndex = [dict[@"slotIndex"] respondsToSelector:@selector(integerValue)] ? [dict[@"slotIndex"] integerValue] : 0;
        [parsed addObject:item];
    }

    self.items = parsed.copy;
}

- (NSArray<BHLibraryBasketItem *> *)allItems {
    return self.items ?: @[];
}

- (BHLibraryBasketItem *)itemForPage:(NSInteger)page slot:(NSInteger)slot {
    for (BHLibraryBasketItem *item in self.items) {
        if (item.pageIndex == page && item.slotIndex == slot) {
            return item;
        }
    }
    return nil;
}

@end
