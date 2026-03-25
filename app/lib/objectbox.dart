import 'package:objectbox/objectbox.dart';
import 'models/note_record.dart';
import 'objectbox.g.dart'; // generated

class ObjectBox {
  late final Store store;
  late final Box<NoteRecord> noteBox;
  late final Box<NoteImage> noteImageBox;
  late final Box<OcrBlock> ocrBlockBox;
  late final Box<TextChunk> textChunkBox;
  late final Box<NoteDiagram> noteDiagramBox;

  ObjectBox._create(this.store) {
    noteBox = Box<NoteRecord>(store);
    noteImageBox = Box<NoteImage>(store);
    ocrBlockBox = Box<OcrBlock>(store);
    textChunkBox = Box<TextChunk>(store);
    noteDiagramBox = Box<NoteDiagram>(store);
  }

  static Future<ObjectBox> create() async {
    final store = await openStore();
    return ObjectBox._create(store);
  }
}
