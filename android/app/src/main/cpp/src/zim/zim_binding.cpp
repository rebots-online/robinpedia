#include <jni.h>
#include <string>
#include <vector>
#include <map>
#include <memory>
#include <android/log.h>

#define LOG_TAG "ZIMBinding"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

#include "zim_reader.h"
#include "zim_entry.h"
#include "zim_cluster.h"

// Map of open ZIM readers
static std::map<jlong, std::shared_ptr<ZimReader>> g_readers;
static jlong g_nextHandle = 1;

extern "C" {

// Open a ZIM file
JNIEXPORT jlong JNICALL
Java_com_robinsai_ontological_1preamble_ZIMBinding_open(
        JNIEnv *env,
        jobject /* this */,
        jstring path) {
    
    // Get the path
    const char *pathChars = env->GetStringUTFChars(path, NULL);
    std::string pathStr(pathChars);
    env->ReleaseStringUTFChars(path, pathChars);
    
    // Create a new ZIM reader
    std::shared_ptr<ZimReader> reader = std::make_shared<ZimReader>();
    
    // Open the ZIM file
    if (!reader->open(pathStr)) {
        LOGE("Failed to open ZIM file: %s", pathStr.c_str());
        return 0;
    }
    
    // Add the reader to the map
    jlong handle = g_nextHandle++;
    g_readers[handle] = reader;
    
    return handle;
}

// Close a ZIM file
JNIEXPORT void JNICALL
Java_com_robinsai_ontological_1preamble_ZIMBinding_close(
        JNIEnv *env,
        jobject /* this */,
        jlong handle) {
    
    // Find the reader
    auto it = g_readers.find(handle);
    if (it == g_readers.end()) {
        LOGE("Invalid ZIM handle: %lld", handle);
        return;
    }
    
    // Close the reader
    it->second->close();
    
    // Remove the reader from the map
    g_readers.erase(it);
}

// Get the ZIM header
JNIEXPORT void JNICALL
Java_com_robinsai_ontological_1preamble_ZIMBinding_getHeader(
        JNIEnv *env,
        jobject /* this */,
        jlong handle,
        jobject header) {
    
    // Find the reader
    auto it = g_readers.find(handle);
    if (it == g_readers.end()) {
        LOGE("Invalid ZIM handle: %lld", handle);
        return;
    }
    
    // Get the header
    const ZimHeader &zimHeader = it->second->getHeader();
    
    // Set the header fields
    jclass headerClass = env->GetObjectClass(header);
    
    jfieldID majorVersionField = env->GetFieldID(headerClass, "majorVersion", "I");
    jfieldID minorVersionField = env->GetFieldID(headerClass, "minorVersion", "I");
    jfieldID articleCountField = env->GetFieldID(headerClass, "articleCount", "I");
    jfieldID clusterCountField = env->GetFieldID(headerClass, "clusterCount", "I");
    jfieldID urlPtrPosField = env->GetFieldID(headerClass, "urlPtrPos", "J");
    jfieldID titlePtrPosField = env->GetFieldID(headerClass, "titlePtrPos", "J");
    jfieldID clusterPtrPosField = env->GetFieldID(headerClass, "clusterPtrPos", "J");
    jfieldID mimeListPosField = env->GetFieldID(headerClass, "mimeListPos", "J");
    jfieldID mainPageField = env->GetFieldID(headerClass, "mainPage", "I");
    jfieldID layoutPageField = env->GetFieldID(headerClass, "layoutPage", "I");
    
    env->SetIntField(header, majorVersionField, zimHeader.majorVersion);
    env->SetIntField(header, minorVersionField, zimHeader.minorVersion);
    env->SetIntField(header, articleCountField, zimHeader.articleCount);
    env->SetIntField(header, clusterCountField, zimHeader.clusterCount);
    env->SetLongField(header, urlPtrPosField, zimHeader.urlPtrPos);
    env->SetLongField(header, titlePtrPosField, zimHeader.titlePtrPos);
    env->SetLongField(header, clusterPtrPosField, zimHeader.clusterPtrPos);
    env->SetLongField(header, mimeListPosField, zimHeader.mimeListPos);
    env->SetIntField(header, mainPageField, zimHeader.mainPage);
    env->SetIntField(header, layoutPageField, zimHeader.layoutPage);
}

// Get an entry by URL
JNIEXPORT jobject JNICALL
Java_com_robinsai_ontological_1preamble_ZIMBinding_getEntryByUrl(
        JNIEnv *env,
        jobject /* this */,
        jlong handle,
        jstring url) {
    
    // Find the reader
    auto it = g_readers.find(handle);
    if (it == g_readers.end()) {
        LOGE("Invalid ZIM handle: %lld", handle);
        return NULL;
    }
    
    // Get the URL
    const char *urlChars = env->GetStringUTFChars(url, NULL);
    std::string urlStr(urlChars);
    env->ReleaseStringUTFChars(url, urlChars);
    
    // Get the entry
    std::shared_ptr<ZimEntry> entry = it->second->getEntryByUrl(urlStr);
    if (!entry) {
        return NULL;
    }
    
    // Create a Java entry object
    jclass entryClass = env->FindClass("com/robinsai/ontological_preamble/ZimDirectoryEntry");
    jmethodID constructor = env->GetMethodID(entryClass, "<init>", "()V");
    jobject entryObj = env->NewObject(entryClass, constructor);
    
    // Set the entry fields
    jfieldID mimeTypeField = env->GetFieldID(entryClass, "mimeType", "I");
    jfieldID namespaceField = env->GetFieldID(entryClass, "namespace", "B");
    jfieldID revisionField = env->GetFieldID(entryClass, "revision", "I");
    jfieldID clusterNumberField = env->GetFieldID(entryClass, "clusterNumber", "I");
    jfieldID blobNumberField = env->GetFieldID(entryClass, "blobNumber", "I");
    jfieldID urlPtrField = env->GetFieldID(entryClass, "urlPtr", "J");
    jfieldID titlePtrField = env->GetFieldID(entryClass, "titlePtr", "J");
    
    env->SetIntField(entryObj, mimeTypeField, entry->mimeType);
    env->SetByteField(entryObj, namespaceField, entry->ns);
    env->SetIntField(entryObj, revisionField, entry->revision);
    env->SetIntField(entryObj, clusterNumberField, entry->clusterNumber);
    env->SetIntField(entryObj, blobNumberField, entry->blobNumber);
    env->SetLongField(entryObj, urlPtrField, entry->urlPtr);
    env->SetLongField(entryObj, titlePtrField, entry->titlePtr);
    
    return entryObj;
}

// Get content for an entry
JNIEXPORT jbyteArray JNICALL
Java_com_robinsai_ontological_1preamble_ZIMBinding_getContent(
        JNIEnv *env,
        jobject /* this */,
        jlong handle,
        jobject entry,
        jobject sizeObj) {
    
    // Find the reader
    auto it = g_readers.find(handle);
    if (it == g_readers.end()) {
        LOGE("Invalid ZIM handle: %lld", handle);
        return NULL;
    }
    
    // Get the entry fields
    jclass entryClass = env->GetObjectClass(entry);
    
    jfieldID mimeTypeField = env->GetFieldID(entryClass, "mimeType", "I");
    jfieldID namespaceField = env->GetFieldID(entryClass, "namespace", "B");
    jfieldID revisionField = env->GetFieldID(entryClass, "revision", "I");
    jfieldID clusterNumberField = env->GetFieldID(entryClass, "clusterNumber", "I");
    jfieldID blobNumberField = env->GetFieldID(entryClass, "blobNumber", "I");
    jfieldID urlPtrField = env->GetFieldID(entryClass, "urlPtr", "J");
    jfieldID titlePtrField = env->GetFieldID(entryClass, "titlePtr", "J");
    
    // Create a ZimEntry
    std::shared_ptr<ZimEntry> zimEntry = std::make_shared<ZimEntry>();
    zimEntry->mimeType = env->GetIntField(entry, mimeTypeField);
    zimEntry->ns = env->GetByteField(entry, namespaceField);
    zimEntry->revision = env->GetIntField(entry, revisionField);
    zimEntry->clusterNumber = env->GetIntField(entry, clusterNumberField);
    zimEntry->blobNumber = env->GetIntField(entry, blobNumberField);
    zimEntry->urlPtr = env->GetLongField(entry, urlPtrField);
    zimEntry->titlePtr = env->GetLongField(entry, titlePtrField);
    
    // Get the content
    std::vector<uint8_t> content;
    if (!it->second->getContent(zimEntry, content)) {
        LOGE("Failed to get content for entry");
        return NULL;
    }
    
    // Set the size
    jclass sizeClass = env->GetObjectClass(sizeObj);
    jfieldID valueField = env->GetFieldID(sizeClass, "value", "J");
    env->SetLongField(sizeObj, valueField, content.size());
    
    // Create a Java byte array for the content
    jbyteArray result = env->NewByteArray(content.size());
    env->SetByteArrayRegion(result, 0, content.size(), (jbyte*)content.data());
    
    return result;
}

// Search for entries
JNIEXPORT jobjectArray JNICALL
Java_com_robinsai_ontological_1preamble_ZIMBinding_search(
        JNIEnv *env,
        jobject /* this */,
        jlong handle,
        jstring query,
        jint limit,
        jobject countObj) {
    
    // Find the reader
    auto it = g_readers.find(handle);
    if (it == g_readers.end()) {
        LOGE("Invalid ZIM handle: %lld", handle);
        return NULL;
    }
    
    // Get the query
    const char *queryChars = env->GetStringUTFChars(query, NULL);
    std::string queryStr(queryChars);
    env->ReleaseStringUTFChars(query, queryChars);
    
    // Search for entries
    std::vector<std::shared_ptr<ZimEntry>> results;
    if (!it->second->search(queryStr, results, limit)) {
        LOGE("Failed to search for entries");
        return NULL;
    }
    
    // Set the count
    jclass countClass = env->GetObjectClass(countObj);
    jfieldID valueField = env->GetFieldID(countClass, "value", "I");
    env->SetIntField(countObj, valueField, results.size());
    
    // Create a Java array for the results
    jclass entryClass = env->FindClass("com/robinsai/ontological_preamble/ZimDirectoryEntry");
    jobjectArray resultArray = env->NewObjectArray(results.size(), entryClass, NULL);
    
    // Fill the array
    for (size_t i = 0; i < results.size(); i++) {
        // Create a Java entry object
        jmethodID constructor = env->GetMethodID(entryClass, "<init>", "()V");
        jobject entryObj = env->NewObject(entryClass, constructor);
        
        // Set the entry fields
        jfieldID mimeTypeField = env->GetFieldID(entryClass, "mimeType", "I");
        jfieldID namespaceField = env->GetFieldID(entryClass, "namespace", "B");
        jfieldID revisionField = env->GetFieldID(entryClass, "revision", "I");
        jfieldID clusterNumberField = env->GetFieldID(entryClass, "clusterNumber", "I");
        jfieldID blobNumberField = env->GetFieldID(entryClass, "blobNumber", "I");
        jfieldID urlPtrField = env->GetFieldID(entryClass, "urlPtr", "J");
        jfieldID titlePtrField = env->GetFieldID(entryClass, "titlePtr", "J");
        
        env->SetIntField(entryObj, mimeTypeField, results[i]->mimeType);
        env->SetByteField(entryObj, namespaceField, results[i]->ns);
        env->SetIntField(entryObj, revisionField, results[i]->revision);
        env->SetIntField(entryObj, clusterNumberField, results[i]->clusterNumber);
        env->SetIntField(entryObj, blobNumberField, results[i]->blobNumber);
        env->SetLongField(entryObj, urlPtrField, results[i]->urlPtr);
        env->SetLongField(entryObj, titlePtrField, results[i]->titlePtr);
        
        // Add the entry to the array
        env->SetObjectArrayElement(resultArray, i, entryObj);
        
        // Release the local reference
        env->DeleteLocalRef(entryObj);
    }
    
    return resultArray;
}

} // extern "C"
