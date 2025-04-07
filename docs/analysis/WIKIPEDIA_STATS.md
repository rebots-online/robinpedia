# Wikipedia & ZIM Statistics Analysis

*Copyright (C) 2025 Robin L. M. Cheung, MBA. All rights reserved.*

## Wikipedia Size Statistics

### English Wikipedia (As of April 2025)

- **Articles**: ~6.8 million
- **Total Pages**: ~56.5 million (including talk pages, user pages, etc.)
- **Database Size**: ~190 GB (text only, uncompressed)
- **Media Size**: ~7.5 TB (images, audio, video)
- **ZIM File Size**:  
  - Text-only: ~93 GB compressed
  - With images (selection): ~120-160 GB
  - Full media: Not typically distributed as single ZIM due to size

### Interlinking Statistics

- **Average Links per Article**: ~92 internal links
- **Total Internal Links**: ~625 million
- **Category Relationships**: ~1.8 million categories with hierarchical structure
- **Template Usage**: ~45,000 templates used across articles

## Knowledge Graph Considerations

### Neo4j Scaling Limitations

- Single-instance Neo4j practically limited to ~100 billion relationships
- Full Wikipedia graph would contain:
  - ~6.8 million nodes (articles)
  - ~625 million relationships (just from direct links)
  - Additional relationships from categories, templates, infoboxes, etc.

### Distributed Knowledge Graph Approaches

#### Sharding Options

1. **Topic-based Sharding**: Partition by major categories
   - Pro: Natural content boundaries
   - Con: Uneven shard sizes, cross-domain topics problematic

2. **Alphabetical/Hash-based Sharding**: Distribute evenly by article title or ID
   - Pro: Even distribution 
   - Con: Related content often separated across shards

3. **Graph Partitioning Algorithms**: Use community detection to minimize cross-shard links
   - Pro: Preserves semantic relationships
   - Con: Computationally expensive to create and maintain

#### Practical Implementation Challenges

- Cross-shard query performance
- Consistency across distributed instances
- Synchronization of updates
- Resource requirements (memory-intensive)

## User Browsing Patterns

- **Average Session Length**: 3-4 articles per session
- **Navigation Depth**: 75% of users go no deeper than 3 links from entry
- **Topic Clustering**: Users typically stay within related topic clusters
- **Popular Entry Points**: ~5% of articles account for ~40% of all entry points

## Recommendations for Distributed Approach

Based on browsing patterns, consider:

1. **Localized Graph Segments**: Create subgraphs around popular entry points
2. **Dynamic Loading**: Load subgraphs based on user navigation paths
3. **Pre-computed Relationships**: Store high-value relationships (similarity, conceptual links)
4. **Hybrid Storage**: Use graph DB for current session context, traditional DB for broader content
5. **Edge Computing**: Consider partial graph processing on client devices

This approach would preserve the benefit of knowledge graph relationships while being practically implementable with current technology constraints.

## ZIM Reader Statistics

### Performance Benchmarks

- **Startup Time**: ~0.8-2.5 seconds
- **Article Load Time**: ~0.2-0.4 seconds
- **Search Index Generation**: ~3-8 hours for full English Wikipedia
- **Memory Usage**: ~120-250 MB baseline, ~350-500 MB during active browsing

### User Experience Metrics

- **Responsiveness Threshold**: >1 second article load perceived as slow
- **Search Response Expectation**: <0.5 seconds for suggestions, <2 seconds for results
