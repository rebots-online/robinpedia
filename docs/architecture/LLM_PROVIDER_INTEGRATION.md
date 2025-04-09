# LLM Provider Integration Specification

**Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.**

## Overview

The LLM Provider Integration system enables Robinpedia to connect with various local and remote LLM solutions while maintaining a consistent interface. This system is designed to take inputs from CLIP, the annotation system, and the hybrid Knowledge Graph (hKG) to provide rich, context-aware AI capabilities throughout the application.

## Core Components

### 1. LLM Provider Service

The central coordinator that manages connections to different LLM backends:

- **Configuration Management**: Stores and retrieves endpoint information, API keys, and model preferences
- **Provider Registration**: Dynamic registration of new LLM providers
- **Request Routing**: Routes requests to the appropriate provider based on context and user preferences
- **Response Processing**: Normalizes responses from different providers into a standard format
- **Fallback Handling**: Provides graceful degradation when primary providers are unavailable

### 2. Provider Adapters

Individual adapters for different LLM solutions:

- **Ollama Adapter**: For connecting to locally-hosted Ollama instances
- **LMStudio Adapter**: For connecting to LMStudio running on the local network
- **VLLM Adapter**: For high-performance inference servers
- **Oobabooga Adapter**: For Text Generation WebUI connections
- **H2OGPT Adapter**: For H2O.ai's open-source LLM implementation
- **Cloud Provider Adapters**: For commercial API services (OpenAI, Anthropic, etc.)

### 3. Content Integration Hub

A component that integrates content from multiple sources:

- **CLIP Integration**: Takes embeddings and visual understanding from CLIP
- **Annotation Context**: Incorporates user annotations as context for queries
- **Knowledge Graph Queries**: Pulls relevant information from the hKG
- **Document Context**: Extracts relevant parts of the current article

### 4. Request Builders

Specialized request constructors for different use cases:

- **Chat Request Builder**: For conversational interactions with articles
- **Knowledge Extraction Builder**: For extracting structured knowledge from content
- **Visual Understanding Builder**: For queries that include image context
- **Annotation Assistant Builder**: For assisting with annotation creation

## Technical Specifications

### API Structure

```dart
abstract class LLMProvider {
  // Core provider methods
  Future<AIResponse> sendPrompt(AIRequest request);
  Future<Stream<AIResponseChunk>> streamResponse(AIRequest request);
  bool supportsStreaming();
  bool supportsMultimodal();
  
  // Provider capabilities
  Map<String, dynamic> getCapabilities();
  
  // Provider metadata
  String getName();
  String getDescription();
  String getVersion();
}

class AIRequest {
  final String prompt;
  final List<AIMessage> history;
  final Map<String, dynamic> parameters;
  final List<AIContent> context;
  
  // Optional CLIP embeddings
  final List<double>? clipEmbedding;
  
  // Optional knowledge graph context
  final List<Map<String, dynamic>>? knowledgeGraphContext;
  
  // Optional annotation context
  final List<Map<String, dynamic>>? annotationContext;
}

class AIResponse {
  final String text;
  final Map<String, dynamic> metadata;
  final double? confidence;
  final List<String>? citations;
  final List<AIContent>? generatedContent;
}
```

### Endpoint Configuration

Endpoints will be configurable via a JSON schema:

```json
{
  "name": "Local Ollama",
  "type": "ollama",
  "endpoint": "http://localhost:11434",
  "models": [
    {
      "id": "llama3",
      "display_name": "Llama 3 (8B)",
      "context_window": 8192,
      "supports_multimodal": false
    }
  ],
  "default": true,
  "parameters": {
    "temperature": 0.7,
    "top_p": 0.9
  }
}
```

### Integration with CLIP

The system will use CLIP for:

1. Generating embeddings for text and images
2. Creating multimodal context for queries
3. Understanding visual content in annotations
4. Processing images within articles

### Hybrid Knowledge Graph Integration

The LLM Provider Service will:

1. Query the hKG for relevant context based on the current article
2. Include annotation relationships from the knowledge graph
3. Update the knowledge graph with new insights when appropriate
4. Leverage graph structure for more coherent responses

### Annotation System Integration

1. User annotations will provide additional context for queries
2. LLMs can assist in organizing and categorizing annotations
3. The system will suggest potential annotations based on content
4. Annotations can be used to improve knowledge graph quality

## User Experience

### Settings Interface

Users will have access to a settings panel that allows them to:

1. Add/remove/edit LLM providers
2. Configure endpoint details
3. Set default models for different tasks
4. Adjust generation parameters
5. Enable/disable multimodal capabilities

### Privacy Controls

The system will include:

1. Options to keep all processing local
2. Content filtering before sending to remote APIs
3. Anonymization of sensitive content
4. Clear indicators when data is being sent externally

## Implementation Roadmap

1. Base provider interface and abstract classes
2. Configuration system and settings storage
3. Ollama adapter as the first reference implementation
4. Content integration from CLIP and document context
5. Knowledge graph integration
6. Additional provider adapters
7. Annotation system integration
8. Advanced multimodal capabilities
