import 'package:shared_preferences/shared_preferences.dart';
import '../models/document_model.dart';

class DocumentRepository {
  DocumentRepository(this._prefs);

  final SharedPreferences _prefs;
  static const _historyKey = 'scanned_documents_history';

  /// Loads all saved documents from local storage, sorted newest first
  List<DocumentModel> loadAllDocuments() {
    final rawList = _prefs.getStringList(_historyKey) ?? [];
    try {
      final list = rawList.map((jsonStr) => DocumentModel.fromJson(jsonStr)).toList();
      // Sort: newest first
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Appends a new document to local storage history
  Future<bool> saveDocument(DocumentModel doc) async {
    final currentList = loadAllDocuments();
    currentList.insert(0, doc); // prepend
    return _saveList(currentList);
  }

  /// Deletes a document record from local storage history
  Future<bool> deleteDocument(String id) async {
    final currentList = loadAllDocuments();
    currentList.removeWhere((doc) => doc.id == id);
    return _saveList(currentList);
  }

  /// Clears all document records from local storage
  Future<bool> clearAll() async {
    return _prefs.remove(_historyKey);
  }

  Future<bool> _saveList(List<DocumentModel> list) async {
    final rawList = list.map((doc) => doc.toJson()).toList();
    return _prefs.setStringList(_historyKey, rawList);
  }
}
