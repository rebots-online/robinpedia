# Neo4j Migration Plan

## Current Configuration
- Host: 192.168.0.157
- Port: 7687
- Username: neo4j
- Authentication: Enabled
- Version: 5.26.1
- OS: Ubuntu 24.04 (Noble Numbat)

## Target Configuration
- Host: 192.168.0.71
- GPU: NVIDIA 3070 Ti (Driver 550)
- Port: 7687 (keeping the same port for consistency)
- OS: Ubuntu 24.04 (Noble Numbat)
- Target Version: 5.26.1 (matching source)

## Installation Steps

1. **Install Neo4j on 192.168.0.71**
```bash
# Install dependencies
sudo apt-get update
sudo apt-get install wget apt-transport-https software-properties-common

# Add Neo4j repository signing key (new method)
curl -fsSL https://debian.neo4j.com/neotechnology.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/neo4j.gpg

# Add Neo4j repository for Ubuntu 24.04 (using exact same config as 192.168.0.157)
echo "deb [signed-by=/usr/share/keyrings/neo4j.gpg] https://debian.neo4j.com stable latest" | sudo tee /etc/apt/sources.list.d/neo4j.list

# Update package list
sudo apt-get update

# Install Neo4j 5.26.1 Community Edition (matching current version)
sudo apt-get install neo4j=5.26.1

# NVIDIA drivers and CUDA are already installed (Driver 550)
# DO NOT modify existing NVIDIA configuration
```

2. **Configure Neo4j for GPU Support**
Edit `/etc/neo4j/neo4j.conf`:
```conf
# Enable GPU acceleration
gds.gpu.enabled=true

# Conservative GPU memory settings to share with other services
gds.gpu.memory.limit=2g  # Reserved GPU memory for Neo4j
# Additional GPU tuning parameters
gds.gpu.allocation.max_size=1600m  # Maximum single allocation size
gds.gpu.similarity.kernel.warpSize=32  # Optimize for Ampere architecture
gds.gpu.overlap.threshold.ratio=0.1  # Lower threshold for GPU usage
gds.gpu.min.memory.usage=0.5  # Minimum memory usage before attempting GPU
gds.gpu.concurrent.copies=2  # Limit concurrent copies

# Configure network binding
dbms.default_listen_address=0.0.0.0
dbms.default_advertised_address=192.168.0.71
dbms.connector.bolt.enabled=true
dbms.connector.bolt.listen_address=:7687

# Memory configuration
dbms.memory.heap.initial_size=4g
dbms.memory.heap.max_size=8g
dbms.memory.pagecache.size=4g
```

3. **Data Migration**

```bash
# On old instance (192.168.0.157)
neo4j-admin dump --database=neo4j --to=/path/to/backup/neo4j-backup.dump

# Transfer file to new instance
scp /path/to/backup/neo4j-backup.dump user@192.168.0.71:/path/to/backup/

# On new instance (192.168.0.71)
neo4j-admin load --from=/path/to/backup/neo4j-backup.dump --database=neo4j --force
```

4. **Update MCP Configuration**
Update the Neo4j connection details in the MCP settings file:
```json
{
  "mcpServers": {
    "neo4j": {
      "command": "node",
      "args": [
        "/home/robin/Documents/Cline/MCP/mcp-neo4j/dist/servers/mcp-neo4j-memory/main.js"
      ],
      "env": {
        "NEO4J_URL": "bolt://192.168.0.71:7687",
        "NEO4J_USER": "neo4j",
        "NEO4J_PASSWORD": "Ch4n3l.C"
      }
    }
  }
}
```

5. **Verification Steps**
- Ensure Neo4j service is running on new instance: `sudo systemctl status neo4j`
- Verify Neo4j version matches: `neo4j --version` should show 5.26.1
- Verify GPU is being utilized: `nvidia-smi` should show Neo4j processes
- Test connection using: `cypher-shell -a bolt://192.168.0.71:7687 -u neo4j -p Ch4n3l.C`
- Run basic queries to verify data integrity
- Check Neo4j browser interface: http://192.168.0.71:7474

## Rollback Plan
If issues occur during migration:
1. Keep old instance running until new instance is verified
2. Document any issues encountered
3. Can revert MCP configuration to old instance if needed

## Post-Migration Tasks
1. Monitor GPU utilization and performance
2. Tune memory settings if needed
3. Consider setting up replication for backup
4. Document new instance details in system architecture

## Performance Monitoring
After migration, monitor GPU memory usage with:
```bash
watch -n 1 nvidia-smi
```

If Neo4j is competing for GPU resources, you can further adjust:
- Decrease `gds.gpu.memory.limit` to 1g if needed
- Increase `gds.gpu.min.memory.usage` to 0.7 to be more selective about GPU usage
- Adjust `gds.gpu.concurrent.copies` based on observed performance

## Notes
- Using exact same Neo4j version (5.26.1) as source system
- Using secure repository configuration with signed-by option
- Repository and package configuration mirrors working setup from 192.168.0.157
- Both source and target running Ubuntu 24.04
