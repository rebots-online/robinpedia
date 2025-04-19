// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/ontology/capabilities/binary_data_capability.dart';

// Mock implementation of BinaryDataCapability for testing
class MockBinaryDataCapability implements BinaryDataCapability {
  final Map<String, Uint8List> _files = {};
  
  @override
  Future<Uint8List> readBytes(String path, {int? offset, int? length}) async {
    if (!await fileExists(path)) {
      throw Exception('File not found: $path');
    }
    
    final data = _files[path]!;
    
    if (offset != null || length != null) {
      final start = offset ?? 0;
      final end = length != null ? start + length : data.length;
      
      if (start < 0 || start >= data.length) {
        throw RangeError('Offset out of range');
      }
      
      if (end > data.length) {
        throw RangeError('Length out of range');
      }
      
      return data.sublist(start, end);
    }
    
    return data;
  }
  
  @override
  Future<int> writeBytes(String path, Uint8List data, {bool append = false}) async {
    if (append && await fileExists(path)) {
      final existingData = _files[path]!;
      final newData = Uint8List(existingData.length + data.length);
      
      newData.setRange(0, existingData.length, existingData);
      newData.setRange(existingData.length, newData.length, data);
      
      _files[path] = newData;
      return data.length;
    } else {
      _files[path] = data;
      return data.length;
    }
  }
  
  @override
  Stream<Uint8List> readBytesStream(String path, {int chunkSize = 64 * 1024}) async* {
    if (!await fileExists(path)) {
      throw Exception('File not found: $path');
    }
    
    final data = _files[path]!;
    
    for (var i = 0; i < data.length; i += chunkSize) {
      final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
      yield data.sublist(i, end);
    }
  }
  
  @override
  Future<int> getFileSize(String path) async {
    if (!await fileExists(path)) {
      throw Exception('File not found: $path');
    }
    
    return _files[path]!.length;
  }
  
  @override
  Future<bool> fileExists(String path) async {
    return _files.containsKey(path);
  }
  
  @override
  Future<bool> deleteFile(String path) async {
    if (!await fileExists(path)) {
      return false;
    }
    
    _files.remove(path);
    return true;
  }
}

void main() {
  group('BinaryDataCapability', () {
    late MockBinaryDataCapability binaryData;
    
    setUp(() {
      binaryData = MockBinaryDataCapability();
    });
    
    test('should write and read binary data', () async {
      // Arrange
      final path = 'test.bin';
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      // Act
      final bytesWritten = await binaryData.writeBytes(path, data);
      final readData = await binaryData.readBytes(path);
      
      // Assert
      expect(bytesWritten, equals(data.length));
      expect(readData, equals(data));
    });
    
    test('should append binary data', () async {
      // Arrange
      final path = 'test.bin';
      final data1 = Uint8List.fromList([1, 2, 3]);
      final data2 = Uint8List.fromList([4, 5]);
      
      // Act
      await binaryData.writeBytes(path, data1);
      final bytesWritten = await binaryData.writeBytes(path, data2, append: true);
      final readData = await binaryData.readBytes(path);
      
      // Assert
      expect(bytesWritten, equals(data2.length));
      expect(readData, equals(Uint8List.fromList([1, 2, 3, 4, 5])));
    });
    
    test('should read binary data with offset and length', () async {
      // Arrange
      final path = 'test.bin';
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      // Act
      await binaryData.writeBytes(path, data);
      final readData1 = await binaryData.readBytes(path, offset: 1);
      final readData2 = await binaryData.readBytes(path, offset: 1, length: 2);
      
      // Assert
      expect(readData1, equals(Uint8List.fromList([2, 3, 4, 5])));
      expect(readData2, equals(Uint8List.fromList([2, 3])));
    });
    
    test('should throw when reading non-existent file', () async {
      // Act & Assert
      expect(
        () => binaryData.readBytes('non-existent.bin'),
        throwsA(isA<Exception>()),
      );
    });
    
    test('should throw when reading with invalid offset or length', () async {
      // Arrange
      final path = 'test.bin';
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      // Act
      await binaryData.writeBytes(path, data);
      
      // Assert
      expect(
        () => binaryData.readBytes(path, offset: -1),
        throwsA(isA<RangeError>()),
      );
      
      expect(
        () => binaryData.readBytes(path, offset: 5),
        throwsA(isA<RangeError>()),
      );
      
      expect(
        () => binaryData.readBytes(path, offset: 0, length: 6),
        throwsA(isA<RangeError>()),
      );
    });
    
    test('should read binary data as a stream', () async {
      // Arrange
      final path = 'test.bin';
      final data = Uint8List.fromList(List.generate(100, (i) => i));
      
      // Act
      await binaryData.writeBytes(path, data);
      final chunks = await binaryData.readBytesStream(path, chunkSize: 30).toList();
      
      // Assert
      expect(chunks.length, 4);
      expect(chunks[0], equals(data.sublist(0, 30)));
      expect(chunks[1], equals(data.sublist(30, 60)));
      expect(chunks[2], equals(data.sublist(60, 90)));
      expect(chunks[3], equals(data.sublist(90, 100)));
    });
    
    test('should get file size', () async {
      // Arrange
      final path = 'test.bin';
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      // Act
      await binaryData.writeBytes(path, data);
      final size = await binaryData.getFileSize(path);
      
      // Assert
      expect(size, equals(data.length));
    });
    
    test('should check if a file exists', () async {
      // Arrange
      final path = 'test.bin';
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      // Act
      final existsBefore = await binaryData.fileExists(path);
      await binaryData.writeBytes(path, data);
      final existsAfter = await binaryData.fileExists(path);
      
      // Assert
      expect(existsBefore, false);
      expect(existsAfter, true);
    });
    
    test('should delete a file', () async {
      // Arrange
      final path = 'test.bin';
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      // Act
      await binaryData.writeBytes(path, data);
      final deletedExisting = await binaryData.deleteFile(path);
      final deletedNonExistent = await binaryData.deleteFile('non-existent.bin');
      final existsAfterDelete = await binaryData.fileExists(path);
      
      // Assert
      expect(deletedExisting, true);
      expect(deletedNonExistent, false);
      expect(existsAfterDelete, false);
    });
  });
}
