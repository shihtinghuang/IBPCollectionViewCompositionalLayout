//
//  IBPCompositionalLayoutSupport.m
//  IBPCollectionViewCompositionalLayout
//
//  Created by s-huang on 2021/01/06.
//  Copyright © 2021 Kishikawa Katsumi. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import <objc/NSObjCRuntime.h>


#import "IBPCompositionalLayoutSupport.h"
#import "IBPCollectionViewOrthogonalScrollerEmbeddedScrollView.h"
#import "IBPNSCollectionLayoutSection_Private.h"
#import "IBPNSCollectionLayoutGroup_Private.h"
#import "IBPUICollectionViewCompositionalLayout.h"

@interface IBPOrthogonalContainerCell : UICollectionViewCell
@property (nonatomic, strong) UICollectionView* scrollView;
@end

@implementation IBPOrthogonalContainerCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}

- (void)configureSection:(UICollectionView *)scrollView {
    [_scrollView removeFromSuperview];

    [self.contentView setAutoresizesSubviews: true];
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    scrollView.center = self.contentView.center;
    [self.contentView addSubview:scrollView];
    _scrollView = scrollView;
}

- (void)configureSectionWithResuedView:(UICollectionView*)scrollView {
    if(!_scrollView) {
        [self.contentView setAutoresizesSubviews: true];
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        scrollView.center = self.contentView.center;
        [self.contentView addSubview:scrollView];
        _scrollView = scrollView;
    } else {
        NSArray *visibleIndexPathes = [_scrollView indexPathsForVisibleItems];
        NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
        for(int i=0;i<visibleIndexPathes.count;i++) {
            [indexSet addIndex:[visibleIndexPathes[i] section]];
        }
        [_scrollView reloadSections:indexSet];
    }
}

@end

@interface IBPCompositionLayoutableCollectionView : UICollectionView

@end

@implementation IBPCompositionLayoutableCollectionView

// TODO: Handle getting cell from sub cells
- (UICollectionViewCell *)cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    return [super cellForItemAtIndexPath:indexPath];
}

@end



@interface IBPCompositionLayoutableCollectionViewDataSource() {
    id<UICollectionViewDataSource> _dataSource;
}

//@property (nonatomic, weak) id<UICollectionViewDataSource> _dataSource;
@property (nonatomic, weak) id<UICollectionViewDataSourcePrefetching> prefetchingDataSource;
@property (nonatomic, weak) id<IBPUICollectionViewCompositionalLayoutProvider> layout;
@end

@implementation IBPCompositionLayoutableCollectionViewDataSource {
    bool _isContainerCellRegistered;
}

- (instancetype)initWithDataSource:(id<UICollectionViewDataSource>)dataSource prefetchDataSource:(id<UICollectionViewDataSourcePrefetching>)prefetchingDataSource layout:(id<IBPUICollectionViewCompositionalLayoutProvider>)layout {
    self = [super init];
    _dataSource = dataSource;
    self.prefetchingDataSource = prefetchingDataSource;
    self.layout = layout;
    return self;
}


// MARK: datasource protocol relay

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    if([_dataSource respondsToSelector:@selector(numberOfSectionsInCollectionView:)]) {
        return [_dataSource numberOfSectionsInCollectionView:collectionView];
    } else {
        return 1;
    }
}

- (nonnull __kindof UICollectionViewCell *)collectionView:(nonnull UICollectionView *)collectionView cellForItemAtIndexPath:(nonnull NSIndexPath *)indexPath {
    if (_layout) {
        IBPNSCollectionLayoutSection *layoutSection = [_layout layoutSectionAtSection:indexPath.section];
        if(layoutSection.scrollsOrthogonally) {
            NSString *containerCellidentifier = @"IBPOrthogonalContainerCell";
            if(!_isContainerCellRegistered) {
                // Register cell
                [collectionView registerClass:[IBPOrthogonalContainerCell class] forCellWithReuseIdentifier:containerCellidentifier];
                _isContainerCellRegistered = true;
            }

            IBPOrthogonalContainerCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:containerCellidentifier forIndexPath:indexPath];
            UICollectionView *scrollView = [_layout getOrthogonalScrollViewForSection:layoutSection sectionIndex:indexPath.section collectionView:collectionView];
            UICollectionViewLayoutAttributes *attributes = [_layout layoutAttributesForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:indexPath.section]];
            scrollView.frame = CGRectMake(0, 0, attributes.frame.size.width, attributes.frame.size.height);

            UICollectionViewLayout* cachedLayout = [_layout getCachedCollectionViewLayoutWithSectionIndex:indexPath.section];
            if(cachedLayout) {
                scrollView.collectionViewLayout = cachedLayout;
            }

            [cell configureSection:scrollView];

            return cell;
        }
    }
    return [_dataSource collectionView:collectionView cellForItemAtIndexPath:indexPath];
}

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_dataSource collectionView:collectionView numberOfItemsInSection:section];
}

- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    if([_dataSource respondsToSelector:@selector(collectionView:canMoveItemAtIndexPath:)]) {
        return [_dataSource collectionView:collectionView canMoveItemAtIndexPath:indexPath];
    } else {
        return false;
    }
}

- (NSIndexPath *)collectionView:(UICollectionView *)collectionView indexPathForIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    if([_dataSource respondsToSelector:@selector(collectionView:indexPathForIndexTitle:atIndex:)]) {
        return [_dataSource collectionView:collectionView indexPathForIndexTitle:title atIndex:index];
    } else {
        return nil;
    }
}

- (void)collectionView:(UICollectionView *)collectionView moveItemAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
    if([_dataSource respondsToSelector:@selector(moveItemAtIndexPath:toIndexPath:)]) {
        [_dataSource collectionView:collectionView moveItemAtIndexPath:sourceIndexPath toIndexPath:destinationIndexPath];
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    if([_dataSource respondsToSelector:@selector(collectionView:viewForSupplementaryElementOfKind:atIndexPath:)]) {
        return [_dataSource collectionView:collectionView viewForSupplementaryElementOfKind:kind atIndexPath:indexPath];
    } else {
        return nil;
    }

}

- (void)collectionView:(UICollectionView *)collectionView prefetchItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths API_AVAILABLE(ios(10.0)) {
    if([_prefetchingDataSource respondsToSelector:@selector(collectionView:prefetchItemsAtIndexPaths:)]) {
        [_prefetchingDataSource collectionView:collectionView prefetchItemsAtIndexPaths:indexPaths];
    }
}

- (void)collectionView:(UICollectionView *)collectionView cancelPrefetchingForItemsAtIndexPaths:(NSArray<NSIndexPath *> *)indexPaths  API_AVAILABLE(ios(10.0)) {
    if([_prefetchingDataSource respondsToSelector:@selector(collectionView:cancelPrefetchingForItemsAtIndexPaths:)]) {
        [_prefetchingDataSource collectionView:collectionView cancelPrefetchingForItemsAtIndexPaths:indexPaths];
    }
}

@end


