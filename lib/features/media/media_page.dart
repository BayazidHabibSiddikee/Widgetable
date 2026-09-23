import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class MediaPage extends StatefulWidget {
  const MediaPage({super.key});
  @override
  State<MediaPage> createState() => _MediaPageState();
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
                  return FutureBuilder(
                    future: item.prepare(),
                    builder: (_, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (item.isVideo) {
                        final controller = item.controller;
                        if (controller == null) return const SizedBox.shrink();
                        return AspectRatio(
                          aspectRatio: controller.value.aspectRatio,
                          child: VideoPlayer(controller),
                        );
                      }
                      return CachedNetworkImage(
                        imageUrl: item.path,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                      );
                    },
                  );
                },
              ),
      );

  Future<void> _pickMedia() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => _items.add(_MediaItem(path: file.path, isVideo: false)));
  }
}

class _MediaItem {
  _MediaItem({required this.path, required this.isVideo});
  final String path;
  final bool isVideo;
  VideoPlayerController? controller;

  Future<void> prepare() async {
    if (!isVideo) return;
    controller ??= VideoPlayerController.file(File(path))..initialize();
    await controller?.initialized ?? Future.value();
  }
}
