import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/document_repository.dart';
import '../models/document_model.dart';

// --- Shared Preferences Provider ---
// Will be overridden in main.dart during app initialization
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

// --- Document Repository Provider ---
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return DocumentRepository(prefs);
});

// --- Document List StateNotifier ---
class DocumentListNotifier extends StateNotifier<List<DocumentModel>> {
  DocumentListNotifier(this._repository) : super([]) {
    loadDocuments();
  }

  final DocumentRepository _repository;

  /// Loads all documents from storage into state
  void loadDocuments() {
    state = _repository.loadAllDocuments();
  }

  /// Saves a newly scanned document and prepends it to state
  Future<void> addDocument(DocumentModel doc) async {
    final ok = await _repository.saveDocument(doc);
    if (ok) {
      state = [doc, ...state];
    }
  }

  /// Deletes a document from storage and state
  Future<void> removeDocument(String id) async {
    final ok = await _repository.deleteDocument(id);
    if (ok) {
      state = state.where((doc) => doc.id != id).toList();
    }
  }

  /// Renames an existing document
  Future<void> renameDocument(String id, String newName) async {
    final list = _repository.loadAllDocuments();
    final index = list.indexWhere((doc) => doc.id == id);
    if (index != -1) {
      list[index] = list[index].copyWith(name: newName);
      final ok = await _repository.clearAll().then((_) async {
        // Rewrite entire list
        bool success = true;
        for (final doc in list.reversed) {
          success = success && await _repository.saveDocument(doc);
        }
        return success;
      });
      if (ok) {
        state = list;
      }
    }
  }
}

final documentListProvider =
    StateNotifierProvider<DocumentListNotifier, List<DocumentModel>>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  return DocumentListNotifier(repository);
});
