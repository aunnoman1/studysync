import 'package:flutter_test/flutter_test.dart';
import 'package:fyp/services/local_embedding/recursive_character_text_splitter.dart';

void main() {
  test('splitTextWithRegex matches LangChain for newline', () {
    final r = splitTextWithRegex(
      'a\nb',
      RegExp.escape(String.fromCharCode(10)),
      true,
    );
    expect(r, ['a', '\nb']);
  });

  test('RecursiveCharacterTextSplitter basic', () {
    final s = RecursiveCharacterTextSplitter(chunkSize: 10, chunkOverlap: 0);
    final chunks = s.splitText('abcdefghijklmnop');
    expect(chunks.isNotEmpty, true);
  });
}
