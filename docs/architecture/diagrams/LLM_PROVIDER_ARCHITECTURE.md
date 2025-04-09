# LLM Provider Architecture Diagram

**Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.**

## High-Level Architecture

```mermaid
graph TD
    subgraph "Content Sources"
        A[Article Content] --> B[Content Integration Hub]
        C[User Annotations] --> B
        D[Knowledge Graph] --> B
        E[CLIP Embeddings] --> B
    end
    
    subgraph "LLM Provider Service"
        B --> F[Request Builder]
        F --> G[Provider Router]
        G --> H[Response Processor]
        I[Configuration Manager] --> G
    end
    
    subgraph "Provider Adapters"
        G --> J[Ollama Adapter]
        G --> K[LMStudio Adapter]
        G --> L[VLLM Adapter]
        G --> M[Oobabooga Adapter]
        G --> N[H2OGPT Adapter]
        G --> O[Cloud Provider Adapters]
    end
    
    subgraph "Application Services"
        H --> P[Article Chat Service]
        H --> Q[Knowledge Extraction]
        H --> R[Annotation Assistant]
        H --> S[Visual Understanding]
    end
```

## Component Interaction Flow

```mermaid
sequenceDiagram
    participant User
    participant ArticleView
    participant ChatService
    participant ContentBridge
    participant LLMProvider
    participant KnowledgeGraph
    
    User->>ArticleView: View article with annotations
    ArticleView->>ContentBridge: Request semantic content
    ContentBridge->>ArticleView: Return semantic elements
    
    User->>ChatService: Ask question about article
    ChatService->>ContentBridge: Get semantic context
    ChatService->>KnowledgeGraph: Query related entities
    
    ChatService->>LLMProvider: Send request with context
    
    alt Local Ollama
        LLMProvider->>Ollama: Forward prompt + context
        Ollama->>LLMProvider: Return response
    else LMStudio
        LLMProvider->>LMStudio: Forward prompt + context
        LMStudio->>LLMProvider: Return response
    else Cloud API
        LLMProvider->>CloudAPI: Forward prompt + context
        CloudAPI->>LLMProvider: Return response
    end
    
    LLMProvider->>ChatService: Return processed response
    ChatService->>User: Display response
    
    opt Knowledge Update
        LLMProvider->>KnowledgeGraph: Store new insights
    end
```

## Data Flow Diagram

```mermaid
flowchart LR
    subgraph User Interface
        A[Article View]
        B[Chat Interface]
        C[Annotation Editor]
    end
    
    subgraph Content Processing
        D[Semantic Content Bridge]
        E[Document Understanding]
        F[CLIP Processor]
    end
    
    subgraph LLM System
        G[LLM Provider Service]
        H[Configuration Manager]
        I[Request Builder]
        J[Response Processor]
    end
    
    subgraph Adapters
        K[Local Adapters]
        L[Remote Adapters]
    end
    
    subgraph Knowledge System
        M[Knowledge Graph Service]
        N[Entity Manager]
        O[Relationship Tracker]
    end
    
    A --> D
    B --> G
    C --> D
    D --> E
    E --> F
    D --> G
    F --> G
    G --> H
    G --> I
    G --> J
    G --> K
    G --> L
    G <--> M
    M --> N
    M --> O
    D <--> M
```

## Provider Configuration Model

```mermaid
classDiagram
    class LLMProviderConfig {
        +String name
        +String type
        +String endpoint
        +List~ModelConfig~ models
        +bool default
        +Map~String,dynamic~ parameters
        +validate()
        +toJson()
        +fromJson()
    }
    
    class ModelConfig {
        +String id
        +String displayName
        +int contextWindow
        +bool supportsMultimodal
        +Map~String,dynamic~ capabilities
        +toJson()
        +fromJson()
    }
    
    class AIRequest {
        +String prompt
        +List~AIMessage~ history
        +Map~String,dynamic~ parameters
        +List~AIContent~ context
        +List~double~ clipEmbedding
        +List~Map~ knowledgeGraphContext
        +List~Map~ annotationContext
        +toJson()
        +fromJson()
    }
    
    class AIResponse {
        +String text
        +Map~String,dynamic~ metadata
        +double confidence
        +List~String~ citations
        +List~AIContent~ generatedContent
        +toJson()
        +fromJson()
    }
    
    LLMProviderConfig "1" --> "*" ModelConfig
    LLMProviderConfig --> AIRequest
    AIRequest --> AIResponse
```

## Integration with Knowledge Graph

```mermaid
graph TD
    subgraph "LLM Integration"
        A[LLM Provider Service]
    end
    
    subgraph "Knowledge Graph"
        B[Entity Manager]
        C[Relationship Tracker]
        D[Entity Node]
        E[Relationship Edge]
        F[Entity Node]
        
        B --- C
        D --- E
        E --- F
    end
    
    subgraph "Semantic Content"
        G[Article DOM Elements]
        H[Semantic Mapping]
        I[Element Coordinates]
        
        G --- H
        H --- I
    end
    
    subgraph "Annotation System"
        J[User Annotations]
        K[Annotation Targets]
        L[Semantic Meaning]
        
        J --- K
        K --- L
    end
    
    A <--> B
    A <--> C
    H <--> D
    L <--> F
    K <--> I
```

## Security and Privacy Model

```mermaid
flowchart TD
    subgraph "User Input"
        A[User Query]
    end
    
    subgraph "Privacy Controls"
        B[Content Filter]
        C[Anonymization]
        D[Local Processing Check]
        
        A --> B
        B --> C
        C --> D
    end
    
    subgraph "Processing Decision"
        E{Is Local Only?}
        
        D --> E
    end
    
    subgraph "Local Processing"
        F[Local LLM]
        G[Local Knowledge Graph]
        
        E -->|Yes| F
        F <--> G
    end
    
    subgraph "Remote Processing"
        H[Remote API]
        I[API Key Management]
        J[Data Minimization]
        
        E -->|No| J
        J --> H
        I --> H
    end
    
    subgraph "Response"
        K[Processed Response]
        L[Usage Tracking]
        
        F --> K
        H --> K
        K --> L
    end
```
