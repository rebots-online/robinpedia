import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../zim_downloader.dart';
import '../themes/theme_data.dart';
import '../themes/theme_provider.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  final ZimDownloader _downloader = ZimDownloader();
  List<ZimFile> _zimFiles = [];
  final Map<String, double> _downloadProgress = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadZimFiles();
  }

  Future<void> _loadZimFiles() async {
    try {
      debugPrint('Starting to load ZIM files...');
      final files = await _downloader.listAvailableZimFiles();
      debugPrint('Loaded ${files.length} ZIM files');
      setState(() {
        _zimFiles = files;
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading ZIM files: $e');
      debugPrint('Stack trace: $stackTrace');
      // Show error to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading ZIM files: $e')),
        );
      }
    }
  }

  void _startDownload(ZimFile file) async {
    setState(() {
      _downloadProgress[file.filename] = 0;
    });

    await _downloader.downloadZimFile(
      file,
      onProgress: (progress) {
        setState(() {
          _downloadProgress[file.filename] = progress;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayedFiles = _searchQuery.isEmpty
        ? _zimFiles
        : _downloader.searchZimFiles(_searchQuery);

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isRetroTheme = themeProvider.currentStyle == ThemeStyle.retroTerminal;

    return Scaffold(
      backgroundColor: isRetroTheme ? Colors.black : null,
      appBar: AppBar(
        backgroundColor: isRetroTheme ? Colors.black : null,
        title: ThemedText(
          isRetroTheme ? 'ROBINPEDIA TERMINAL v1.0' : 'Available ZIM Files',
          isTitle: true,
          animate: isRetroTheme,
        ),
        actions: [
          PopupMenuButton<ThemeStyle>(
            icon: Icon(
              Icons.palette,
              color: isRetroTheme ? const Color(0xFF33FF33) : null,
            ),
            onSelected: (ThemeStyle style) {
              context.read<ThemeProvider>().setTheme(style);
            },
            itemBuilder: (BuildContext context) {
              return ThemeStyle.values.map((ThemeStyle style) {
                return PopupMenuItem<ThemeStyle>(
                  value: style,
                  child: Text(ThemeManager.themes[style]!.name),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: ThemedContainer(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ThemedContainer(
                isCard: true,
                child: TextField(
                  style: isRetroTheme
                      ? const TextStyle(
                          color: Color(0xFF33FF33),
                          fontFamily: 'RobotoMono',
                        )
                      : null,
                  decoration: InputDecoration(
                    labelText: isRetroTheme ? 'SEARCH DATABASE' : 'Search ZIM files',
                    labelStyle: isRetroTheme
                        ? const TextStyle(
                            color: Color(0xFF33FF33),
                            fontFamily: 'RobotoMono',
                          )
                        : null,
                    prefixIcon: Icon(
                      Icons.search,
                      color: isRetroTheme ? const Color(0xFF33FF33) : null,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: displayedFiles.length,
                itemBuilder: (context, index) {
                  final file = displayedFiles[index];
                  final progress = _downloadProgress[file.filename];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    child: ThemedContainer(
                      isCard: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ThemedText(
                                  isRetroTheme
                                      ? '> ${file.title.toUpperCase()}'
                                      : file.title,
                                  isTitle: true,
                                  animate: isRetroTheme,
                                ),
                              ),
                              if (progress == null)
                                ThemedContainer(
                                  isButton: true,
                                  onTap: () => _startDownload(file),
                                  child: Icon(
                                    Icons.download,
                                    color: isRetroTheme ? const Color(0xFF33FF33) : null,
                                  ),
                                )
                              else
                                ThemedText(
                                  isRetroTheme
                                      ? '[DOWNLOADING: ${(progress * 100).toStringAsFixed(1)}%]'
                                      : '${(progress * 100).toStringAsFixed(1)}%',
                                  animate: isRetroTheme,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ThemedText(
                            isRetroTheme
                                ? '> ${file.description.toUpperCase()}'
                                : file.description,
                            animate: isRetroTheme,
                          ),
                          ThemedText(
                            isRetroTheme
                                ? 'SIZE: ${(file.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB | STATUS: READY'
                                : 'Size: ${(file.sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB',
                            animate: isRetroTheme,
                          ),
                          if (progress != null) ...[
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: isRetroTheme
                                  ? const Color(0xFF001100)
                                  : null,
                              valueColor: isRetroTheme
                                  ? const AlwaysStoppedAnimation<Color>(Color(0xFF33FF33))
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
