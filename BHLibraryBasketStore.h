#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface BHLibraryBasketItem : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSArray<NSString *> *bundleIDs;
@property (nonatomic, assign) NSInteger pageIndex;
@property (nonatomic, assign) NSInteger slotIndex;
@end

@interface BHLibraryBasketStore : NSObject
+ (instancetype)sharedInstance;
- (NSArray<BHLibraryBasketItem *> *)allItems;
- (NSArray<BHLibraryBasketItem *> *)itemsForPage:(NSInteger)page;
- (nullable BHLibraryBasketItem *)itemForIdentifier:(NSString *)identifier;
- (nullable BHLibraryBasketItem *)itemForPage:(NSInteger)page slot:(NSInteger)slot;
- (NSInteger)nextAvailableSlotForPage:(NSInteger)page;
- (BHLibraryBasketItem *)createBasketOnPage:(NSInteger)page;
- (void)saveOrUpdateItem:(BHLibraryBasketItem *)item;
- (void)removeItemWithIdentifier:(NSString *)identifier;
- (void)reload;
@end

NS_ASSUME_NONNULL_END
