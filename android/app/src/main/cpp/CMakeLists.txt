cmake_minimum_required(VERSION 3.10.2)

project(robinpedia)

# Set the C++ standard
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# Add LZMA library
add_library(lzma SHARED
    src/lzma/lzma_binding.cpp
    src/lzma/lzma_stream.cpp
)

# Add ZIM library
add_library(zim SHARED
    src/zim/zim_binding.cpp
    src/zim/zim_reader.cpp
    src/zim/zim_entry.cpp
    src/zim/zim_cluster.cpp
)

# Link libraries
target_link_libraries(lzma
    android
    log
)

target_link_libraries(zim
    android
    log
    lzma
)

# Install libraries
install(TARGETS lzma zim
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)
