// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/article.dart';
import '../content/semantic_content_bridge.dart';
import '../knowledge/knowledge_graph_service.dart';

/// Service that enables conversational interaction with article content
/// 
/// This "chat with Wikipedia" functionality leverages the semantic understanding
/// of the document to provide contextual responses about the content.
class ArticleChatService {
  final SemanticContentBridge _semanticBridge;
  final KnowledgeGraphService _knowledgeGraphService;
  
  ArticleChatService({
    required SemanticContentBridge semanticBridge,
    required KnowledgeGraphService knowledgeGraphService,
  }) : 
    _semanticBridge = semanticBridge,
    _knowledgeGraphService = knowledgeGraphService;
  
  /// Chat history for the current article session
  final List<ChatMessage> _chatHistory = [];
  
  /// Current article being discussed
  Article? _currentArticle;
  
  /// Set the current article context for the chat
  void setArticleContext(Article article) {
    _currentArticle = article;
    _chatHistory.clear();
    
    // Add a system message to initialize the conversation
    _chatHistory.add(ChatMessage(
      role: ChatRole.system,
      content: 'You are now discussing the article "${article.title}".',
      timestamp: DateTime.now(),
    ));
  }
  
  /// Get the chat history for the current article
  List<ChatMessage> getChatHistory() {
    return List.unmodifiable(_chatHistory);
  }
  
  /// Send a user message and get a response about the article
  Future<ChatMessage> sendMessage(String message) async {
    try {
      if (_currentArticle == null) {
        throw Exception('No article context set for chat');
      }
      
      // Add user message to history
      final userMessage = ChatMessage(
        role: ChatRole.user,
        content: message,
        timestamp: DateTime.now(),
      );
      _chatHistory.add(userMessage);
      
      // Generate a response based on article content and knowledge graph
      final response = await _generateResponse(message);
      _chatHistory.add(response);
      
      return response;
    } catch (e) {
      debugPrint('Error in article chat: $e');
      
      // Add error response to history
      final errorResponse = ChatMessage(
        role: ChatRole.assistant,
        content: 'I encountered an error while processing your question. Please try again.',
        timestamp: DateTime.now(),
        metadata: {'error': e.toString()},
      );
      _chatHistory.add(errorResponse);
      
      return errorResponse;
    }
  }
  
  /// Generate a response to the user's message based on article content
  /// 
  /// This is a placeholder implementation that will be replaced with actual
  /// AI-powered chat functionality integrated with the knowledge graph.
  Future<ChatMessage> _generateResponse(String userMessage) async {
    if (_currentArticle == null) {
      throw Exception('No article context set for chat');
    }
    
    // In a real implementation, this would:
    // 1. Query the knowledge graph for relevant information
    // 2. Use semantic search to find relevant content in the article
    // 3. Generate a coherent response using a language model
    
    // For now, return a simple placeholder response
    String responseContent;
    
    if (userMessage.toLowerCase().contains('what is') || 
        userMessage.toLowerCase().contains('who is') ||
        userMessage.toLowerCase().contains('tell me about')) {
      responseContent = 'This article covers "${_currentArticle!.title}". ' +
          'To provide a more detailed answer, I would need to analyze the specific ' +
          'content and knowledge graph. This functionality will be fully implemented ' +
          'in a future update.';
    } else if (userMessage.toLowerCase().contains('summary') || 
               userMessage.toLowerCase().contains('summarize')) {
      responseContent = 'This appears to be an article about "${_currentArticle!.title}". ' +
          'In the full implementation, I would provide a summary based on the semantic ' +
          'analysis of the article content.';
    } else {
      responseContent = 'I understand you\'re asking about "${_currentArticle!.title}". ' +
          'In the future, I\'ll be able to give you specific answers based on the ' +
          'article content and the knowledge graph.';
    }
    
    return ChatMessage(
      role: ChatRole.assistant,
      content: responseContent,
      timestamp: DateTime.now(),
      metadata: {
        'article_id': _currentArticle!.id,
        'article_title': _currentArticle!.title,
        'placeholder': true,
      },
    );
  }
  
  /// Clear the chat history for the current article
  void clearChatHistory() {
    _chatHistory.clear();
    
    if (_currentArticle != null) {
      // Add a system message to reinitialize the conversation
      _chatHistory.add(ChatMessage(
        role: ChatRole.system,
        content: 'You are now discussing the article "${_currentArticle!.title}".',
        timestamp: DateTime.now(),
      ));
    }
  }
}

/// Defines the possible roles in a chat conversation
enum ChatRole {
  system,
  user,
  assistant,
}

/// Represents a single message in the chat conversation
class ChatMessage {
  final ChatRole role;
  final String content;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;
  
  ChatMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    Map<String, dynamic>? metadata,
  }) : metadata = metadata ?? {};
  
  /// Convert to a JSON representation
  Map<String, dynamic> toJson() {
    return {
      'role': role.toString().split('.').last,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
  
  /// Create from a JSON representation
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: _roleFromString(json['role'] as String),
      content: json['content'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }
  
  /// Parse a role string to ChatRole enum
  static ChatRole _roleFromString(String roleStr) {
    switch (roleStr) {
      case 'system':
        return ChatRole.system;
      case 'user':
        return ChatRole.user;
      case 'assistant':
        return ChatRole.assistant;
      default:
        return ChatRole.system;
    }
  }
}
