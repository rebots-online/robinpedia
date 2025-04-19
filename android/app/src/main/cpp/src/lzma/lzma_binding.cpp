#include <jni.h>
#include <string>
#include <vector>
#include <android/log.h>

#define LOG_TAG "LZMABinding"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// LZMA SDK includes
#include "lzma/LzmaDec.h"
#include "lzma/LzmaEnc.h"

extern "C" {

// LZMA decompression function
JNIEXPORT jbyteArray JNICALL
Java_com_robinsai_ontological_1preamble_LZMABinding_decompress(
        JNIEnv *env,
        jobject /* this */,
        jbyteArray compressedData) {
    
    // Get the compressed data
    jsize compressedSize = env->GetArrayLength(compressedData);
    jbyte *compressedBytes = env->GetByteArrayElements(compressedData, NULL);
    
    // Check if the data is valid LZMA
    if (compressedSize < LZMA_PROPS_SIZE + 8) {
        LOGE("Invalid LZMA data: too small");
        env->ReleaseByteArrayElements(compressedData, compressedBytes, JNI_ABORT);
        return NULL;
    }
    
    // Get the uncompressed size from the header
    UInt64 uncompressedSize = 0;
    for (int i = 0; i < 8; i++) {
        uncompressedSize |= ((UInt64)(Byte)compressedBytes[LZMA_PROPS_SIZE + i]) << (i * 8);
    }
    
    // Allocate memory for the decompressed data
    std::vector<Byte> decompressedData(uncompressedSize);
    
    // Initialize the LZMA decoder
    CLzmaDec state;
    LzmaDec_Construct(&state);
    
    // Set the decoder properties
    SRes res = LzmaDec_Allocate(&state, (Byte*)compressedBytes, LZMA_PROPS_SIZE, &g_Alloc);
    if (res != SZ_OK) {
        LOGE("Failed to allocate LZMA decoder: %d", res);
        env->ReleaseByteArrayElements(compressedData, compressedBytes, JNI_ABORT);
        return NULL;
    }
    
    // Initialize the decoder state
    LzmaDec_Init(&state);
    
    // Decompress the data
    SizeT srcLen = compressedSize - (LZMA_PROPS_SIZE + 8);
    SizeT destLen = uncompressedSize;
    ELzmaStatus status;
    
    res = LzmaDec_DecodeToBuf(&state,
                             decompressedData.data(), &destLen,
                             (Byte*)compressedBytes + LZMA_PROPS_SIZE + 8, &srcLen,
                             LZMA_FINISH_ANY, &status);
    
    // Free the decoder
    LzmaDec_Free(&state, &g_Alloc);
    
    // Release the compressed data
    env->ReleaseByteArrayElements(compressedData, compressedBytes, JNI_ABORT);
    
    // Check if decompression was successful
    if (res != SZ_OK) {
        LOGE("LZMA decompression failed: %d", res);
        return NULL;
    }
    
    // Create a Java byte array for the decompressed data
    jbyteArray result = env->NewByteArray(destLen);
    env->SetByteArrayRegion(result, 0, destLen, (jbyte*)decompressedData.data());
    
    return result;
}

// LZMA compression function
JNIEXPORT jbyteArray JNICALL
Java_com_robinsai_ontological_1preamble_LZMABinding_compress(
        JNIEnv *env,
        jobject /* this */,
        jbyteArray data,
        jint level) {
    
    // Get the data to compress
    jsize dataSize = env->GetArrayLength(data);
    jbyte *dataBytes = env->GetByteArrayElements(data, NULL);
    
    // Allocate memory for the compressed data (worst case: input size + header)
    std::vector<Byte> compressedData(dataSize + LZMA_PROPS_SIZE + 8);
    
    // Initialize the LZMA encoder properties
    CLzmaEncProps props;
    LzmaEncProps_Init(&props);
    props.level = level;
    
    // Compress the data
    SizeT propsSize = LZMA_PROPS_SIZE;
    SizeT destLen = dataSize + LZMA_PROPS_SIZE + 8;
    
    // Write the uncompressed size to the header
    for (int i = 0; i < 8; i++) {
        compressedData[LZMA_PROPS_SIZE + i] = (Byte)(dataSize >> (i * 8));
    }
    
    // Compress the data
    SRes res = LzmaEncode(
        compressedData.data() + LZMA_PROPS_SIZE + 8, &destLen,
        (Byte*)dataBytes, dataSize,
        &props, compressedData.data(), &propsSize,
        0, NULL, &g_Alloc, &g_Alloc);
    
    // Release the input data
    env->ReleaseByteArrayElements(data, dataBytes, JNI_ABORT);
    
    // Check if compression was successful
    if (res != SZ_OK) {
        LOGE("LZMA compression failed: %d", res);
        return NULL;
    }
    
    // Create a Java byte array for the compressed data
    jbyteArray result = env->NewByteArray(propsSize + 8 + destLen);
    env->SetByteArrayRegion(result, 0, propsSize + 8 + destLen, (jbyte*)compressedData.data());
    
    return result;
}

} // extern "C"
