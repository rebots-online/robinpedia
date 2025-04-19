#pragma once

#include <cstdint>
#include <vector>
#include <memory>
#include <cstdio>

// ZIM cluster class
class ZimCluster {
public:
    // Constructor
    ZimCluster(FILE *file);
    
    // Read the cluster
    bool read();
    
    // Get a blob from the cluster
    bool getBlob(uint32_t index, std::vector<uint8_t> &blob);
    
    // Get the compression type
    uint8_t getCompressionType() const;
    
    // Get the extended compression type
    uint8_t getExtendedType() const;
    
    // Get the blob count
    uint32_t getBlobCount() const;
    
private:
    // The ZIM file
    FILE *m_file;
    
    // The cluster position
    uint64_t m_position;
    
    // Compression type
    uint8_t m_compressionType;
    
    // Extended compression type
    uint8_t m_extendedType;
    
    // Blob count
    uint32_t m_blobCount;
    
    // Blob offset list
    std::vector<uint32_t> m_blobOffsets;
    
    // Decompressed data
    std::vector<uint8_t> m_data;
    
    // Initialization flag
    bool m_initialized;
};
