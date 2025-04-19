#include "zim_entry.h"

bool ZimEntry::isRedirect() const {
    // Check if the cluster number is 0xFFFFFFFF
    return clusterNumber == 0xFFFFFFFF;
}

uint32_t ZimEntry::getRedirectIndex() const {
    // The redirect index is stored in the blob number
    return blobNumber;
}
