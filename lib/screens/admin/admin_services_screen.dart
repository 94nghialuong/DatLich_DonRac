import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AdminServicesScreen extends StatefulWidget {
  const AdminServicesScreen({super.key});

  @override
  State<AdminServicesScreen> createState() => _AdminServicesScreenState();
}

class _AdminServicesScreenState extends State<AdminServicesScreen> {
  static const Color _bg = Color(0xFFEAF7EF);
  static const Color _primary = Color(0xFF1E8449);
  static const Color _primaryDark = Color(0xFF006D37);
  static const Color _surface = Colors.white;
  static const Color _surfaceContainer = Color(0xFFE3F0F1);
  static const Color _textDark = Color(0xFF121E1F);

  final TextEditingController _searchController = TextEditingController();

  String searchText = '';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<String?> _pickAndUploadImage() async {
    final picker = ImagePicker();

    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (file == null) return null;

    final Uint8List bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();

    String contentType = 'image/jpeg';
    if (ext == 'png') contentType = 'image/png';
    if (ext == 'webp') contentType = 'image/webp';

    final ref = FirebaseStorage.instance
        .ref()
        .child('services')
        .child('${DateTime.now().millisecondsSinceEpoch}.$ext');

    await ref.putData(bytes, SettableMetadata(contentType: contentType));

    return ref.getDownloadURL();
  }

  Future<void> _showServiceDialog({
    String? serviceId,
    Map<String, dynamic>? data,
  }) async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(
      text: data?['name']?.toString() ?? '',
    );

    final descriptionController = TextEditingController(
      text: data?['description']?.toString() ?? '',
    );

    final priceController = TextEditingController(
      text: (data?['price'] ?? '').toString(),
    );

    final urlController = TextEditingController(
      text: (data?['URL'] ?? data?['imageUrl'] ?? data?['url'] ?? '')
          .toString(),
    );

    bool isUploading = false;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final imageUrl = urlController.text.trim();

            return AlertDialog(
              backgroundColor: _bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                serviceId == null ? 'Thêm dịch vụ' : 'Sửa dịch vụ',
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SizedBox(
                width: 430,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DialogInput(
                          controller: nameController,
                          label: 'Tên dịch vụ',
                          icon: Icons.cleaning_services,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nhập tên dịch vụ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _DialogInput(
                          controller: descriptionController,
                          label: 'Mô tả',
                          icon: Icons.description,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 12),
                        _DialogInput(
                          controller: priceController,
                          label: 'Giá',
                          icon: Icons.payments,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            final text = value?.trim() ?? '';

                            if (text.isEmpty) return 'Nhập giá';
                            if (double.tryParse(text) == null) {
                              return 'Giá không hợp lệ';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: urlController,
                          decoration: InputDecoration(
                            labelText: 'URL ảnh',
                            prefixIcon: const Icon(Icons.link),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                        const SizedBox(height: 14),
                        if (imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: SizedBox(
                              height: 140,
                              width: double.infinity,
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) {
                                  return Container(
                                    color: _surfaceContainer,
                                    alignment: Alignment.center,
                                    child: const Text('Không tải được ảnh'),
                                  );
                                },
                              ),
                            ),
                          ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: isUploading
                                ? null
                                : () async {
                                    setDialogState(() {
                                      isUploading = true;
                                    });

                                    try {
                                      final url = await _pickAndUploadImage();

                                      if (url != null) {
                                        urlController.text = url;
                                      }
                                    } finally {
                                      if (dialogContext.mounted) {
                                        setDialogState(() {
                                          isUploading = false;
                                        });
                                      }
                                    }
                                  },
                            icon: isUploading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload),
                            label: Text(
                              isUploading ? 'Đang upload...' : 'Upload ảnh',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          final imageUrl = urlController.text.trim();

                          final payload = {
                            'name': nameController.text.trim(),
                            'description': descriptionController.text.trim(),
                            'price':
                                double.tryParse(priceController.text.trim()) ??
                                0,
                            'URL': imageUrl,
                            'imageUrl': imageUrl,
                            'updatedAt': FieldValue.serverTimestamp(),
                          };

                          final services = _db.collection('services');

                          if (serviceId == null) {
                            await services.add({
                              ...payload,
                              'createdAt': FieldValue.serverTimestamp(),
                            });
                          } else {
                            await services.doc(serviceId).update(payload);
                          }

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    urlController.dispose();
  }

  Future<void> _deleteService(String serviceId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa dịch vụ?'),
          content: const Text('Bạn chắc chắn muốn xóa dịch vụ này?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      await _db.collection('services').doc(serviceId).delete();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Đã xóa dịch vụ')));
      }
    }
  }

  bool _matchSearch(Map<String, dynamic> data, String docId) {
    final keyword = searchText.trim().toLowerCase();

    if (keyword.isEmpty) return true;

    final text = [
      docId,
      data['name'],
      data['description'],
      data['price'],
    ].whereType<Object>().join(' ').toLowerCase();

    return text.contains(keyword);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: Column(
        children: [
          _Header(
            controller: _searchController,
            searchText: searchText,
            onSearchChanged: (value) {
              setState(() {
                searchText = value;
              });
            },
            onClearSearch: () {
              _searchController.clear();
              setState(() {
                searchText = '';
              });
            },
            onAdd: () => _showServiceDialog(),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _db.collection('services').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Lỗi tải dịch vụ: ${snapshot.error}'),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _matchSearch(data, doc.id);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text('Không tìm thấy dịch vụ'));
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;

                    final crossAxisCount = width >= 1100
                        ? 4
                        : width >= 760
                        ? 3
                        : width >= 520
                        ? 2
                        : 1;

                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        mainAxisExtent: 335,
                      ),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;

                        return _ServiceCard(
                          id: doc.id,
                          data: data,
                          onEdit: () =>
                              _showServiceDialog(serviceId: doc.id, data: data),
                          onDelete: () => _deleteService(doc.id),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final TextEditingController controller;
  final String searchText;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final VoidCallback onAdd;

  const _Header({
    required this.controller,
    required this.searchText,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 650;

          final search = TextField(
            controller: controller,
            onChanged: onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Tìm dịch vụ...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchText.isEmpty
                  ? null
                  : IconButton(
                      onPressed: onClearSearch,
                      icon: const Icon(Icons.clear),
                    ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.black.withOpacity(0.12)),
              ),
            ),
          );

          final addButton = SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: _AdminServicesScreenState._primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Thêm'),
            ),
          );

          if (isWide) {
            return Row(
              children: [
                Expanded(child: search),
                const SizedBox(width: 10),
                addButton,
              ],
            );
          }

          return Column(
            children: [
              search,
              const SizedBox(height: 10),
              SizedBox(width: double.infinity, child: addButton),
            ],
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ServiceCard({
    required this.id,
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = (data['URL'] ?? data['imageUrl'] ?? data['url'] ?? '')
        .toString();

    final name = data['name']?.toString() ?? 'Không tên';
    final description = data['description']?.toString() ?? '';
    final price = data['price'] ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: _AdminServicesScreenState._surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _AdminServicesScreenState._primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: 150,
            width: double.infinity,
            child: imageUrl.isEmpty
                ? const _ImagePlaceholder(icon: Icons.image_not_supported)
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) {
                      return const _ImagePlaceholder(icon: Icons.broken_image);
                    },
                  ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _AdminServicesScreenState._textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    description.isEmpty ? 'Không có mô tả' : description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const Spacer(),
                  Text(
                    '${double.tryParse(price.toString())?.toStringAsFixed(0) ?? price}đ',
                    style: const TextStyle(
                      color: _AdminServicesScreenState._primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Sửa',
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit),
                      ),
                      IconButton(
                        tooltip: 'Xóa',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final IconData icon;

  const _ImagePlaceholder({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _AdminServicesScreenState._surfaceContainer,
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.black38, size: 42),
    );
  }
}

class _DialogInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  const _DialogInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
