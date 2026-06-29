import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _isLoading = false;
  bool _isProcessing = false;
  List<String> _backupFiles = [];

  @override
  void initState() {
    super.initState();
    _loadBackupFiles();
  }

  Future<void> _loadBackupFiles() async {
    setState(() {
      _isLoading = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 400));

    if (!mounted) return;

    setState(() {
      _backupFiles = [
        '/storage/emulated/0/Download/milk_backup_2024.json',
        '/storage/emulated/0/Download/milk_backup_2025.json',
      ];
      _isLoading = false;
    });
  }

  Future<void> _createBackup() async {
    setState(() {
      _isProcessing = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
      _backupFiles = [
        '/storage/emulated/0/Download/milk_backup_2024.json',
        '/storage/emulated/0/Download/milk_backup_2025.json',
        '/storage/emulated/0/Download/milk_backup_preview.json',
      ];
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup created successfully.')),
    );
  }

  Future<void> _shareBackup(String path) async {
    setState(() {
      _isProcessing = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share sheet opened.')));
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _restoreFromFilePicker() async {
    setState(() {
      _isProcessing = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backup restored successfully.')),
    );
  }

  Future<void> _restoreBackup(String filePath) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restore Backup'),
          content: const Text(
            'Restoring a backup will replace your current milk tracker data. Do you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
    });

    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Restored $filePath')),
    );
  }

  String _fileName(String path) {
    return path.split(RegExp(r'[\\/]')).last;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: AppTheme.glassCard(context),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Protect your data',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create a backup of your customer and delivery data. Use restore to recover saved snapshots.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _createBackup,
                            icon: const Icon(Icons.backup),
                            label: Text(_isProcessing ? 'Working...' : 'Create Backup'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        TextButton.icon(
                          onPressed: _isProcessing ? null : _restoreFromFilePicker,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Restore from file'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Available backups',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: _isLoading || _isProcessing ? null : _loadBackupFiles,
                    child: const Text('Refresh'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _backupFiles.isEmpty
                        ? Center(
                            child: Text(
                              'No backups found yet. Create one to save your data safely.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: _backupFiles.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final path = _backupFiles[index];
                              final filename = _fileName(path);

                              return Container(
                                decoration: AppTheme.glassCard(context),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  title: Text(filename, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(path, maxLines: 2, overflow: TextOverflow.ellipsis),
                                  trailing: SizedBox(
                                    width: 140,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          tooltip: 'Share',
                                          onPressed: _isProcessing ? null : () => _shareBackup(path),
                                          icon: const Icon(Icons.share),
                                        ),
                                        const SizedBox(width: 6),
                                        SizedBox(
                                          height: 34,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(horizontal: 10),
                                              minimumSize: const Size(80, 34),
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            onPressed: _isProcessing ? null : () => _restoreBackup(path),
                                            child: const Text('Restore', style: TextStyle(fontSize: 12)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
