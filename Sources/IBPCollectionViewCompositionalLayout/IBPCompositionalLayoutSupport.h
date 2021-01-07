//
//  IBPCompositionalLayoutSupport.h
//  IBPCollectionViewCompositionalLayout
//
//  Created by s-huang on 2021/01/06.
//  Copyright © 2021 Kishikawa Katsumi. All rights reserved.
//

#ifndef IBPCompositionalLayoutSupport_h
#define IBPCompositionalLayoutSupport_h
@protocol IBPUICollectionViewCompositionalLayoutProvider;

@interface IBPCompositionLayoutableCollectionViewDataSource : NSObject<UICollectionViewDataSource, UICollectionViewDataSourcePrefetching>

@property (nonatomic, readonly) id<UICollectionViewDataSource> dataSource;

- (instancetype)initWithDataSource:(id<UICollectionViewDataSource>)dataSource prefetchDataSource:(id<UICollectionViewDataSourcePrefetching>)prefetchingDataSource layout:(id<IBPUICollectionViewCompositionalLayoutProvider>)layout;

@end

#endif /* IBPCompositionalLayoutSupport_h */
