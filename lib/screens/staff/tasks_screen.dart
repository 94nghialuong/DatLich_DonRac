import 'package:booking_don_rac/screens/staff/task_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../models/task_model.dart';
import '../../provider/employee_provider.dart';
import '../../services/common_service.dart';

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  static const Color _bg = Color(0xFFEEFDFD);
  static const Color _primary = Color(0xFF006D37);
  static const Color _primarySoft = Color(0xFF2ECC71);
  static const Color _surface = Colors.white;
  static const Color _outline = Color(0xFF6C7B6D);
  static const Color _textDark = Color(0xFF121E1F);
  static const Color _textVariant = Color(0xFF3D4A3E);

  final CommonService service = CommonService();
  final TextEditingController _searchController = TextEditingController();

  String searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalize(String value) {
    return value.toLowerCase().trim().replaceAll('đ', 'd');
  }

  bool _matchSearch({
    required String serviceName,
    required String address,
    required String receiver,
    required String phone,
  }) {
    final keyword = _normalize(searchText);

    if (keyword.isEmpty) return true;

    return _normalize(serviceName).contains(keyword) ||
        _normalize(address).contains(keyword) ||
        _normalize(receiver).contains(keyword) ||
        _normalize(phone).contains(keyword);
  }

  Future<void> _updateTaskStatus(TaskModel task, String status) async {
    await FirebaseFirestore.instance.collection('tasks').doc(task.id).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật trạng thái: $status')),
      );
    }
  }

  List<TaskModel> _filterTasksByStatus(
    List<TaskModel> tasks,
    List<String> statuses,
  ) {
    return tasks.where((task) {
      return statuses.contains(task.status.toUpperCase());
    }).toList();
  }

  Widget _buildTaskGrid(List<TaskModel> tasks) {
    if (tasks.isEmpty) {
      return const Center(child: Text('Không có task nào'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width >= 1000
            ? 3
            : width >= 650
            ? 2
            : 1;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _TaskSummaryCard(total: tasks.length),
            ),

            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                itemCount: tasks.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  mainAxisExtent: 310,
                ),
                itemBuilder: (context, index) {
                  final task = tasks[index];

                  return _TaskLoaderCard(
                    task: task,
                    service: service,
                    matchSearch: _matchSearch,
                    onOpen: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TaskDetail(task: task),
                        ),
                      );
                    },
                    onUpdateStatus: (status) {
                      _updateTaskStatus(task, status);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: _surface,
          foregroundColor: _primary,
          titleSpacing: 20,
          title: const Row(
            children: [
              Icon(Icons.eco, color: _primary),
              SizedBox(width: 8),
              Text(
                'EcoStaff',
                style: TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          bottom: const TabBar(
            labelColor: _primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: _primary,
            tabs: [
              Tab(text: 'Đã giao'),
              Tab(text: 'Đang làm'),
              Tab(text: 'Hoàn thành'),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: _SearchBox(
                controller: _searchController,
                searchText: searchText,
                onChanged: (value) {
                  setState(() => searchText = value);
                },
                onClear: () {
                  _searchController.clear();
                  setState(() => searchText = '');
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: provider.tasks,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text('Không có task nào'));
                  }

                  final tasks = snapshot.data!.docs.map((doc) {
                    return TaskModel.fromDoc(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    );
                  }).toList();

                  final assignedTasks = _filterTasksByStatus(tasks, [
                    'ASSIGNED',
                  ]);

                  final inProgressTasks = _filterTasksByStatus(tasks, [
                    'IN_PROGRESS',
                  ]);

                  final completedTasks = _filterTasksByStatus(tasks, [
                    'COMPLETED',
                    'DONE',
                  ]);

                  return TabBarView(
                    children: [
                      _buildTaskGrid(assignedTasks),
                      _buildTaskGrid(inProgressTasks),
                      _buildTaskGrid(completedTasks),
                    ],
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

class _SearchBox extends StatelessWidget {
  final TextEditingController controller;
  final String searchText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBox({
    required this.controller,
    required this.searchText,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Tìm theo dịch vụ, địa chỉ hoặc người nhận...',
        prefixIcon: const Icon(Icons.search, color: _TaskScreenState._outline),
        suffixIcon: searchText.isEmpty
            ? null
            : IconButton(onPressed: onClear, icon: const Icon(Icons.clear)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(
            color: _TaskScreenState._outline.withOpacity(0.3),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(
            color: _TaskScreenState._outline.withOpacity(0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: const BorderSide(
            color: _TaskScreenState._primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}

class _TaskSummaryCard extends StatelessWidget {
  final int total;

  const _TaskSummaryCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _TaskScreenState._primarySoft.withOpacity(0.16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _TaskScreenState._primarySoft.withOpacity(0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _TaskScreenState._primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.task_alt,
              color: _TaskScreenState._primary,
              size: 23,
            ),
          ),

          const SizedBox(width: 12),

          const Expanded(
            child: Text(
              'Active Tasks',
              style: TextStyle(
                color: _TaskScreenState._primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$total Total',
              style: const TextStyle(
                color: _TaskScreenState._primary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskLoaderCard extends StatelessWidget {
  final TaskModel task;
  final CommonService service;
  final bool Function({
    required String serviceName,
    required String address,
    required String receiver,
    required String phone,
  })
  matchSearch;
  final VoidCallback onOpen;
  final ValueChanged<String> onUpdateStatus;

  const _TaskLoaderCard({
    required this.task,
    required this.service,
    required this.matchSearch,
    required this.onOpen,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('bookings')
          .doc(task.bookingId)
          .get(),
      builder: (context, bookingSnap) {
        if (!bookingSnap.hasData) {
          return const _LoadingTaskCard();
        }

        final bookingData = bookingSnap.data!.data();

        if (bookingData == null) {
          return const SizedBox.shrink();
        }

        final booking = BookingModel.fromDoc(
          bookingSnap.data!.id,
          bookingData as Map<String, dynamic>,
        );

        return FutureBuilder<List<Map<String, dynamic>?>>(
          future: Future.wait([
            service.getService(booking.serviceId),
            service.getAddress(booking.addressId),
          ]),
          builder: (context, dataSnap) {
            if (!dataSnap.hasData) {
              return const _LoadingTaskCard();
            }

            final serviceData = dataSnap.data![0];
            final addressData = dataSnap.data![1];

            final serviceName = serviceData?['name']?.toString() ?? 'Dịch vụ';
            final fullAddress =
                addressData?['fullAddress']?.toString() ?? 'Không có địa chỉ';
            final receiver =
                addressData?['receiverName']?.toString() ?? 'Không có tên';
            final phone = addressData?['phone']?.toString() ?? 'Không có SĐT';

            final visible = matchSearch(
              serviceName: serviceName,
              address: fullAddress,
              receiver: receiver,
              phone: phone,
            );

            if (!visible) return const SizedBox.shrink();

            return _TaskCard(
              task: task,
              serviceName: serviceName,
              fullAddress: fullAddress,
              receiver: receiver,
              phone: phone,
              onOpen: onOpen,
              onUpdateStatus: onUpdateStatus,
            );
          },
        );
      },
    );
  }
}

class _TaskCard extends StatelessWidget {
  final TaskModel task;
  final String serviceName;
  final String fullAddress;
  final String receiver;
  final String phone;
  final VoidCallback onOpen;
  final ValueChanged<String> onUpdateStatus;

  const _TaskCard({
    required this.task,
    required this.serviceName,
    required this.fullAddress,
    required this.receiver,
    required this.phone,
    required this.onOpen,
    required this.onUpdateStatus,
  });

  @override
  Widget build(BuildContext context) {
    final status = task.status.toUpperCase();
    final statusData = _statusData(status);
    final completed = status == 'COMPLETED' || status == 'DONE';

    return Opacity(
      opacity: completed ? 0.82 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _TaskScreenState._surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.green.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E8449).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onOpen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🧹', style: TextStyle(fontSize: 19)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      serviceName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: completed
                            ? _TaskScreenState._textVariant
                            : _TaskScreenState._textDark,
                        fontSize: 19,
                        height: 1.25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusChip(
                    text: statusData.text,
                    bg: statusData.bg,
                    fg: statusData.fg,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _InfoLine(
                icon: Icons.location_on,
                text: fullAddress,
                muted: completed,
              ),
              const SizedBox(height: 10),
              _InfoLine(icon: Icons.person, text: receiver, muted: completed),
              const SizedBox(height: 10),
              _InfoLine(
                icon: Icons.call,
                text: phone,
                color: completed
                    ? _TaskScreenState._primary.withOpacity(0.65)
                    : _TaskScreenState._primary,
                muted: completed,
              ),
              const Spacer(),
              Container(height: 1, color: Colors.green.withOpacity(0.08)),
              const SizedBox(height: 12),
              if (completed)
                const Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: _TaskScreenState._primary,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Verified Completion',
                        style: TextStyle(
                          color: _TaskScreenState._primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (status == 'ASSIGNED') {
                            onUpdateStatus('IN_PROGRESS');
                          } else if (status == 'IN_PROGRESS') {
                            onUpdateStatus('COMPLETED');
                          } else {
                            onOpen();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _TaskScreenState._primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          status == 'ASSIGNED'
                              ? 'START TASK'
                              : status == 'IN_PROGRESS'
                              ? 'UPDATE STATUS'
                              : 'DETAIL',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 46,
                      height: 46,
                      child: OutlinedButton(
                        onPressed: onOpen,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _TaskScreenState._primary,
                          side: const BorderSide(
                            color: _TaskScreenState._primary,
                            width: 1.4,
                          ),
                          padding: EdgeInsets.zero,
                          shape: const CircleBorder(),
                        ),
                        child: const Icon(Icons.map),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  static ({String text, Color bg, Color fg}) _statusData(String status) {
    switch (status) {
      case 'ASSIGNED':
        return (
          text: 'ASSIGNED',
          bg: Colors.orange.withOpacity(0.2),
          fg: Colors.orange.shade700,
        );
      case 'IN_PROGRESS':
        return (
          text: 'IN_PROGRESS',
          bg: Colors.blue.withOpacity(0.18),
          fg: Colors.blue.shade700,
        );
      case 'COMPLETED':
      case 'DONE':
        return (
          text: 'COMPLETED',
          bg: Colors.green.withOpacity(0.18),
          fg: Colors.green.shade700,
        );
      default:
        return (
          text: status,
          bg: Colors.grey.withOpacity(0.18),
          fg: Colors.grey.shade700,
        );
    }
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final bool muted;

  const _InfoLine({
    required this.icon,
    required this.text,
    this.color,
    this.muted = false,
  });

  @override
  Widget build(BuildContext context) {
    final lineColor =
        color ??
        (muted ? _TaskScreenState._outline : _TaskScreenState._textVariant);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: muted
              ? _TaskScreenState._outline.withOpacity(0.55)
              : _TaskScreenState._outline,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: lineColor,
              fontSize: 15,
              height: 1.3,
              fontWeight: icon == Icons.person ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _StatusChip({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _LoadingTaskCard extends StatelessWidget {
  const _LoadingTaskCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _TaskScreenState._surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
