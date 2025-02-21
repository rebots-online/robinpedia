# Robinpedia System Diagrams

## System Architecture

```mermaid
graph TB
    subgraph UI["UI Layer"]
        AV[Article Viewer]
        CKP[Cozy Knowledge Path]
        AT[Achievement Toast]
        OI[Offline Indicator]
    end

    subgraph Core["Core Components"]
        ZP[ZIM Parser]
        RD[Resilient Downloader]
        DQ[Download Queue]
        SE[Search Engine]
        SM[Sync Manager]
    end

    subgraph Knowledge["Knowledge Management"]
        KG[Knowledge Graph]
        HE[Healing Engine]
        KN[Knowledge Nudger]
        AP[Article Parser]
        OQ[Offline Queue]
    end

    subgraph Engagement["Engagement System"]
        AS[Achievement System]
        KS[Knowledge Sharing]
        TTS[Text-to-Speech]
        OS[Offline Sharing]
    end

    subgraph Storage["Storage Layer"]
        STM[Storage Manager]
        SS[Secure Storage]
        KL[Kiwix Library]
        DB[Drift Database]
    end

    subgraph External["External Systems"]
        ZR[ZIM Repository]
        PS[Payment System]
        SR[Share Repository]
    end

    %% UI Layer Connections
    UI --> Core
    UI --> Knowledge
    UI --> Engagement
    OI --> SM

    %% Core Component Connections
    Core --> Storage
    ZP --> KG
    RD --> ZR
    SE --> KG
    SM --> OQ
    SM --> DB

    %% Knowledge Management Connections
    KG --> HE
    KG --> KN
    AP --> KG
    OQ --> KG

    %% Engagement System Connections
    AS --> KG
    KS --> KG
    TTS --> AV
    OS --> OQ
    OS --> SR

    %% Storage Layer Connections
    STM --> SS
    STM --> KL
    STM --> DB

    %% External Connections
    PS --> SS
    SR --> KS
```

## Offline Data Flow

```mermaid
sequenceDiagram
    participant User
    participant UI
    participant SM as Sync Manager
    participant OQ as Offline Queue
    participant DB as Database
    participant Net as Network

    User->>UI: Attempt Action
    UI->>SM: Check Connection
    SM-->>UI: Connection Status

    alt Offline
        UI->>OQ: Queue Operation
        OQ->>DB: Store Operation
        UI-->>User: Show Offline Status
    else Online
        UI->>Net: Execute Operation
        Net-->>UI: Operation Result
        UI-->>User: Show Result
    end

    loop Background Sync
        SM->>Net: Check Connection
        alt Connection Restored
            SM->>DB: Get Queued Operations
            DB-->>SM: Pending Operations
            loop For Each Operation
                SM->>Net: Execute Operation
                Net-->>SM: Operation Result
                SM->>DB: Update Status
            end
            SM->>UI: Update Sync Status
        end
    end
```

## Article Management Flow

```mermaid
sequenceDiagram
    participant User
    participant AV as Article Viewer
    participant AP as Article Parser
    participant DB as Database
    participant SS as Secure Storage

    User->>AV: View Article
    AV->>DB: Request Article
    DB-->>AV: Article Data

    alt Article Has Images
        AV->>AP: Process Images
        AP->>SS: Cache Images
        SS-->>AP: Image Paths
        AP-->>AV: Updated Content
    end

    alt User Edits
        User->>AV: Edit Article
        AV->>DB: Queue Edit
        DB-->>AV: Confirm Queue
        AV-->>User: Show Status
    end

    alt User Shares
        User->>AV: Share Article
        AV->>DB: Queue Share
        DB-->>AV: Confirm Queue
        AV-->>User: Show Status
    end
```

## Entity Relationships

```mermaid
erDiagram
    Article ||--o{ KnowledgeNode : "mapped_to"
    KnowledgeNode ||--o{ KnowledgeNode : "relates_to"
    Article ||--o{ Achievement : "unlocks"
    User ||--o{ Achievement : "earns"
    User ||--o{ Article : "reads"
    Article ||--o{ Category : "belongs_to"
    KnowledgeNode ||--o{ Category : "categorized_as"
    User ||--o{ KnowledgeShare : "creates"
    Article ||--o{ KnowledgeShare : "shared_in"
```

## Component States

```mermaid
stateDiagram-v2
    [*] --> Idle
    
    state "Content Management" as CM {
        Idle --> Downloading
        Downloading --> Processing
        Processing --> Ready
        Ready --> Idle
        Downloading --> Error
        Error --> Idle
    }
    
    state "Knowledge Graph" as KG {
        Ready --> Learning
        Learning --> Healing
        Healing --> Ready
    }
    
    state "User Engagement" as UE {
        Ready --> Reading
        Reading --> Achieving
        Reading --> Sharing
        Achieving --> Ready
        Sharing --> Ready
    }
