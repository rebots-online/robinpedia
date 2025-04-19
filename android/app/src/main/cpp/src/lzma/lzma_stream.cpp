#include <jni.h>
#include <string>
#include <vector>
#include <android/log.h>

#define LOG_TAG "LZMAStream"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

// LZMA SDK includes
#include "lzma/LzmaDec.h"
#include "lzma/LzmaEnc.h"

extern "C" {

// Initialize LZMA stream
JNIEXPORT jlong JNICALL
Java_com_robinsai_ontological_1preamble_LZMAStream_initialize(
        JNIEnv *env,
        jobject /* this */) {
    
    // Create a new LZMA decoder
    CLzmaDec *state = new CLzmaDec();
    LzmaDec_Construct(state);
    
    return (jlong)state;
}

// Set LZMA properties
JNIEXPORT jboolean JNICALL
Java_com_robinsai_ontological_1preamble_LZMAStream_setProperties(
        JNIEnv *env,
        jobject /* this */,
        jlong handle,
        jbyteArray props) {
    
    // Get the LZMA decoder
    CLzmaDec *state = (CLzmaDec*)handle;
    
    // Get the properties
    jsize propsSize = env->GetArrayLength(props);
    jbyte *propsBytes = env->GetByteArrayElements(props, NULL);
    
    // Set the decoder properties
    SRes res = LzmaDec_Allocate(state, (Byte*)propsBytes, propsSize, &g_Alloc);
    
    // Release the properties
    env->ReleaseByteArrayElements(props, propsBytes, JNI_ABORT);
    
    // Check if the properties were set successfully
    if (res != SZ_OK) {
        LOGE("Failed to set LZMA properties: %d", res);
        return JNI_FALSE;
    }
    
    // Initialize the decoder state
    LzmaDec_Init(state);
    
    return JNI_TRUE;
}

// Decode LZMA data
JNIEXPORT jbyteArray JNICALL
Java_com_robinsai_ontological_1preamble_LZMAStream_decode(
        JNIEnv *env,
        jobject /* this */,
        jlong handle,
        jbyteArray data,
        jboolean finish) {
    
    // Get the LZMA decoder
    CLzmaDec *state = (CLzmaDec*)handle;
    
    // Get the data to decode
    jsize dataSize = env->GetArrayLength(data);
    jbyte *dataBytes = env->GetByteArrayElements(data, NULL);
    
    // Allocate memory for the decoded data (worst case: 4x input size)
    std::vector<Byte> decodedData(dataSize * 4);
    
    // Decode the data
    SizeT srcLen = dataSize;
    SizeT destLen = decodedData.size();
    ELzmaStatus status;
    ELzmaFinishMode finishMode = finish ? LZMA_FINISH_END : LZMA_FINISH_ANY;
    
    SRes res = LzmaDec_DecodeToBuf(state,
                                 decodedData.data(), &destLen,
                                 (Byte*)dataBytes, &srcLen,
                                 finishMode, &status);
    
    // Release the input data
    env->ReleaseByteArrayElements(data, dataBytes, JNI_ABORT);
    
    // Check if decoding was successful
    if (res != SZ_OK) {
        LOGE("LZMA decoding failed: %d", res);
        return NULL;
    }
    
    // Create a Java byte array for the decoded data
    jbyteArray result = env->NewByteArray(destLen);
    env->SetByteArrayRegion(result, 0, destLen, (jbyte*)decodedData.data());
    
    return result;
}

// Dispose LZMA stream
JNIEXPORT void JNICALL
Java_com_robinsai_ontological_1preamble_LZMAStream_dispose(
        JNIEnv *env,
        jobject /* this */,
        jlong handle) {
    
    // Get the LZMA decoder
    CLzmaDec *state = (CLzmaDec*)handle;
    
    // Free the decoder
    LzmaDec_Free(state, &g_Alloc);
    
    // Delete the decoder
    delete state;
}

} // extern "C"
