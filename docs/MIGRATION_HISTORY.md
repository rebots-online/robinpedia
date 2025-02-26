# Infrastructure Migration History

## February 2025 Infrastructure Upgrades

### Qdrant Migration (Completed)
- **Date**: February 23, 2025
- **Status**: ✅ Completed
- **From**: 192.168.0.157
- **To**: 192.168.0.71
- **Details**:
  - Successfully migrated Qdrant to new machine with 3070 Ti GPU
  - Updated MCP configuration to use new endpoint (http://192.168.0.71:6333)
  - Collection name maintained as "RobinSST23feb2025"
  - Using fastembed-model-name: "sentence-transformers/all-MiniLM-L6-v2"
  - Verified functionality through test queries
  - Original configuration preserved for reference

### Neo4j Migration (In Progress)
- **Date**: February 23, 2025
- **Status**: 🔄 In Progress
- **From**: 192.168.0.157 (Ubuntu 24.04)
- **To**: 192.168.0.71 (Ubuntu 24.04)
- **Motivation**: 
  - Leverage 3070 Ti GPU capabilities
  - Consolidate graph database on more powerful hardware
  - Optimize for shared GPU usage with other services (like Ollama)
- **Key Considerations**:
  - Conservative GPU memory allocation (2GB, adjustable down to 1GB)
  - Maintaining compatibility with Ubuntu 24.04 on both machines
  - Preserving existing data and relationships
  - Zero-downtime migration strategy
- **Documentation**:
  - Detailed migration plan: [NEO4J_MIGRATION_PLAN.md](NEO4J_MIGRATION_PLAN.md)
  - Hardware specifications documented
  - GPU sharing configuration outlined
  - Rollback procedures established

## System Context
Both migrations are part of a larger infrastructure optimization initiative, moving key services to better-equipped hardware while ensuring efficient resource sharing.