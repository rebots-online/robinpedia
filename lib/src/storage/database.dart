import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'database.g.dart';

/// Database tables and queries for the application
@DriftDatabase(
  tables: [Articles, ArticleMetadata, SearchIndices, OfflineQueue],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // Add future migrations here
      },
    );
  }
}

/// Stores article content and metadata
class Articles extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get content => text()();
  TextColumn get rawContent => text()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isOffline => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Stores article metadata for quick access
class ArticleMetadata extends Table {
  TextColumn get id => text().references(Articles, #id)();
  TextColumn get title => text()();
  TextColumn get snippet => text()();
  DateTimeColumn get lastAccessed => dateTime()();
  IntColumn get accessCount => integer().withDefault(const Constant(0))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Stores search indices for full-text search
class SearchIndices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get articleId => text().references(Articles, #id)();
  TextColumn get term => text()();
  IntColumn get frequency => integer()();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Stores offline operations queue
class OfflineQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operation => text()();
  TextColumn get payload => text()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get isProcessed => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'robinpedia.sqlite'));
    return NativeDatabase(file);
  });
}
