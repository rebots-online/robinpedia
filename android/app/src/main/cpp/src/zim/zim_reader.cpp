#include "zim_reader.h"
#include "zim_entry.h"
#include "zim_cluster.h"

#include <fstream>
#include <algorithm>
#include <android/log.h>

#define LOG_TAG "ZimReader"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

ZimReader::ZimReader() : m_file(nullptr), m_initialized(false) {
}

ZimReader::~ZimReader() {
    close();
}

bool ZimReader::open(const std::string &path) {
    // Close any open file
    close();
    
    // Open the file
    m_file = fopen(path.c_str(), "rb");
    if (!m_file) {
        LOGE("Failed to open ZIM file: %s", path.c_str());
        return false;
    }
    
    // Read the header
    if (fread(&m_header, sizeof(ZimHeader), 1, m_file) != 1) {
        LOGE("Failed to read ZIM header");
        close();
        return false;
    }
    
    // Check the magic number
    if (m_header.magicNumber[0] != 'Z' || m_header.magicNumber[1] != 'I' ||
        m_header.magicNumber[2] != 'M' || m_header.magicNumber[3] != '\0') {
        LOGE("Invalid ZIM file: wrong magic number");
        close();
        return false;
    }
    
    // Initialize the URL index
    if (!initializeUrlIndex()) {
        LOGE("Failed to initialize URL index");
        close();
        return false;
    }
    
    m_initialized = true;
    return true;
}

void ZimReader::close() {
    if (m_file) {
        fclose(m_file);
        m_file = nullptr;
    }
    
    m_urlIndex.clear();
    m_initialized = false;
}

const ZimHeader &ZimReader::getHeader() const {
    return m_header;
}

std::shared_ptr<ZimEntry> ZimReader::getEntryByUrl(const std::string &url) {
    if (!m_initialized) {
        LOGE("ZIM reader not initialized");
        return nullptr;
    }
    
    // Find the URL in the index
    auto it = m_urlIndex.find(url);
    if (it == m_urlIndex.end()) {
        return nullptr;
    }
    
    // Get the entry
    return getEntryByIndex(it->second);
}

std::shared_ptr<ZimEntry> ZimReader::getEntryByIndex(uint32_t index) {
    if (!m_initialized) {
        LOGE("ZIM reader not initialized");
        return nullptr;
    }
    
    if (index >= m_header.articleCount) {
        LOGE("Invalid entry index: %u", index);
        return nullptr;
    }
    
    // Seek to the URL pointer
    if (fseek(m_file, m_header.urlPtrPos + index * sizeof(uint64_t), SEEK_SET) != 0) {
        LOGE("Failed to seek to URL pointer");
        return nullptr;
    }
    
    // Read the URL pointer
    uint64_t urlPtr;
    if (fread(&urlPtr, sizeof(uint64_t), 1, m_file) != 1) {
        LOGE("Failed to read URL pointer");
        return nullptr;
    }
    
    // Seek to the entry
    if (fseek(m_file, urlPtr, SEEK_SET) != 0) {
        LOGE("Failed to seek to entry");
        return nullptr;
    }
    
    // Read the entry
    std::shared_ptr<ZimEntry> entry = std::make_shared<ZimEntry>();
    if (fread(entry.get(), sizeof(ZimEntry), 1, m_file) != 1) {
        LOGE("Failed to read entry");
        return nullptr;
    }
    
    return entry;
}

bool ZimReader::getContent(std::shared_ptr<ZimEntry> entry, std::vector<uint8_t> &content) {
    if (!m_initialized) {
        LOGE("ZIM reader not initialized");
        return false;
    }
    
    if (!entry) {
        LOGE("Invalid entry");
        return false;
    }
    
    // Check if this is a redirect
    if (entry->isRedirect()) {
        // Get the target entry
        std::shared_ptr<ZimEntry> targetEntry = getEntryByIndex(entry->getRedirectIndex());
        if (!targetEntry) {
            LOGE("Failed to get redirect target");
            return false;
        }
        
        // Get the content of the target entry
        return getContent(targetEntry, content);
    }
    
    // Get the cluster
    std::shared_ptr<ZimCluster> cluster = getCluster(entry->clusterNumber);
    if (!cluster) {
        LOGE("Failed to get cluster");
        return false;
    }
    
    // Get the blob
    return cluster->getBlob(entry->blobNumber, content);
}

std::shared_ptr<ZimCluster> ZimReader::getCluster(uint32_t index) {
    if (!m_initialized) {
        LOGE("ZIM reader not initialized");
        return nullptr;
    }
    
    if (index >= m_header.clusterCount) {
        LOGE("Invalid cluster index: %u", index);
        return nullptr;
    }
    
    // Seek to the cluster pointer
    if (fseek(m_file, m_header.clusterPtrPos + index * sizeof(uint64_t), SEEK_SET) != 0) {
        LOGE("Failed to seek to cluster pointer");
        return nullptr;
    }
    
    // Read the cluster pointer
    uint64_t clusterPtr;
    if (fread(&clusterPtr, sizeof(uint64_t), 1, m_file) != 1) {
        LOGE("Failed to read cluster pointer");
        return nullptr;
    }
    
    // Seek to the cluster
    if (fseek(m_file, clusterPtr, SEEK_SET) != 0) {
        LOGE("Failed to seek to cluster");
        return nullptr;
    }
    
    // Read the cluster
    std::shared_ptr<ZimCluster> cluster = std::make_shared<ZimCluster>(m_file);
    if (!cluster->read()) {
        LOGE("Failed to read cluster");
        return nullptr;
    }
    
    return cluster;
}

bool ZimReader::search(const std::string &query, std::vector<std::shared_ptr<ZimEntry>> &results, uint32_t limit) {
    if (!m_initialized) {
        LOGE("ZIM reader not initialized");
        return false;
    }
    
    // Clear the results
    results.clear();
    
    // Convert the query to lowercase
    std::string lowerQuery = query;
    std::transform(lowerQuery.begin(), lowerQuery.end(), lowerQuery.begin(), ::tolower);
    
    // Search through the URL index
    for (const auto &pair : m_urlIndex) {
        // Get the entry
        std::shared_ptr<ZimEntry> entry = getEntryByIndex(pair.second);
        if (!entry) {
            continue;
        }
        
        // Get the URL and title
        std::string url = pair.first;
        std::string title = getTitle(entry);
        
        // Convert to lowercase
        std::transform(url.begin(), url.end(), url.begin(), ::tolower);
        std::transform(title.begin(), title.end(), title.begin(), ::tolower);
        
        // Check if the URL or title contains the query
        if (url.find(lowerQuery) != std::string::npos || title.find(lowerQuery) != std::string::npos) {
            results.push_back(entry);
            
            // Check if we've reached the limit
            if (results.size() >= limit) {
                break;
            }
        }
    }
    
    return true;
}

std::string ZimReader::getTitle(std::shared_ptr<ZimEntry> entry) {
    if (!m_initialized) {
        LOGE("ZIM reader not initialized");
        return "";
    }
    
    if (!entry) {
        LOGE("Invalid entry");
        return "";
    }
    
    // Seek to the title pointer
    if (fseek(m_file, m_header.titlePtrPos + entry->titlePtr * sizeof(uint64_t), SEEK_SET) != 0) {
        LOGE("Failed to seek to title pointer");
        return "";
    }
    
    // Read the title pointer
    uint64_t titlePtr;
    if (fread(&titlePtr, sizeof(uint64_t), 1, m_file) != 1) {
        LOGE("Failed to read title pointer");
        return "";
    }
    
    // Seek to the title
    if (fseek(m_file, titlePtr, SEEK_SET) != 0) {
        LOGE("Failed to seek to title");
        return "";
    }
    
    // Read the title
    std::string title;
    char c;
    while (fread(&c, 1, 1, m_file) == 1 && c != '\0') {
        title += c;
    }
    
    return title;
}

bool ZimReader::initializeUrlIndex() {
    if (!m_file) {
        LOGE("ZIM file not open");
        return false;
    }
    
    // Clear the URL index
    m_urlIndex.clear();
    
    // Iterate through all entries
    for (uint32_t i = 0; i < m_header.articleCount; i++) {
        // Seek to the URL pointer
        if (fseek(m_file, m_header.urlPtrPos + i * sizeof(uint64_t), SEEK_SET) != 0) {
            LOGE("Failed to seek to URL pointer");
            return false;
        }
        
        // Read the URL pointer
        uint64_t urlPtr;
        if (fread(&urlPtr, sizeof(uint64_t), 1, m_file) != 1) {
            LOGE("Failed to read URL pointer");
            return false;
        }
        
        // Seek to the entry
        if (fseek(m_file, urlPtr, SEEK_SET) != 0) {
            LOGE("Failed to seek to entry");
            return false;
        }
        
        // Read the entry
        ZimEntry entry;
        if (fread(&entry, sizeof(ZimEntry), 1, m_file) != 1) {
            LOGE("Failed to read entry");
            return false;
        }
        
        // Read the URL
        std::string url;
        char c;
        while (fread(&c, 1, 1, m_file) == 1 && c != '\0') {
            url += c;
        }
        
        // Add to the URL index
        m_urlIndex[url] = i;
    }
    
    return true;
}
