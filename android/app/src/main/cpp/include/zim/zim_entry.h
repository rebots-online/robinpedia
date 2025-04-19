#pragma once

#include <cstdint>
#include <memory>

// ZIM directory entry
class ZimEntry {
public:
    // MIME type index
    uint16_t mimeType;
    
    // Namespace
    uint8_t ns;
    
    // Revision (ZIM format v6+)
    uint32_t revision;
    
    // Cluster number
    uint32_t clusterNumber;
    
    // Blob number
    uint32_t blobNumber;
    
    // URL pointer
    uint64_t urlPtr;
    
    // Title pointer
    uint64_t titlePtr;
    
    // Parameter length
    uint32_t parameterLen;
    
    // Check if this entry is a redirect
    bool isRedirect() const;
    
    // Get the redirect index
    uint32_t getRedirectIndex() const;
};
