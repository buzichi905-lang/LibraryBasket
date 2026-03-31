#import "BHLibraryBasketStore.h"

@implementation BHLibraryBasketItem

- (instancetype)copyWithZone:(NSZone *)zone {
    BHLibraryBasketItem *item = [BHLibraryBasketItem new];
    item.identifier = self.identifier;
    item.title = self.title;
    item.bundleIDs = self.bundleIDs;
    item.pageIndex = self.pageIndex;
    item.slotIndex = self.slotIndex;
    return item;
}

@end

@interface BHLibraryBasketStore ()
@property (nonatomic, strong) NSMutableArray<BHLibraryBasketItem *> *items;
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

- (NSDictionary *)dictionaryForItem:(BHLibraryBasketItem *)item {
    return @{
        @"identifier": item.identifier ?: [[NSUUID UUID] UUIDString],
        @"title": item.title ?: @"收纳筐",
        @"bundleIDs": item.bundleIDs ?: @[],
        @"pageIndex": @(item.pageIndex),
        @"slotIndex": @(item.slotIndex)
    };
}

- (void)writeCurrentItems {
    NSMutableArray *raw = [NSMutableArray array];
    for (BHLibraryBasketItem *item in self.items ?: @[]) {
        [raw addObject:[self dictionaryForItem:item]];
    }

    NSDictionary *root = @{ @"items": raw };
    [root writeToFile:[self configPath] atomically:YES];
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

    self.items = parsed;
}

- (NSArray<BHLibraryBasketItem *> *)allItems {
    return self.items.copy ?: @[];
}

- (NSArray<BHLibraryBasketItem *> *)itemsForPage:(NSInteger)page {
    NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(BHLibraryBasketItem *item, NSDictionary *bindings) {
        return item.pageIndex == page;
    }];
    return [self.items filteredArrayUsingPredicate:predicate] ?: @[];
}

- (BHLibraryBasketItem *)itemForIdentifier:(NSString *)identifier {
    for (BHLibraryBasketItem *item in self.items) {
        if ([item.identifier isEqualToString:identifier]) {
            return item;
        }
    }
    return nil;
}

- (BHLibraryBasketItem *)itemForPage:(NSInteger)page slot:(NSInteger)slot {
    for (BHLibraryBasketItem *item in self.items) {
        if (item.pageIndex == page && item.slotIndex == slot) {
            return item;
        }
    }
    return nil;
}

- (NSInteger)nextAvailableSlotForPage:(NSInteger)page {
    NSMutableSet<NSNumber *> *used = [NSMutableSet set];
    for (BHLibraryBasketItem *item in [self itemsForPage:page]) {
        [used addObject:@(item.slotIndex)];
    }

    for (NSInteger idx = 0; idx < 24; idx++) {
        if (![used containsObject:@(idx)]) {
            return idx;
        }
    }
    return 0;
}

- (BHLibraryBasketItem *)createBasketOnPage:(NSInteger)page {
    BHLibraryBasketItem *item = [BHLibraryBasketItem new];
    item.identifier = [[NSUUID UUID] UUIDString];
    item.title = @"新收纳筐";
    item.bundleIDs = @[@"com.apple.Preferences", @"com.apple.mobilesafari"];
    item.pageIndex = page;
    item.slotIndex = [self nextAvailableSlotForPage:page];
    [self.items addObject:item];
    [self writeCurrentItems];
    return item;
}

- (void)saveOrUpdateItem:(BHLibraryBasketItem *)item {
    if (!item.identifier.length) {
        item.identifier = [[NSUUID UUID] UUIDString];
    }

    NSUInteger existingIndex = [self.items indexOfObjectPassingTest:^BOOL(BHLibraryBasketItem *obj, NSUInteger idx, BOOL *stop) {
        return [obj.identifier isEqualToString:item.identifier];
    }];

    if (existingIndex != NSNotFound) {
        self.items[existingIndex] = item;
    } else {
        [self.items addObject:item];
    }
    [self writeCurrentItems];
}

- (void)removeItemWithIdentifier:(NSString *)identifier {
    if (!identifier.length) {
        return;
    }
    NSIndexSet *indexes = [self.items indexesOfObjectsPassingTest:^BOOL(BHLibraryBasketItem *obj, NSUInteger idx, BOOL *stop) {
        return [obj.identifier isEqualToString:identifier];
    }];
    if (indexes.count > 0) {
        [self.items removeObjectsAtIndexes:indexes];
        [self writeCurrentItems];
    }
}

@end
