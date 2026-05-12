import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _bg = Color(0xFFEAF7EF);
  static const Color _primary = Color(0xFF2ECC71);
  static const Color _primaryDark = Color(0xFF087D3D);
  static const Color _surface = Colors.white;
  static const Color _inputBg = Color(0xFFF4F4F4);
  static const Color _textDark = Color(0xFF202124);
  static const Color _textMuted = Color(0xFF9E9E9E);
  static const Color _error = Color(0xFFFF3B30);

  Future<Map<String, dynamic>> _loadProfile(String uid) async {
    final results = await Future.wait([
      FirebaseFirestore.instance.collection('users').doc(uid).get(),
      FirebaseFirestore.instance.collection('employees').doc(uid).get(),
    ]);

    return {
      'user': results[0].exists ? results[0].data() : null,
      'employee': results[1].exists ? results[1].data() : null,
    };
  }

  Stream<QuerySnapshot> _reviewStream(String employeeId) {
    return FirebaseFirestore.instance
        .collection('reviews')
        .where('employeeId', isEqualTo: employeeId)
        .snapshots();
  }

  double _calculateAvgRating(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) return 0;

    double total = 0;
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      total += double.tryParse((data['rating'] ?? 0).toString()) ?? 0;
    }

    return total / docs.length;
  }

  String _text(dynamic value, [String fallback = '']) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  String _dateText(dynamic value) {
    if (value == null) return '';

    if (value is Timestamp) {
      final date = value.toDate();
      return '${date.year.toString().padLeft(4, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.day.toString().padLeft(2, '0')}';
    }

    return value.toString();
  }

  DateTime? _parseDate(String text) {
    if (text.trim().isEmpty) return null;

    final normalized = text.trim().replaceAll('-', '/');
    final parts = normalized.split('/');

    if (parts.length != 3) return null;

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) return null;

    return DateTime(year, month, day);
  }

  String _initials(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return '?';

    final words = clean.split(RegExp(r'\s+'));
    if (words.length == 1) return words.first.substring(0, 1).toUpperCase();

    return '${words.first.substring(0, 1)}${words.last.substring(0, 1)}'
        .toUpperCase();
  }

  Future<void> _copyUserId(BuildContext context, String uid) async {
    await Clipboard.setData(ClipboardData(text: uid));

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã copy mã user')));
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await FirebaseAuth.instance.signOut();
    }
  }

  Future<void> _showEditSheet({
    required String uid,
    required Map<String, dynamic>? userData,
    required Map<String, dynamic>? employeeData,
  }) async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(
      text: _text(userData?['fullname'] ?? userData?['fullName']),
    );

    final phoneController = TextEditingController(
      text: _text(userData?['phone']),
    );

    final dobController = TextEditingController(
      text: _dateText(userData?['dateOfBirth'] ?? userData?['dob']),
    );

    final avatarController = TextEditingController(
      text: _text(
        userData?['avatarUrl'] ??
            userData?['photoUrl'] ??
            userData?['photoURL'] ??
            FirebaseAuth.instance.currentUser?.photoURL,
      ),
    );

    final areaController = TextEditingController(
      text: _text(employeeData?['area'], 'Huế'),
    );

    bool isAvailable = employeeData?['isAvailable'] != false;
    bool isSaving = false;
    bool didSaveAndClose = false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: _bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final avatarUrl = avatarController.text.trim();

            Future<void> saveProfile() async {
              if (!formKey.currentState!.validate()) return;

              setSheetState(() => isSaving = true);

              try {
                final fullname = nameController.text.trim();
                final phone = phoneController.text.trim();
                final dob = dobController.text.trim();
                final avatar = avatarController.text.trim();
                final area = areaController.text.trim();

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .set({
                      'fullname': fullname,
                      'fullName': fullname,
                      'phone': phone,
                      'dateOfBirth': dob,
                      'dob': dob,
                      'avatarUrl': avatar,
                      'photoUrl': avatar,
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                await FirebaseFirestore.instance
                    .collection('employees')
                    .doc(uid)
                    .set({
                      'userId': uid,
                      'fullname': fullname,
                      'phone': phone,
                      'area': area.isEmpty ? 'Chưa cập nhật' : area,
                      'avatarUrl': avatar,
                      'isAvailable': isAvailable,
                      'role': 'STAFF',
                      'updatedAt': FieldValue.serverTimestamp(),
                    }, SetOptions(merge: true));

                didSaveAndClose = true;

                if (sheetContext.mounted) {
                  Navigator.pop(sheetContext);
                }

                if (mounted) {
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã cập nhật thông tin')),
                  );
                }
              } catch (e) {
                if (sheetContext.mounted) {
                  ScaffoldMessenger.of(
                    sheetContext,
                  ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                }

                if (sheetContext.mounted) {
                  setSheetState(() => isSaving = false);
                }
              }
            }

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                14,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _EditAvatar(
                        avatarUrl: avatarUrl,
                        initials: _initials(nameController.text),
                        onTap: () {},
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Cập nhật ảnh đại diện',
                        style: TextStyle(
                          color: _primaryDark,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            _EditInput(
                              controller: nameController,
                              label: 'FULL NAME',
                              icon: Icons.person,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Nhập họ tên';
                                }
                                return null;
                              },
                              onChanged: (_) {
                                if (!didSaveAndClose) {
                                  setSheetState(() {});
                                }
                              },
                            ),
                            const SizedBox(height: 18),
                            _EditInput(
                              controller: phoneController,
                              label: 'PHONE',
                              icon: Icons.call,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 18),
                            _EditInput(
                              controller: dobController,
                              label: 'DATE OF BIRTH',
                              icon: Icons.calendar_month,
                              readOnly: true,
                              onTap: () async {
                                final initial =
                                    _parseDate(dobController.text) ??
                                    DateTime(2000, 1, 1);

                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: initial,
                                  firstDate: DateTime(1950),
                                  lastDate: DateTime.now(),
                                );

                                if (picked != null && sheetContext.mounted) {
                                  dobController.text =
                                      '${picked.year.toString().padLeft(4, '0')}/'
                                      '${picked.month.toString().padLeft(2, '0')}/'
                                      '${picked.day.toString().padLeft(2, '0')}';
                                }
                              },
                            ),
                            const SizedBox(height: 18),
                            _EditInput(
                              controller: avatarController,
                              label: 'AVATAR URL',
                              icon: Icons.link,
                              keyboardType: TextInputType.url,
                              onChanged: (_) {
                                if (!didSaveAndClose) {
                                  setSheetState(() {});
                                }
                              },
                            ),
                            const SizedBox(height: 18),
                            _EditInput(
                              controller: areaController,
                              label: 'KHU VỰC',
                              icon: Icons.location_city,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD9F2DF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.eco, color: _primaryDark),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                isAvailable
                                    ? 'Nhân viên EcoService\nĐang sẵn sàng nhận việc.'
                                    : 'Nhân viên EcoService\nHiện đang tạm nghỉ.',
                                style: const TextStyle(
                                  color: _textDark,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            Switch(
                              activeColor: _primary,
                              value: isAvailable,
                              onChanged: isSaving
                                  ? null
                                  : (value) {
                                      setSheetState(() {
                                        isAvailable = value;
                                      });
                                    },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 62,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: isSaving ? null : saveProfile,
                          icon: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save),
                          label: Text(
                            isSaving ? 'Đang lưu...' : 'Lưu',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // Không dispose controller ở đây.
    // Bottom sheet có thể còn rebuild TextFormField trong lúc đóng.
    // Dispose sớm sẽ gây lỗi: TextEditingController was used after being disposed.
  }

  @override
  Widget build(BuildContext context) {
    final authUser = FirebaseAuth.instance.currentUser;

    if (authUser == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: Text('Chưa đăng nhập')),
      );
    }

    final uid = authUser.uid;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _bg,
        foregroundColor: _primaryDark,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: _primaryDark,
            fontSize: 26,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadProfile(uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final userData = snapshot.data?['user'] as Map<String, dynamic>?;
          final employeeData =
              snapshot.data?['employee'] as Map<String, dynamic>?;

          final fullname = _text(
            userData?['fullname'] ??
                userData?['fullName'] ??
                authUser.displayName,
            'Nhân viên',
          );

          final email = _text(
            userData?['email'] ?? authUser.email,
            'Chưa có email',
          );

          final phone = _text(userData?['phone'], 'Chưa có SĐT');

          final dob = _text(
            _dateText(userData?['dateOfBirth'] ?? userData?['dob']),
            'Chưa cập nhật',
          );

          final avatarUrl = _text(
            userData?['avatarUrl'] ??
                userData?['photoUrl'] ??
                userData?['photoURL'] ??
                employeeData?['avatarUrl'] ??
                authUser.photoURL,
          );

          final area = _text(employeeData?['area'], 'Chưa cập nhật');
          final role = _text(userData?['role'], 'STAFF').toUpperCase();
          final isAvailable = employeeData?['isAvailable'] != false;
          final status = userData?['status'] != false;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 22, 24, 120),
            child: Column(
              children: [
                _ViewAvatar(
                  avatarUrl: avatarUrl,
                  initials: _initials(fullname),
                  onEdit: () => _showEditSheet(
                    uid: uid,
                    userData: userData,
                    employeeData: employeeData,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  fullname,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _textMuted, fontSize: 16),
                ),
                const SizedBox(height: 28),
                _InfoPanel(
                  children: [
                    _ProfileInfoRow(
                      icon: Icons.badge,
                      label: 'User ID',
                      value: uid,
                      trailing: IconButton(
                        onPressed: () => _copyUserId(context, uid),
                        icon: const Icon(Icons.copy, color: _primaryDark),
                      ),
                    ),
                    _ProfileInfoRow(
                      icon: Icons.person,
                      label: 'Full Name',
                      value: fullname,
                    ),
                    _ProfileInfoRow(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: phone,
                    ),
                    _ProfileInfoRow(
                      icon: Icons.calendar_month,
                      label: 'Date of Birth',
                      value: dob,
                    ),
                    _ProfileInfoRow(
                      icon: Icons.location_city,
                      label: 'Khu vực',
                      value: area,
                    ),
                    _ProfileInfoRow(
                      icon: status ? Icons.check_circle : Icons.lock,
                      label: 'Trạng thái tài khoản',
                      value: status ? 'Đang hoạt động' : 'Đã khóa',
                      valueColor: status ? _primaryDark : _error,
                    ),
                    _ProfileInfoRow(
                      icon: isAvailable ? Icons.task_alt : Icons.pause_circle,
                      label: 'Sẵn sàng nhận việc',
                      value: isAvailable ? 'Có' : 'Không',
                      valueColor: isAvailable ? _primaryDark : _textMuted,
                    ),
                    _ProfileInfoRow(
                      icon: Icons.admin_panel_settings,
                      label: 'Vai trò',
                      value: role,
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: _reviewStream(uid),
                      builder: (context, reviewSnapshot) {
                        final docs = reviewSnapshot.data?.docs ?? [];
                        final avg = _calculateAvgRating(docs);

                        return _ProfileInfoRow(
                          icon: Icons.star,
                          label: 'Đánh giá',
                          value: docs.isEmpty
                              ? 'Chưa có đánh giá'
                              : '${avg.toStringAsFixed(1)} / 5 (${docs.length})',
                          valueColor: Colors.orange,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 62,
                  child: ElevatedButton.icon(
                    onPressed: () => _showEditSheet(
                      uid: uid,
                      userData: userData,
                      employeeData: employeeData,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: _primary.withOpacity(0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(Icons.edit),
                    label: const Text(
                      'Sửa thông tin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 62,
                  child: OutlinedButton.icon(
                    onPressed: () => _copyUserId(context, uid),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _primaryDark,
                      side: const BorderSide(color: _primaryDark, width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(Icons.copy),
                    label: const Text(
                      'Copy mã user',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 62,
                  child: OutlinedButton.icon(
                    onPressed: () => _logout(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _error,
                      side: const BorderSide(color: _error, width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text(
                      'Đăng xuất',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ViewAvatar extends StatelessWidget {
  final String avatarUrl;
  final String initials;
  final VoidCallback onEdit;

  const _ViewAvatar({
    required this.avatarUrl,
    required this.initials,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        children: [
          Container(
            width: 144,
            height: 144,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _ProfileScreenState._primary.withOpacity(0.16),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: avatarUrl.isEmpty
                  ? _AvatarFallback(initials: initials)
                  : Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _AvatarFallback(initials: initials),
                    ),
            ),
          ),
          Positioned(
            right: 4,
            bottom: 12,
            child: InkWell(
              onTap: onEdit,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: _ProfileScreenState._primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditAvatar extends StatelessWidget {
  final String avatarUrl;
  final String initials;
  final VoidCallback onTap;

  const _EditAvatar({
    required this.avatarUrl,
    required this.initials,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipOval(
          child: SizedBox(
            width: 136,
            height: 136,
            child: avatarUrl.isEmpty
                ? _AvatarFallback(initials: initials, fontSize: 36)
                : Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        _AvatarFallback(initials: initials, fontSize: 36),
                  ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 4,
          child: Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              color: _ProfileScreenState._primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit, color: Colors.white),
          ),
        ),
      ],
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String initials;
  final double fontSize;

  const _AvatarFallback({required this.initials, this.fontSize = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _ProfileScreenState._primary.withOpacity(0.15),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: _ProfileScreenState._primaryDark,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _InfoPanel extends StatelessWidget {
  final List<Widget> children;

  const _InfoPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: BoxDecoration(
        color: _ProfileScreenState._surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(children: children),
    );
  }
}

class _ProfileInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  const _ProfileInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.28)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _ProfileScreenState._primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _ProfileScreenState._primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _ProfileScreenState._textMuted,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor ?? _ProfileScreenState._textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _EditInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const _EditInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _ProfileScreenState._textMuted,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          onTap: onTap,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.black54),
            filled: true,
            fillColor: _ProfileScreenState._inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: _ProfileScreenState._error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: _ProfileScreenState._error),
            ),
          ),
        ),
      ],
    );
  }
}
