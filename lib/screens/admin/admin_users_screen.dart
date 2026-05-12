import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const Color _bg = Color(0xFFEEFDFD);
  static const Color _primary = Color(0xFF006D37);
  static const Color _primarySoft = Color(0xFF2ECC71);
  static const Color _surface = Color(0xFFFFFFFF);
  static const Color _surfaceContainer = Color(0xFFE3F0F1);
  static const Color _secondaryContainer = Color(0xFF94F4AD);
  static const Color _tertiaryFixed = Color(0xFFD9E6DE);
  static const Color _textDark = Color(0xFF121E1F);
  static const Color _textVariant = Color(0xFF3D4A3E);
  static const Color _error = Color(0xFFBA1A1A);

  final TextEditingController _searchController = TextEditingController();

  String searchText = '';
  String roleFilter = 'ALL';

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addUser({
    required String email,
    required String password,
    required String fullname,
    required String phone,
    required String role,
  }) async {
    FirebaseApp? secondaryApp;

    try {
      secondaryApp = await Firebase.initializeApp(
        name: 'adminCreateUserApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );

      final auth = FirebaseAuth.instanceFor(app: secondaryApp);

      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'fullname': fullname,
        'phone': phone,
        'role': role,
        'status': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (role == 'STAFF') {
        await _db.collection('employees').doc(uid).set({
          'userId': uid,
          'fullname': fullname,
          'area': 'Huế',
          'isAvailable': true,
          'rating': 0,
          'role': 'STAFF',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      await auth.signOut();
    } finally {
      await secondaryApp?.delete();
    }
  }

  Future<void> _showAddUserDialog() async {
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final passwordController = TextEditingController();

    String selectedRole = 'CUSTOMER';
    bool isLoading = false;
    bool obscurePassword = true;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Text(
                'Thêm người dùng mới',
                style: TextStyle(color: _primary, fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 430,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _DialogInput(
                          controller: nameController,
                          label: 'Họ tên',
                          icon: Icons.person,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Nhập họ tên';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _DialogInput(
                          controller: emailController,
                          label: 'Email',
                          icon: Icons.mail,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            final email = value?.trim() ?? '';
                            if (email.isEmpty) return 'Nhập email';
                            if (!email.contains('@')) {
                              return 'Email không hợp lệ';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        _DialogInput(
                          controller: phoneController,
                          label: 'Số điện thoại',
                          icon: Icons.call,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Mật khẩu',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setDialogState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          validator: (value) {
                            final password = value ?? '';
                            if (password.isEmpty) return 'Nhập mật khẩu';
                            if (password.length < 6) {
                              return 'Mật khẩu tối thiểu 6 ký tự';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          decoration: InputDecoration(
                            labelText: 'Vai trò',
                            prefixIcon: const Icon(Icons.admin_panel_settings),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'CUSTOMER',
                              child: Text('Khách hàng'),
                            ),
                            DropdownMenuItem(
                              value: 'STAFF',
                              child: Text('Nhân viên'),
                            ),
                            DropdownMenuItem(
                              value: 'ADMIN',
                              child: Text('Quản trị viên'),
                            ),
                          ],
                          onChanged: (value) {
                            selectedRole = value ?? 'CUSTOMER';
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Hủy'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          setDialogState(() => isLoading = true);

                          try {
                            await _addUser(
                              email: emailController.text.trim(),
                              password: passwordController.text.trim(),
                              fullname: nameController.text.trim(),
                              phone: phoneController.text.trim(),
                              role: selectedRole,
                            );

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đã thêm người dùng mới'),
                                ),
                              );
                            }
                          } on FirebaseAuthException catch (e) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text(_authError(e.code))),
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(content: Text('Lỗi: $e')),
                              );
                            }
                          } finally {
                            if (dialogContext.mounted) {
                              setDialogState(() => isLoading = false);
                            }
                          }
                        },
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.person_add),
                  label: Text(isLoading ? 'Đang thêm...' : 'Thêm'),
                ),
              ],
            );
          },
        );
      },
    );

    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
  }

  Future<void> _updateUserRole({
    required String uid,
    required String role,
    required Map<String, dynamic> userData,
  }) async {
    final batch = _db.batch();

    final userRef = _db.collection('users').doc(uid);
    final employeeRef = _db.collection('employees').doc(uid);

    batch.update(userRef, {
      'role': role,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (role == 'STAFF') {
      batch.set(employeeRef, {
        'userId': uid,
        'fullname': userData['fullname'] ?? '',
        'area': userData['area'] ?? 'Huế',
        'isAvailable': true,
        'rating': userData['rating'] ?? 0,
        'role': 'STAFF',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      batch.delete(employeeRef);
    }

    await batch.commit();
  }

  Future<void> _toggleStatus(String uid, bool currentStatus) async {
    await _db.collection('users').doc(uid).update({
      'status': !currentStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteUserDoc(BuildContext context, String uid) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa tài khoản?'),
        content: const Text(
          'Thao tác này chỉ xóa dữ liệu user trong Firestore và employee tương ứng. Muốn xóa hoàn toàn Firebase Authentication account nên dùng Firebase Admin SDK hoặc Cloud Function.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final batch = _db.batch();
    batch.delete(_db.collection('users').doc(uid));
    batch.delete(_db.collection('employees').doc(uid));
    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa user trong Firestore')),
      );
    }
  }

  bool _matchUser(Map<String, dynamic> data, String docId) {
    final role = (data['role'] ?? 'CUSTOMER').toString().toUpperCase();

    if (roleFilter != 'ALL' && role != roleFilter) return false;

    final keyword = searchText.trim().toLowerCase();
    if (keyword.isEmpty) return true;

    final text = [
      docId,
      data['fullname'],
      data['email'],
      data['phone'],
      data['role'],
      data['address'],
    ].whereType<Object>().join(' ').toLowerCase();

    return text.contains(keyword);
  }

  static String _authError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email này đã tồn tại';
      case 'invalid-email':
        return 'Email không hợp lệ';
      case 'weak-password':
        return 'Mật khẩu quá yếu';
      case 'operation-not-allowed':
        return 'Firebase chưa bật đăng ký bằng Email/Password';
      default:
        return 'Không thể tạo tài khoản: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            sliver: SliverToBoxAdapter(
              child: _Header(
                searchController: _searchController,
                searchText: searchText,
                roleFilter: roleFilter,
                onSearchChanged: (value) {
                  setState(() => searchText = value);
                },
                onClearSearch: () {
                  _searchController.clear();
                  setState(() => searchText = '');
                },
                onRoleChanged: (value) {
                  setState(() => roleFilter = value ?? 'ALL');
                },
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(child: Text('Lỗi tải user: ${snapshot.error}')),
                );
              }

              if (!snapshot.hasData) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final docs = snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _matchUser(data, doc.id);
              }).toList();

              if (docs.isEmpty) {
                return SliverFillRemaining(
                  child: _EmptyUsers(onAdd: _showAddUserDialog),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent;
                    final crossAxisCount = width >= 1000
                        ? 3
                        : width >= 650
                        ? 2
                        : 1;

                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 245,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        childCount: docs.length + 1,
                        (context, index) {
                          if (index == docs.length) {
                            return _AddUserCard(onTap: _showAddUserDialog);
                          }

                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final uid = doc.id;

                          return _UserCard(
                            uid: uid,
                            data: data,
                            onAction: (action) async {
                              final isActive = data['status'] != false;

                              if (action == 'LOCK') {
                                await _toggleStatus(uid, isActive);
                              } else if (action == 'DELETE') {
                                await _deleteUserDoc(context, uid);
                              } else {
                                await _updateUserRole(
                                  uid: uid,
                                  role: action,
                                  userData: data,
                                );
                              }
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final TextEditingController searchController;
  final String searchText;
  final String roleFilter;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClearSearch;
  final ValueChanged<String?> onRoleChanged;

  const _Header({
    required this.searchController,
    required this.searchText,
    required this.roleFilter,
    required this.onSearchChanged,
    required this.onClearSearch,
    required this.onRoleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quản lý người dùng',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _AdminUsersScreenState._primary,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tìm kiếm, phân quyền, khóa hoặc thêm người dùng mới.',
          style: TextStyle(color: _AdminUsersScreenState._textVariant),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 760;

            final search = TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên, email hoặc số điện thoại...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchText.isEmpty
                    ? null
                    : IconButton(
                        onPressed: onClearSearch,
                        icon: const Icon(Icons.clear),
                      ),
                filled: true,
                fillColor: _AdminUsersScreenState._surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _AdminUsersScreenState._textVariant.withOpacity(0.2),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _AdminUsersScreenState._textVariant.withOpacity(0.2),
                  ),
                ),
              ),
            );

            final filter = DropdownButtonFormField<String>(
              value: roleFilter,
              decoration: InputDecoration(
                filled: true,
                fillColor: _AdminUsersScreenState._surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _AdminUsersScreenState._textVariant.withOpacity(0.2),
                  ),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('Tất cả vai trò')),
                DropdownMenuItem(value: 'CUSTOMER', child: Text('Khách hàng')),
                DropdownMenuItem(value: 'STAFF', child: Text('Nhân viên')),
                DropdownMenuItem(value: 'ADMIN', child: Text('Quản trị viên')),
              ],
              onChanged: onRoleChanged,
            );

            if (!isWide) {
              return Column(
                children: [search, const SizedBox(height: 12), filter],
              );
            }

            return Row(
              children: [
                Expanded(flex: 8, child: search),
                const SizedBox(width: 16),
                Expanded(flex: 4, child: filter),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;
  final ValueChanged<String> onAction;

  const _UserCard({
    required this.uid,
    required this.data,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final role = (data['role'] ?? 'CUSTOMER').toString().toUpperCase();
    final isActive = data['status'] != false;

    final name = data['fullname']?.toString() ?? 'Không tên';
    final email = data['email']?.toString() ?? '';
    final phone = data['phone']?.toString() ?? '';

    final initials = _initials(name);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: _AdminUsersScreenState._surface,
        borderRadius: BorderRadius.circular(18),
        border: isActive
            ? null
            : const Border(
                left: BorderSide(
                  color: _AdminUsersScreenState._error,
                  width: 4,
                ),
              ),
        boxShadow: [
          BoxShadow(
            color: _AdminUsersScreenState._primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: _avatarColor(role, isActive),
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: role == 'CUSTOMER' && isActive
                            ? const Color(0xFF005027)
                            : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _RoleChip(role: role),
                      const SizedBox(height: 7),
                      _StatusText(isActive: isActive),
                    ],
                  ),
                  const SizedBox(width: 32),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _AdminUsersScreenState._textDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              if (email.isNotEmpty)
                _InfoLine(
                  icon: Icons.mail_outline,
                  text: email,
                  muted: !isActive,
                ),
              if (phone.isNotEmpty) ...[
                const SizedBox(height: 6),
                _InfoLine(icon: Icons.call_outlined, text: phone),
              ],
              const Spacer(),
              Text(
                'UID: $uid',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _AdminUsersScreenState._textVariant.withOpacity(0.65),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          Positioned(
            top: 0,
            right: 0,
            child: PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert,
                color: _AdminUsersScreenState._textVariant,
              ),
              onSelected: onAction,
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'CUSTOMER',
                  child: _MenuItem(
                    icon: Icons.person,
                    text: 'Đổi thành CUSTOMER',
                  ),
                ),
                const PopupMenuItem(
                  value: 'STAFF',
                  child: _MenuItem(icon: Icons.badge, text: 'Đổi thành STAFF'),
                ),
                const PopupMenuItem(
                  value: 'ADMIN',
                  child: _MenuItem(
                    icon: Icons.admin_panel_settings,
                    text: 'Đổi thành ADMIN',
                  ),
                ),
                PopupMenuItem(
                  value: 'LOCK',
                  child: _MenuItem(
                    icon: isActive ? Icons.lock : Icons.lock_open,
                    text: isActive ? 'Khóa tài khoản' : 'Mở khóa tài khoản',
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'DELETE',
                  child: _MenuItem(
                    icon: Icons.delete,
                    text: 'Xóa người dùng',
                    color: _AdminUsersScreenState._error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.isEmpty || words.first.isEmpty) return '?';

    if (words.length == 1) {
      return words.first.characters.first.toUpperCase();
    }

    return '${words.first.characters.first}${words.last.characters.first}'
        .toUpperCase();
  }

  static Color _avatarColor(String role, bool isActive) {
    if (!isActive) return Colors.grey;
    if (role == 'ADMIN') return _AdminUsersScreenState._primary;
    if (role == 'STAFF') return const Color(0xFF96F7B0);
    return _AdminUsersScreenState._primarySoft;
  }
}

class _AddUserCard extends StatelessWidget {
  final VoidCallback onTap;

  const _AddUserCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: _AdminUsersScreenState._primary.withOpacity(0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _AdminUsersScreenState._textVariant.withOpacity(0.25),
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: _AdminUsersScreenState._surfaceContainer,
                child: Icon(
                  Icons.person_add,
                  color: _AdminUsersScreenState._primary,
                  size: 30,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Thêm người dùng mới',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _AdminUsersScreenState._textVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyUsers extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyUsers({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(child: _AddUserCard(onTap: onAdd));
  }
}

class _RoleChip extends StatelessWidget {
  final String role;

  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (role) {
      case 'ADMIN':
        bg = _AdminUsersScreenState._secondaryContainer;
        fg = const Color(0xFF00723A);
        break;
      case 'STAFF':
        bg = _AdminUsersScreenState._tertiaryFixed;
        fg = const Color(0xFF3E4944);
        break;
      default:
        bg = const Color(0xFFD9E6DE);
        fg = _AdminUsersScreenState._textVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatusText extends StatelessWidget {
  final bool isActive;

  const _StatusText({required this.isActive});

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? _AdminUsersScreenState._primary
        : _AdminUsersScreenState._error;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          isActive ? 'Đang hoạt động' : 'Đã khóa',
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool muted;

  const _InfoLine({required this.icon, required this.text, this.muted = false});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: muted ? 0.55 : 1,
      child: Row(
        children: [
          Icon(icon, size: 17, color: _AdminUsersScreenState._textVariant),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _AdminUsersScreenState._textVariant,
                decoration: muted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;

  const _MenuItem({required this.icon, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? _AdminUsersScreenState._primary;

    return Row(
      children: [
        Icon(icon, color: itemColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: TextStyle(color: color)),
        ),
      ],
    );
  }
}

class _DialogInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _DialogInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
