#pragma once

#include <string>
#include <vector>
#include <map>
#include <memory>
#include <cstdio>

// Forward declarations
class ZimEntry;
class ZimCluster;

// ZIM file header
struct ZimHeader {
    char magicNumber[4];
    uint16_t majorVersion;
    uint16_t minorVersion;
    uint8_t uuid[16];
    uint32_t articleCount;
    uint32_t clusterCount;
    uint64_t urlPtrPos;
    uint64_t titlePtrPos;
    uint64_t clusterPtrPos;
    uint64_t mimeListPos;
    uint32_t mainPage;
    uint32_t layoutPage;
    uint64_t checksumPos;
};

// ZIM reader class
class ZimReader {
public:
    ZimReader();
    ~ZimReader();
    
    // Open a ZIM file
    bool open(const std::string &path);
    
    // Close the ZIM file
    void close();
    
    // Get the ZIM header
    const ZimHeader &getHeader() const;
    
    // Get an entry by URL
    std::shared_ptr<ZimEntry> getEntryByUrl(const std::string &url);
    
    // Get an entry by index
    std::shared_ptr<ZimEntry> getEntryByIndex(uint32_t index);
    
    // Get content for an entry
    bool getContent(std::shared_ptr<ZimEntry> entry, std::vector<uint8_t> &content);
    
    // Get a cluster
    std::shared_ptr<ZimCluster> getCluster(uint32_t index);
    
    // Search for entries
    bool search(const std::string &query, std::vector<std::shared_ptr<ZimEntry>> &results, uint32_t limit);
    
    // Get the title for an entry
    std::string getTitle(std::shared_ptr<ZimEntry> entry);
    
private:
    // Initialize the URL index
    bool initializeUrlIndex();
    
    // The ZIM file
    FILE *m_file;
    
    // The ZIM header
    ZimHeader m_header;
    
    // URL index (URL -> entry index)
    std::map<std::string, uint32_t> m_urlIndex;
    
    // Initialization flag
    bool m_initialized;
};
