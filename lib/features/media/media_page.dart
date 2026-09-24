import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class MediaPage extends StatefulWidget {
  const MediaPage({super.key});
  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaItem {
  _MediaItem({required this.path, required this.isVideo});
  final String path;
  final bool isVideo;
}

class _MediaPageState extends State<MediaPage> {
  final List<_MediaItem> _items = [];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Media'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_outlined),
              onPressed: _pickMedia,
            )
          ],
        ),
        body: _items.isEmpty
            ? const Center(child: Text('Add images or videos to get started.'))
            : GridView.builder(
                padding: const EdgeInsets.all(8),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final item = _items[i];
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: item.isVideo
                            ? _VideoThumb(path: item.path)
                            : Image.file(
                                File(item.path),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                              ),
                      ),
                      if (item.isVideo)
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
        );

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final file = await picker.pickMedia();
    if (file == null) return;
    final isVideo = file.path.endsWith('.mp4') || file.path.endsWith('.mov') || file.path.endsWith('.webm');
    setState(() => _items.add(_MediaItem(path: file.path, isVideo: isVideo)));
  }
}

class _VideoThumb extends StatefulWidget {
  const _VideoThumb({required this.path});
  final String path;

  @override
  State<_VideoThumb> createState() => _VideoThumbState();
}

class _VideoThumbState extends State<_VideoThumb> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.path))
      ..initialize().then((_) => setState(() {}))
      ..setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _controller.value.isInitialized
      ? VideoPlayer(_controller)
      : const Center(child: CircularProgressIndicator());
}

