#include "zim_cluster.h"
#include <cstring>
#include <android/log.h>

#define LOG_TAG "ZimCluster"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// External LZMA decompression function
extern "C" {
    extern uint8_t* lzma_decompress(const uint8_t* data, size_t dataSize, size_t* outSize);
}

ZimCluster::ZimCluster(FILE *file) : m_file(file), m_position(0), m_compressionType(0),
                                    m_extendedType(0), m_blobCount(0), m_initialized(false) {
}

bool ZimCluster::read() {
    if (!m_file) {
        LOGE("ZIM file not open");
        return false;
    }
    
    // Save the current position
    m_position = ftell(m_file);
    
    // Read the compression type
    if (fread(&m_compressionType, sizeof(uint8_t), 1, m_file) != 1) {
        LOGE("Failed to read compression type");
        return false;
    }
    
    // Read the extended compression type (ZIM format v6+)
    if (m_compressionType == 4) {
        if (fread(&m_extendedType, sizeof(uint8_t), 1, m_file) != 1) {
            LOGE("Failed to read extended compression type");
            return false;
        }
    }
    
    // Read the blob count
    uint8_t firstByte;
    if (fread(&firstByte, sizeof(uint8_t), 1, m_file) != 1) {
        LOGE("Failed to read first byte of blob count");
        return false;
    }
    
    if (firstByte == 0xFF) {
        // 4-byte blob count
        uint32_t blobCount;
        if (fread(&blobCount, sizeof(uint32_t), 1, m_file) != 1) {
            LOGE("Failed to read 4-byte blob count");
            return false;
        }
        m_blobCount = blobCount;
    } else {
        // 1-byte blob count
        m_blobCount = firstByte;
    }
    
    // Read the blob offset list
    m_blobOffsets.resize(m_blobCount + 1);
    for (uint32_t i = 0; i <= m_blobCount; i++) {
        if (fread(&m_blobOffsets[i], sizeof(uint32_t), 1, m_file) != 1) {
            LOGE("Failed to read blob offset %u", i);
            return false;
        }
    }
    
    // Read the compressed data
    uint32_t dataSize = m_blobOffsets[m_blobCount];
    std::vector<uint8_t> compressedData(dataSize);
    if (fread(compressedData.data(), 1, dataSize, m_file) != dataSize) {
        LOGE("Failed to read compressed data");
        return false;
    }
    
    // Decompress the data if necessary
    if (m_compressionType == 0) {
        // Uncompressed
        m_data = compressedData;
    } else if (m_compressionType == 4) {
        // LZMA
        size_t decompressedSize = 0;
        uint8_t* decompressedData = lzma_decompress(compressedData.data(), compressedData.size(), &decompressedSize);
        if (!decompressedData) {
            LOGE("Failed to decompress LZMA data");
            return false;
        }
        
        m_data.resize(decompressedSize);
        memcpy(m_data.data(), decompressedData, decompressedSize);
        
        // Free the decompressed data
        free(decompressedData);
    } else {
        LOGE("Unsupported compression type: %u", m_compressionType);
        return false;
    }
    
    m_initialized = true;
    return true;
}

bool ZimCluster::getBlob(uint32_t index, std::vector<uint8_t> &blob) {
    if (!m_initialized) {
        LOGE("ZIM cluster not initialized");
        return false;
    }
    
    if (index >= m_blobCount) {
        LOGE("Invalid blob index: %u", index);
        return false;
    }
    
    // Get the blob offset and size
    uint32_t offset = m_blobOffsets[index];
    uint32_t size = m_blobOffsets[index + 1] - offset;
    
    // Copy the blob data
    blob.resize(size);
    memcpy(blob.data(), m_data.data() + offset, size);
    
    return true;
}

uint8_t ZimCluster::getCompressionType() const {
    return m_compressionType;
}

uint8_t ZimCluster::getExtendedType() const {
    return m_extendedType;
}

uint32_t ZimCluster::getBlobCount() const {
    return m_blobCount;
}
