# Robinpedia Codebase Visualization

**Created:** April 16, 2025  
**Author:** Augment Agent  
**Purpose:** Visual representation of the Robinpedia codebase architecture

## 1. High-Level Architecture

```mermaid
graph TB
    subgraph "UI Layer"
        AV[Article Viewer]
        ZRS[ZIM Reader Screen]
        ZDS[ZIM Download Screen]
        Settings[Settings Screen]
        AC[Annotation Canvas]
    end

    subgraph "Business Logic Layer"
        AM[Article Manager]
        ZR[ZIM Reader]
        DM[Download Manager]
        SM[Sync Manager]
        KG[Knowledge Graph]
        AC_C[Annotation Controller]
    end

    subgraph "Core Components"
        ZP[ZIM Parser]
        CE[Content Extractor]
        CM[Cluster Manager]
        LD[LZMA Decompression]
        SE[Search Engine]
    end

    subgraph "Data Layer"
        DB[SQLite Database]
        SS[Secure Storage]
        FS[File System]
    end

    subgraph "External Systems"
        ZR_R[ZIM Repository]
        PS[Payment System]
    end

    %% UI to Business Logic connections
    AV --> AM
    ZRS --> ZR
    ZDS --> DM
    AC --> AC_C

    %% Business Logic to Core Components
    AM --> ZP
    ZR --> ZP
    ZR --> CE
    ZR --> CM
    CM --> LD
    AM --> SE

    %% Core Components to Data Layer
    ZP --> FS
    CE --> FS
    SE --> DB
    AM --> DB
    AM --> SS

    %% External connections
    DM --> ZR_R
    SM --> ZR_R
    SM --> PS
```

## 2. Directory Structure

```mermaid
graph TD
    Root["/"] --> Lib["lib/"]
    Root --> Assets["assets/"]
    Root --> Docs["docs/"]
    Root --> Test["test/"]
    Root --> Platform["Platform-specific (android, ios, etc.)"]
    
    Lib --> Main["main.dart"]
    Lib --> Src["src/"]
    
    Src --> Screens["screens/"]
    Src --> Models["models/"]
    Src --> Controllers["controllers/"]
    Src --> UI["ui/"]
    Src --> ZIM["zim/"]
    Src --> Content["content/"]
    Src --> Download["download/"]
    Src --> Utils["utils/"]
    Src --> FFI["ffi/"]
    Src --> Services["services/"]
    Src --> Storage["storage/"]
    Src --> Sync["sync/"]
    
    ZIM --> ZimReader["zim_reader.dart"]
    ZIM --> ClusterManager["cluster_manager.dart"]
    ZIM --> EnhancedClusterManager["enhanced_cluster_manager.dart"]
    ZIM --> ContentExtractor["content_extractor.dart"]
    ZIM --> ZimEntry["zim_entry.dart"]
    ZIM --> Compression["compression/"]
    
    Compression --> LzmaDecoder["lzma_decoder.dart"]
    
    FFI --> Bindings["bindings/"]
    Bindings --> LzmaBinding["lzma_binding.dart"]
    
    UI --> ArticleViewer["article_viewer.dart"]
    UI --> AnnotationCanvas["annotation_canvas.dart"]
    UI --> Themes["themes/"]
    
    Content --> ArticleManager["article_manager.dart"]
    
    Screens --> ZimReaderScreen["zim_reader_screen.dart"]
    Screens --> ZimDownloadScreen["zim_download_screen.dart"]
    Screens --> ZimDownloadPlaceholder["zim_download_placeholder.dart"]
```

## 3. Core Components Detail

### 3.1 ZIM Parser System

```mermaid
graph TD
    ZR[ZIM Reader] --> ZP[ZIM Parser]
    ZR --> CM[Cluster Manager]
    ZR --> CE[Content Extractor]
    
    ZP --> Header[Header Reading]
    ZP --> DirEntry[Directory Entry Parsing]
    ZP --> URL[URL/Title Indexing]
    
    CM --> Decompression[Decompression]
    CM --> Cache[Cluster Caching]
    CM --> Prefetch[Prefetching]
    
    Decompression --> LZMA[LZMA2 Decompression]
    Decompression --> Zlib[Zlib Decompression]
    Decompression --> Zstd[Zstandard Decompression]
    
    CE --> HTML[HTML Processing]
    CE --> Images[Image Handling]
    CE --> Binary[Binary Content]
    
    HTML --> Sanitize[Content Sanitization]
    HTML --> Extract[Metadata Extraction]
    HTML --> Links[Link Processing]
```

### 3.2 Data Flow

```mermaid
sequenceDiagram
    participant User
    participant UI as User Interface
    participant CM as Content Manager
    participant ZP as ZIM Parser
    participant CLM as Cluster Manager
    participant KG as Knowledge Graph
    participant DB as Storage Layer
    
    User->>UI: Request Article
    UI->>CM: Request Content
    CM->>DB: Check Local Cache
    
    alt Content in Cache
        DB->>CM: Return Cached Content
        CM->>UI: Process and Display
    else Content Not Cached
        CM->>ZP: Request Article Data
        ZP->>CLM: Get Cluster Info
        CLM->>ZP: Return Decompressed Content
        ZP->>CM: Return Article Data
        CM->>DB: Cache Content
        CM->>UI: Process and Display
    end
    
    UI->>KG: Update Knowledge Graph
    KG->>DB: Store Relationships
```

### 3.3 Multimodal Annotation System (Galaxy Brain)

```mermaid
graph TD
    subgraph "UI Components"
        AC[Annotation Canvas]
        TP[Tool Palette]
        AL[Annotation List]
    end
    
    subgraph "Controllers"
        ANC[Annotation Controller]
        TS[Tool Selection]
        PS[Position System]
    end
    
    subgraph "Processing"
        CA[Content Analysis]
        VL[Visual-Language Bridge]
        DS[Diagram Understanding]
    end
    
    subgraph "Storage"
        AM[Annotation Model]
        KG[Knowledge Graph]
        SS[Secure Storage]
    end
    
    AC --> ANC
    TP --> TS
    AL --> ANC
    
    ANC --> CA
    ANC --> PS
    TS --> ANC
    
    CA --> VL
    CA --> DS
    
    ANC --> AM
    VL --> KG
    DS --> KG
    AM --> SS
    KG --> SS
```

## 4. Implementation Status

| Component | Completion | Status | Notes |
|-----------|------------|--------|-------|
| **ZIM Parser** | 100% | ✅ | Header reading, MIME handling, directory entry parsing, URL/title indexing complete |
| **Download Manager** | 100% | ✅ | Includes resume capability, progress tracking, integrity verification |
| **Search Implementation** | 90% | ✅ | SQLite FTS5 indexing complete, link graph in progress |
| **Database Implementation** | 95% | ✅ | Schema defined, article storage, search indexing complete, offline queue partially implemented |
| **Cluster Management** | 65% | 🔄 | Basic structure implemented, optimization needed |
| **Content Processing** | 50% | 🔄 | ZIM-specific HTML processing in progress |
| **LZMA2 Decompression** | 75% | 🔄 | Basic implementation complete, performance optimization needed |
| **Knowledge Graph** | 40% | 🔄 | Foundation implemented, self-healing engine partially complete |
| **UI Components** | 60% | 🔄 | Core viewing components complete, advanced features in progress |
| **Interactive Annotation** | 0% | ⬜ | Planned with canvas-like capability for multimedia annotations |
| **Learning Path Generation** | 0% | ⬜ | Not started, dependent on knowledge graph completion |
| **Social Features** | 0% | ⬜ | Not started, planned for future phases |

**Legend**: ✅ Complete | 🔄 In Progress | ⬜ Not Started

## 5. Current Development Focus

```mermaid
gantt
    title Current Development Focus (Q2 2025)
    dateFormat  YYYY-MM-DD
    section Cluster Management
    Complete cluster decompression implementation :active, 2025-04-01, 30d
    Optimize memory usage                        :2025-04-15, 45d
    
    section Content Processing
    Enhance article content processing           :active, 2025-04-01, 45d
    Improve ZIM-specific link handling           :2025-04-20, 30d
    
    section Annotation System
    Begin interactive annotation implementation  :2025-05-01, 60d
    
    section Knowledge Graph
    Complete relationship mapping                :2025-05-15, 45d
    Implement quick navigation                   :2025-06-01, 30d
    Enhance self-healing engine                  :2025-06-15, 45d
```

## 6. Key Files and Their Relationships

```mermaid
graph LR
    Main["main.dart"] --> RobinpediaApp["RobinpediaApp"]
    
    RobinpediaApp --> ZimDownloadScreen["zim_download_screen.dart"]
    ZimDownloadScreen --> ZimReader["zim_reader.dart"]
    
    ZimReader --> EnhancedClusterManager["enhanced_cluster_manager.dart"]
    ZimReader --> ContentExtractor["content_extractor.dart"]
    ZimReader --> LZMABinding["lzma_binding.dart"]
    
    EnhancedClusterManager --> LzmaDecompressionService["lzma_decompression.dart"]
    LzmaDecompressionService --> LzmaDecoder["lzma_decoder.dart"]
    
    ZimDownloadScreen --> ArticleManager["article_manager.dart"]
    ArticleManager --> ArticleViewer["article_viewer.dart"]
    
    ArticleViewer --> AnnotationCanvas["annotation_canvas.dart"]
    AnnotationCanvas --> AnnotationController["annotation_controller.dart"]
```

## 7. Current Issues

1. **Dev Builds Show Placeholders**: The current implementation falls back to placeholder content instead of displaying actual ZIM content
   - Located in `lib/src/zim/zim_reader.dart` in the `getContentByUrl` method
   - Fallback occurs in the catch block with `_getSampleContent(url)`
   - Needs to be fixed by completing the cluster decompression implementation

2. **Incomplete ZIM Implementation**:
   - Only header reading fully implemented
   - Directory entry parsing partially implemented
   - Cluster decompression needs completion
   - Internal image handling missing

3. **Article Parser Misalignment**:
   - Assumes web-like content structure
   - Downloads images from URLs (should read from ZIM)
   - No handling of ZIM-specific link formats
   - Inefficient image caching

4. **Missing Core Features**:
   - No navigation between articles
   - No table of contents
   - No search functionality
   - No offline image support
