import 'package:flutter/material.dart';
import '../models/note_record.dart';
import '../theme.dart';

class NoteDebugPage extends StatelessWidget {
  final NoteRecord note;
  final List<NoteImage> images;
  final int currentIndex;
  final List<OcrBlock> Function(NoteImage image) fetchOcrBlocks;
  final List<TextChunk> Function(NoteRecord note) fetchTextChunks;

  const NoteDebugPage({
    super.key,
    required this.note,
    required this.images,
    required this.currentIndex,
    required this.fetchOcrBlocks,
    required this.fetchTextChunks,
  });

  @override
  Widget build(BuildContext context) {
    final List<OcrBlock> ocrBlocks = images.isEmpty
        ? const <OcrBlock>[]
        : fetchOcrBlocks(images[currentIndex]);
    final List<TextChunk> chunks = fetchTextChunks(note);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // OCR section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.lightInputFill,
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OCR (current page)',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Blocks: ${ocrBlocks.length}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    if (ocrBlocks.isEmpty)
                      const Text(
                        'No blocks.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      )
                    else
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (context, i) {
                          final b = ocrBlocks[i];
                          final text = b.text.trim();
                          return Text(
                            '#${i + 1} [order ${b.readingOrder}]: $text',
                            style: const TextStyle(color: AppTheme.textPrimary),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemCount: ocrBlocks.length,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Embeddings section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.lightInputFill,
                  border: Border.all(color: AppTheme.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Embeddings',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Chunks: ${chunks.length}',
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    if (chunks.isEmpty)
                      const Text(
                        'No chunks.',
                        style: TextStyle(color: AppTheme.textSecondary),
                      )
                    else
                      ListView.separated(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemBuilder: (context, i) {
                          final c = chunks[i];
                          final snippet = c.chunkText.length > 140
                              ? '${c.chunkText.substring(0, 140)}...'
                              : c.chunkText;
                          final dim = c.embedding.length;
                          return Text(
                            '#${i + 1} [${dim}d]: $snippet',
                            style: const TextStyle(color: AppTheme.textPrimary),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 4),
                        itemCount: chunks.length,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}






