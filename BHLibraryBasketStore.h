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
- (nullable BHLibraryBasketItem *)itemForPage:(NSInteger)page slot:(NSInteger)slot;
- (void)reload;
@end

NS_ASSUME_NONNULL_END
