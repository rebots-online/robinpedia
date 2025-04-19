// Copyright (C)2025 Robin L. M. Cheung, MBA. All rights reserved.

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:robinpedia/platforms/android/binary_data_ffi.dart';

void main() {
  group('FfiBinaryDataCapability', () {
    late FfiBinaryDataCapability binaryData;
    late Directory tempDir;
    late String testFilePath;
    
    setUp(() async {
      binaryData = FfiBinaryDataCapability();
      tempDir = await Directory.systemTemp.createTemp('binary_data_test_');
      testFilePath = '${tempDir.path}/test.bin';
    });
    
    tearDown(() async {
      await tempDir.delete(recursive: true);
    });
    
    test('should write and read binary data', () async {
      // Create test data
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      // Write data to file
      final bytesWritten = await binaryData.writeBytes(testFilePath, data);
      
      // Check that the correct number of bytes was written
      expect(bytesWritten, equals(data.length));
      
      // Read data from file
      final readData = await binaryData.readBytes(testFilePath);
      
      // Check that the read data matches the written data
      expect(readData, equals(data));
    });
    
    test('should read binary data with offset and length', () async {
      // Create test data
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      // Write data to file
      await binaryData.writeBytes(testFilePath, data);
      
      // Read data with offset
      final readData1 = await binaryData.readBytes(testFilePath, offset: 1);
      
      // Check that the read data matches the expected subset
      expect(readData1, equals(Uint8List.fromList([2, 3, 4, 5])));
      
      // Read data with offset and length
      final readData2 = await binaryData.readBytes(testFilePath, offset: 1, length: 2);
      
      // Check that the read data matches the expected subset
      expect(readData2, equals(Uint8List.fromList([2, 3])));
    });
    
    test('should append binary data', () async {
      // Create test data
      final data1 = Uint8List.fromList([1, 2, 3]);
      final data2 = Uint8List.fromList([4, 5]);
      
      // Write first chunk
      await binaryData.writeBytes(testFilePath, data1);
      
      // Append second chunk
      final bytesWritten = await binaryData.writeBytes(testFilePath, data2, append: true);
      
      // Check that the correct number of bytes was written
      expect(bytesWritten, equals(data2.length));
      
      // Read the combined data
      final readData = await binaryData.readBytes(testFilePath);
      
      // Check that the read data matches the combined data
      expect(readData, equals(Uint8List.fromList([1, 2, 3, 4, 5])));
    });
    
    test('should throw when reading non-existent file', () async {
      // Attempt to read a non-existent file
      expect(
        () => binaryData.readBytes('${tempDir.path}/non-existent.bin'),
        throwsA(isA<Exception>()),
      );
    });
    
    test('should read binary data as a stream', () async {
      // Create test data
      final data = Uint8List.fromList(List.generate(100, (i) => i));
      
      // Write data to file
      await binaryData.writeBytes(testFilePath, data);
      
      // Read data as a stream with chunk size 30
      final chunks = await binaryData.readBytesStream(testFilePath, chunkSize: 30).toList();
      
      // Check that the correct number of chunks was read
      expect(chunks.length, 4);
      
      // Check that the chunks have the expected sizes
      expect(chunks[0].length, 30);
      expect(chunks[1].length, 30);
      expect(chunks[2].length, 30);
      expect(chunks[3].length, 10);
      
      // Check that the chunks have the expected content
      expect(chunks[0], equals(data.sublist(0, 30)));
      expect(chunks[1], equals(data.sublist(30, 60)));
      expect(chunks[2], equals(data.sublist(60, 90)));
      expect(chunks[3], equals(data.sublist(90, 100)));
    });
    
    test('should get file size', () async {
      // Create test data
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      // Write data to file
      await binaryData.writeBytes(testFilePath, data);
      
      // Get file size
      final size = await binaryData.getFileSize(testFilePath);
      
      // Check that the size matches the data length
      expect(size, equals(data.length));
    });
    
    test('should check if a file exists', () async {
      // Check that the file doesn't exist initially
      expect(await binaryData.fileExists(testFilePath), false);
      
      // Create test data
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      // Write data to file
      await binaryData.writeBytes(testFilePath, data);
      
      // Check that the file exists now
      expect(await binaryData.fileExists(testFilePath), true);
    });
    
    test('should delete a file', () async {
      // Create test data
      final data = Uint8List.fromList([1, 2, 3, 4, 5]);
      
      // Write data to file
      await binaryData.writeBytes(testFilePath, data);
      
      // Check that the file exists
      expect(await binaryData.fileExists(testFilePath), true);
      
      // Delete the file
      final deleted = await binaryData.deleteFile(testFilePath);
      
      // Check that the file was deleted
      expect(deleted, true);
      expect(await binaryData.fileExists(testFilePath), false);
    });
    
    test('should return false when deleting non-existent file', () async {
      // Attempt to delete a non-existent file
      final deleted = await binaryData.deleteFile('${tempDir.path}/non-existent.bin');
      
      // Check that the operation returned false
      expect(deleted, false);
    });
  });
}
