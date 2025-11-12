import 'package:objectbox/objectbox.dart';
import 'models/captured_note.dart';
import 'objectbox.g.dart'; // generated

class ObjectBox {
  late final Store store;
  late final Box<CapturedNote> capturedNoteBox;

  ObjectBox._create(this.store) {
    capturedNoteBox = Box<CapturedNote>(store);
  }

  static Future<ObjectBox> create() async {
    final store = await openStore();
    return ObjectBox._create(store);
  }
}


