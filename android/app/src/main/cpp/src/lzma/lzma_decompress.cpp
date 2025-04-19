#include <cstdlib>
#include <cstdint>
#include <android/log.h>

#define LOG_TAG "LZMADecompress"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// LZMA SDK includes
#include "lzma/LzmaDec.h"

extern "C" {

// LZMA decompression function for use by other components
uint8_t* lzma_decompress(const uint8_t* data, size_t dataSize, size_t* outSize) {
    // Check if the data is valid LZMA
    if (dataSize < LZMA_PROPS_SIZE + 8) {
        LOGE("Invalid LZMA data: too small");
        return NULL;
    }
    
    // Get the uncompressed size from the header
    UInt64 uncompressedSize = 0;
    for (int i = 0; i < 8; i++) {
        uncompressedSize |= ((UInt64)(Byte)data[LZMA_PROPS_SIZE + i]) << (i * 8);
    }
    
    // Allocate memory for the decompressed data
    uint8_t* decompressedData = (uint8_t*)malloc(uncompressedSize);
    if (!decompressedData) {
        LOGE("Failed to allocate memory for decompressed data");
        return NULL;
    }
    
    // Initialize the LZMA decoder
    CLzmaDec state;
    LzmaDec_Construct(&state);
    
    // Set the decoder properties
    SRes res = LzmaDec_Allocate(&state, (Byte*)data, LZMA_PROPS_SIZE, &g_Alloc);
    if (res != SZ_OK) {
        LOGE("Failed to allocate LZMA decoder: %d", res);
        free(decompressedData);
        return NULL;
    }
    
    // Initialize the decoder state
    LzmaDec_Init(&state);
    
    // Decompress the data
    SizeT srcLen = dataSize - (LZMA_PROPS_SIZE + 8);
    SizeT destLen = uncompressedSize;
    ELzmaStatus status;
    
    res = LzmaDec_DecodeToBuf(&state,
                             decompressedData, &destLen,
                             (Byte*)data + LZMA_PROPS_SIZE + 8, &srcLen,
                             LZMA_FINISH_ANY, &status);
    
    // Free the decoder
    LzmaDec_Free(&state, &g_Alloc);
    
    // Check if decompression was successful
    if (res != SZ_OK) {
        LOGE("LZMA decompression failed: %d", res);
        free(decompressedData);
        return NULL;
    }
    
    // Set the output size
    *outSize = destLen;
    
    return decompressedData;
}

} // extern "C"
