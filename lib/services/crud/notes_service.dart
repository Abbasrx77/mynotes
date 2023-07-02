import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mynotes/services/crud/crud_exceptions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

class NoteService{
  Database? _db;
  List <DatabaseNote> _notes = [];

  static final NoteService _shared = NoteService._sharedInstance();
  NoteService._sharedInstance();
  factory NoteService() => _shared;
  final _notesStreamController =
  StreamController<List<DatabaseNote>>.broadcast();

  Stream<List<DatabaseNote>> get allNotes => _notesStreamController.stream;

  Future<DatabaseUser> getOrCreateUser({required String email})async{

    try{
      final user = await getUser(email:email);
      return user;
    } on CouldNotFindUser{
      final createdUser = await createUser(email:email);
      return createdUser;
    } catch(e){
      rethrow;
    }
  }

  Future<void> _cacheNotes()async{
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  Future<DatabaseNote> updateNote({
    required DatabaseNote note,
    required String text})async{
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    await getNote(id: note.id);
    final updatesCount = await db.update(noteTable, {
  textColumn: text,
});

if(updatesCount == 0){
  throw CouldNotUpdateNote();
}else{
  final updatedNote = await getNote(id: note.id);
  _notes.removeWhere((note) => note.id == updatedNote.id);
  _notes.add(updatedNote);
  _notesStreamController.add(_notes);
  return updatedNote;
}
  }

  Future<Iterable<DatabaseNote>> getAllNotes()async{
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(noteTable);

    return notes.map((noteRow) => DatabaseNote.fromRow(noteRow));

  }

  Future<DatabaseNote> getNote({required int id})async{
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final notes = await db.query(noteTable,limit: 1,where: 'id=?',whereArgs: [id]);

    if(notes.isEmpty){
      throw CouldNotFindNote();
    }else{
      final note =  DatabaseNote.fromRow(notes.first);
      _notes.removeWhere((note) => note.id == id);
      _notes.add(note);
      _notesStreamController.add(_notes);
      return note;
    }
  }

  Future<int> deleteAllNotes()async{
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final numberOfDeletions =  await db.delete(noteTable);
    _notes = [];
    _notesStreamController.add(_notes);
    return numberOfDeletions;
  }
  Future<void> deleteNote({required int id})async{
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      noteTable,
      where: 'id=?',
      whereArgs: [id],
    );
    if(deletedCount == 0){
      throw CouldNotDeleteNote();
    }else{

      _notes.removeWhere((note)=>note.id == id);
      _notesStreamController.add(_notes);
    }
  }

  Future<DatabaseNote> createNote({required DatabaseUser owner})async{
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final dbUser = await getUser(email: owner.email);
    if(dbUser != owner){
      throw CouldNotFindUser();
    }
    const text = '';
    final noteId = await db.insert(noteTable,{
      userIdColumn: owner.id,
      textColumn: text,
    });

    final note = DatabaseNote(id: noteId, userId: owner.id, text: text);
    _notes.add(note);
    _notesStreamController.add(_notes);
    return note;
  }

  Future<DatabaseUser> getUser({required String email})async{
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();

    final results = await db.query(userTable, limit: 1, where: 'email =?', whereArgs: [email.toLowerCase()]);
    if(results.isEmpty){
      throw CouldNotFindUser();
    }else{
      return DatabaseUser.fromRow(results.first);
    }

    final userId = await db.insert(userTable, {
      emailColumn : email.toLowerCase()
    });
  }

  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(userTable,
      where: 'email =?',
      whereArgs: [email.toLowerCase()],
    );
    if(deletedCount !=1 ){
      throw CouldNotDeleteUser();
    }
  }

  Future<DatabaseUser> createUser({required String email}) async{
    await _ensureDbIsOpen();
    final db = _getDatabaseOrThrow();
    final results = await db.query(userTable, limit: 1, where: 'email =?', whereArgs: [email.toLowerCase()]);
    if(results.isNotEmpty){
      throw UserAlreadyExists();
    }

    final userId = await db.insert(userTable, {
      emailColumn : email.toLowerCase()
    });

    return DatabaseUser(id: userId, email: email);
  }

  Database _getDatabaseOrThrow(){
    final  db = _db;
    if(db == null){
      throw DatabaseIsNotOpen();
    }else{
      return db;
    }
  }

  Future<void> close() async{
    final db = _db;
    if(db == null){
      throw DatabaseIsNotOpen();
    }else{
      await db.close();
    }
  }

  Future<void> _ensureDbIsOpen()async{
    try{
      await open();
    }on DatabaseAlreadyOpenException{
      //empty
    };
  }

  Future<void> open() async{
    if(_db != null){
      throw DatabaseAlreadyOpenException;
    }
    try {
    final docsPath = await getApplicationDocumentsDirectory();
    final dbPath = join(docsPath.path, dbName);
    final db = await openDatabase(dbPath);
    _db = db;

    await db.execute(createUserTable);

    await db.execute(createNotesTable);

    await _cacheNotes();

    } on MissingPlatformDirectoryException{
     throw UnableToGetDocumentsDirectoryException();
    }
  }
}

@immutable
class DatabaseUser{
  final int id;
  final String email;
  const DatabaseUser({
    required this.id,
    required this.email,
});
  DatabaseUser.fromRow(Map<String,Object?>map): id = map[idColumn] as int, email = map[emailColumn] as String;

  @override
  toString() => "Person, ID = $id, email = $email";

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  // TODO: implement hashCode
  int get hashCode => id.hashCode;

}

class DatabaseNote{
  final int id;
  final int userId;
  final String text;

  DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
});

  DatabaseNote.fromRow(Map<String, Object?>map)
  : id = map[idColumn] as int,
    userId =  map[userIdColumn] as int,
    text = map[textColumn] as String;

  @override
  toString() => "Note, ID = $id, userId = $userId, text = $text";

  @override
  bool operator ==(covariant DatabaseNote other) => id == other.id;

  @override
  // TODO: implement hashCode
  int get hashCode => id.hashCode;
}
const dbName = 'notes.db';
const noteTable = 'note';
const userTable = 'user';
const idColumn = "id";
const emailColumn = "email";
const userIdColumn = "user_id";
const textColumn = "text";
const createUserTable = '''
    CREATE TABLE IF NOT EXISTS "user" (
	"id"	INTEGER NOT NULL,
	"email"	TEXT NOT NULL UNIQUE,
	PRIMARY KEY("id" AUTOINCREMENT)
);
    ''';
const createNotesTable = '''
    CREATE TABLE IF NOT EXISTS "notes" (
	"id"	INTEGER NOT NULL,
	"user_id"	INTEGER NOT NULL,
	"text"	TEXT NOT NULL,
	PRIMARY KEY("id" AUTOINCREMENT)
);
    ''';