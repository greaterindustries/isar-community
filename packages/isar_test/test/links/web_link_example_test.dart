import 'package:isar_community/isar.dart';
import 'package:isar_test/isar_test.dart';
import 'package:test/test.dart';

part 'web_link_example_test.g.dart';

/// This test demonstrates the idiomatic way to use Isar Links
/// that works across all platforms, including web.
/// 
/// Key principles:
/// 1. Always use async methods (.load() and .save())
/// 2. Explicitly load links before accessing them
/// 3. IDs stay within JavaScript safe integer range (±9,007,199,254,740,991)

@collection
class Author {
  Author(this.name);

  Id? id;
  
  final String name;

  @override
  String toString() => 'Author($id, $name)';

  @override
  bool operator ==(Object other) =>
      other is Author && id == other.id && name == other.name;

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}

@collection
class Book {
  Book(this.title);

  Id? id;
  
  final String title;
  
  final author = IsarLink<Author>();
  
  @Backlink(to: 'author')
  final relatedBooks = IsarLinks<Book>();

  @override
  String toString() => 'Book($id, $title)';

  @override
  bool operator ==(Object other) =>
      other is Book && id == other.id && title == other.title;

  @override
  int get hashCode => id.hashCode ^ title.hashCode;
}

void main() {
  group('Web-compatible Link Usage', () {
    late Isar isar;

    setUp(() async {
      isar = await openTempIsar([AuthorSchema, BookSchema]);
    });

    isarTest('Idiomatic async link pattern (works on all platforms)', () async {
      // Create objects
      final author = Author('Stephen King');
      final book1 = Book('The Shining');
      final book2 = Book('It');

      // Set up the link
      book1.author.value = author;
      book2.author.value = author;

      // Save everything (async pattern)
      await isar.tWriteTxn(() async {
        await isar.books.tPut(book1);
        await isar.books.tPut(book2);
        await isar.authors.tPut(author);
        await book1.author.tSave();
        await book2.author.tSave();
      });

      // Retrieve and verify - ALWAYS load links explicitly
      final retrievedBook = await isar.books.tGet(book1.id!);
      expect(retrievedBook, isNotNull);
      
      // This is the key: explicitly load the link before using it
      await retrievedBook!.author.tLoad();
      expect(retrievedBook.author.value, author);
      expect(retrievedBook.author.value!.name, 'Stephen King');

      // Test backlinks
      final retrievedAuthor = await isar.authors.tGet(author.id!);
      await retrievedAuthor!.relatedBooks.tLoad();
      expect(retrievedAuthor.relatedBooks.length, 2);
      expect(retrievedAuthor.relatedBooks, contains(book1));
      expect(retrievedAuthor.relatedBooks, contains(book2));
    });

    isarTest('Links work with auto-increment IDs', () async {
      // Use auto-increment IDs (which stay within safe integer range)
      final author = Author('Jane Austen')..id = Isar.autoIncrement;
      final book = Book('Pride and Prejudice')..id = Isar.autoIncrement;

      book.author.value = author;

      await isar.tWriteTxn(() async {
        await isar.authors.tPut(author);
        await isar.books.tPut(book);
        await book.author.tSave();
      });

      // Verify IDs were assigned
      expect(author.id, isNotNull);
      expect(author.id, isNot(Isar.autoIncrement));
      expect(book.id, isNotNull);
      expect(book.id, isNot(Isar.autoIncrement));

      // Verify link works
      final retrieved = await isar.books.tGet(book.id!);
      await retrieved!.author.tLoad();
      expect(retrieved.author.value, author);
    });

    isarTest('Links work with manual IDs within safe range', () async {
      // Use manual IDs within JavaScript safe integer range
      const safeId1 = 1000000;
      const safeId2 = 2000000;

      final author = Author('Isaac Asimov')..id = safeId1;
      final book = Book('Foundation')..id = safeId2;

      book.author.value = author;

      await isar.tWriteTxn(() async {
        await isar.authors.tPut(author);
        await isar.books.tPut(book);
        await book.author.tSave();
      });

      // Retrieve and verify
      final retrieved = await isar.books.tGet(safeId2);
      await retrieved!.author.tLoad();
      expect(retrieved.author.value!.id, safeId1);
      expect(retrieved.author.value!.name, 'Isaac Asimov');
    });

    isarTest('Update and reset links', () async {
      final author1 = Author('Author 1');
      final author2 = Author('Author 2');
      final book = Book('Sample Book');

      book.author.value = author1;

      await isar.tWriteTxn(() async {
        await isar.authors.tPutAll([author1, author2]);
        await isar.books.tPut(book);
        await book.author.tSave();
      });

      // Change the link
      book.author.value = author2;
      await isar.tWriteTxn(() => book.author.tSave());

      // Verify the change
      final retrieved = await isar.books.tGet(book.id!);
      await retrieved!.author.tLoad();
      expect(retrieved.author.value, author2);

      // Reset the link
      await isar.tWriteTxn(() => retrieved.author.tReset());
      await retrieved.author.tLoad();
      expect(retrieved.author.value, isNull);
    });

    isarTest('Multiple links (IsarLinks)', () async {
      final author = Author('Multi-Book Author');
      final book1 = Book('Book 1');
      final book2 = Book('Book 2');
      final book3 = Book('Book 3');

      book1.author.value = author;
      book2.author.value = author;
      book3.author.value = author;

      await isar.tWriteTxn(() async {
        await isar.authors.tPut(author);
        await isar.books.tPutAll([book1, book2, book3]);
        await book1.author.tSave();
        await book2.author.tSave();
        await book3.author.tSave();
      });

      // Use backlinks to get all books by this author
      final retrievedAuthor = await isar.authors.tGet(author.id!);
      await retrievedAuthor!.relatedBooks.tLoad();

      expect(retrievedAuthor.relatedBooks.length, 3);
      expect(retrievedAuthor.relatedBooks, containsAll([book1, book2, book3]));
    });
  });
}
