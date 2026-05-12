import 'dart:io';

import 'package:booking_don_rac/services/chat_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/booking_model.dart';
import '../../models/task_model.dart';
import '../../provider/employee_provider.dart';
import '../../services/common_service.dart';
import 'chat_screen.dart';

class TaskDetail extends StatefulWidget {
  final TaskModel task;

  const TaskDetail({super.key, required this.task});

  @override
  State<TaskDetail> createState() => _TaskDetailState();
}

class _TaskDetailState extends State<TaskDetail> {
  static const Color _bg = Color(0xFFEEFDFD);
  static const Color _primary = Color(0xFF006D37);
  static const Color _primarySoft = Color(0xFF2ECC71);
  static const Color _surface = Colors.white;
  static const Color _surfaceContainer = Color(0xFFE3F0F1);
  static const Color _outline = Color(0xFF6C7B6D);
  static const Color _textDark = Color(0xFF121E1F);
  static const Color _textVariant = Color(0xFF3D4A3E);
  static const Color _error = Color(0xFFBA1A1A);

  final ImagePicker picker = ImagePicker();
  final CommonService service = CommonService();

  File? beforeImage;
  File? afterImage;
  bool isSubmitting = false;

  String get status => widget.task.status.toUpperCase();

  Future<void> pickBefore() async {
    final file = await picker.pickImage(source: ImageSource.camera);

    if (file == null) return;

    setState(() {
      beforeImage = File(file.path);
    });
  }

  Future<void> pickAfter() async {
    final file = await picker.pickImage(source: ImageSource.camera);

    if (file == null) return;

    setState(() {
      afterImage = File(file.path);
    });
  }

  Future<void> _startTask(EmployeeProvider provider) async {
    setState(() => isSubmitting = true);

    try {
      await provider.startTask(widget.task.id, widget.task.bookingId);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Đã bắt đầu công việc')));

      Navigator.pop(context);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Future<void> _completeTask(EmployeeProvider provider) async {
    setState(() => isSubmitting = true);

    try {
      if (afterImage != null) {
        await provider.completeTaskWithImage(
          widget.task.id,
          widget.task.bookingId,
          afterImage!,
        );
      } else {
        await FirebaseFirestore.instance
            .collection('tasks')
            .doc(widget.task.id)
            .update({
              'status': 'COMPLETED',
              'endTime': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });

        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.task.bookingId)
            .update({
              'status': 'COMPLETED',
              'updatedAt': FieldValue.serverTimestamp(),
            });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hoàn thành task')));

      Navigator.pop(context);
    } catch (e) {
      _showError(e);
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Future<void> _openChat({
    required BookingModel booking,
    required EmployeeProvider provider,
    required Map<String, dynamic>? address,
  }) async {
    final roomId = await ChatService().getRoomId(
      widget.task.bookingId,
      booking.userId,
      provider.userId,
    );

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          roomId: roomId,
          myId: provider.userId,
          myName: address?['receiverName']?.toString() ?? 'Nhân viên',
        ),
      ),
    );
  }

  void _showError(Object e) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(e.toString())));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EmployeeProvider>();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _surface,
        foregroundColor: _primary,
        centerTitle: true,
        title: const Text(
          'Chi tiết Task',
          style: TextStyle(color: _primary, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: _BottomAction(
        status: status,
        loading: isSubmitting,
        onStart: () => _startTask(provider),
        onComplete: () => _completeTask(provider),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.task.bookingId)
            .get(),
        builder: (context, bookingSnap) {
          if (!bookingSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rawBooking = bookingSnap.data!.data();

          if (rawBooking == null) {
            return const Center(child: Text('Không tìm thấy booking'));
          }

          final booking = BookingModel.fromDoc(
            bookingSnap.data!.id,
            rawBooking as Map<String, dynamic>,
          );

          return FutureBuilder<List<Map<String, dynamic>?>>(
            future: Future.wait([
              service.getService(booking.serviceId),
              service.getAddress(booking.addressId),
            ]),
            builder: (context, dataSnap) {
              if (!dataSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final serviceData = dataSnap.data![0];
              final address = dataSnap.data![1];
              final serviceName = serviceData?['name']?.toString() ?? 'Dịch vụ';
              final fullAddress =
                  address?['fullAddress']?.toString() ?? 'Không có địa chỉ';
              final receiver =
                  address?['receiverName']?.toString() ?? 'Không có tên';
              final phone = address?['phone']?.toString() ?? 'Không có SĐT';
              final note = '';
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _StatusChip(status: status)),
                    const SizedBox(height: 20),
                    _InfoCard(
                      taskId: widget.task.id,
                      bookingId: widget.task.bookingId,
                      serviceName: serviceName,
                      timeText: _formatTaskTime(booking.time),
                      fullAddress: fullAddress,
                      receiver: receiver,
                      phone: phone,
                      onChat: () => _openChat(
                        booking: booking,
                        provider: provider,
                        address: address,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _PhotoSection(
                      title: 'Chụp BEFORE',
                      requiredText: 'Bắt buộc',
                      localImage: beforeImage,
                      imageUrl: widget.task.beforeImage,
                      emptyText: 'Chưa có ảnh BEFORE',
                      buttonText:
                          beforeImage != null ||
                              widget.task.beforeImage.isNotEmpty
                          ? 'CHỤP LẠI ẢNH BEFORE'
                          : 'CHỤP ẢNH BEFORE',
                      onCapture: pickBefore,
                    ),
                    const SizedBox(height: 18),
                    _PhotoSection(
                      title: 'Chụp AFTER',
                      requiredText: 'Tùy chọn',
                      localImage: afterImage,
                      imageUrl: widget.task.afterImage,
                      emptyText: 'Chưa có ảnh AFTER',
                      buttonText:
                          afterImage != null ||
                              widget.task.afterImage.isNotEmpty
                          ? 'CHỤP LẠI ẢNH AFTER'
                          : 'CHỤP ẢNH AFTER',
                      onCapture: pickAfter,
                      optional: true,
                    ),
                    const SizedBox(height: 18),
                    _NoteBox(
                      note: note.isEmpty ? 'Không có ghi chú dịch vụ.' : note,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _formatTaskTime(Timestamp time) {
    final date = time.toDate();

    return 'Hôm nay, '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

class _IdChip extends StatelessWidget {
  final String label;
  final String value;

  const _IdChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _TaskDetailState._surfaceContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label: $value',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: _TaskDetailState._primary,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String bookingId;
  final String taskId;
  final String serviceName;
  final String timeText;
  final String fullAddress;
  final String receiver;
  final String phone;
  final VoidCallback onChat;

  const _InfoCard({
    required this.bookingId,
    required this.taskId,
    required this.serviceName,
    required this.timeText,
    required this.fullAddress,
    required this.receiver,
    required this.phone,
    required this.onChat,
  });

  String _shortId(String id) {
    if (id.length <= 10) return id;
    return id.substring(0, 10);
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _TaskDetailState._primarySoft.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.cleaning_services,
                  color: _TaskDetailState._primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: const TextStyle(
                        color: _TaskDetailState._textDark,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _IdChip(label: 'Booking', value: _shortId(bookingId)),
                        _IdChip(label: 'Task', value: _shortId(taskId)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          color: _TaskDetailState._primary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeText,
                          style: const TextStyle(
                            color: _TaskDetailState._textVariant,
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.green.withOpacity(0.08)),
          const SizedBox(height: 10),
          _InfoLine(
            icon: Icons.confirmation_number,
            text: 'Mã booking: $bookingId',
          ),
          const SizedBox(height: 14),
          _InfoLine(icon: Icons.task_alt, text: 'Mã task: $taskId'),
          const SizedBox(height: 14),
          _InfoLine(icon: Icons.location_on, text: fullAddress),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(Icons.person, color: _TaskDetailState._primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receiver,
                      style: const TextStyle(
                        color: _TaskDetailState._textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      phone,
                      style: const TextStyle(
                        color: _TaskDetailState._textVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: onChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _TaskDetailState._primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                icon: const Icon(Icons.chat, size: 18),
                label: const Text(
                  'CHAT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  final String title;
  final String requiredText;
  final File? localImage;
  final String imageUrl;
  final String emptyText;
  final String buttonText;
  final VoidCallback onCapture;
  final bool optional;

  const _PhotoSection({
    required this.title,
    required this.requiredText,
    required this.localImage,
    required this.imageUrl,
    required this.emptyText,
    required this.buttonText,
    required this.onCapture,
    this.optional = false,
  });

  bool get hasImage => localImage != null || imageUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _TaskDetailState._textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Row(
                children: [
                  if (!optional)
                    const Icon(
                      Icons.error,
                      color: _TaskDetailState._error,
                      size: 14,
                    ),
                  if (!optional) const SizedBox(width: 4),
                  Text(
                    requiredText,
                    style: TextStyle(
                      color: optional
                          ? _TaskDetailState._textVariant.withOpacity(0.65)
                          : _TaskDetailState._error,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: double.infinity,
              height: 190,
              child: _PreviewImage(
                localImage: localImage,
                imageUrl: imageUrl,
                emptyText: emptyText,
              ),
            ),
          ),
          if (hasImage) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.green.withOpacity(0.12)),
              ),
              child: const Text(
                'Đã tải lên',
                style: TextStyle(
                  color: _TaskDetailState._primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCapture,
              style: OutlinedButton.styleFrom(
                foregroundColor: _TaskDetailState._primary,
                side: const BorderSide(
                  color: _TaskDetailState._primary,
                  width: 2,
                ),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              icon: const Icon(Icons.photo_camera),
              label: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewImage extends StatelessWidget {
  final File? localImage;
  final String imageUrl;
  final String emptyText;

  const _PreviewImage({
    required this.localImage,
    required this.imageUrl,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (localImage != null) {
      return Image.file(localImage!, fit: BoxFit.cover);
    }

    if (imageUrl.isNotEmpty) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _EmptyImage(text: 'Không tải được ảnh'),
      );
    }

    return _EmptyImage(text: emptyText);
  }
}

class _EmptyImage extends StatelessWidget {
  final String text;

  const _EmptyImage({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _TaskDetailState._surfaceContainer,
        border: Border.all(color: Colors.green.withOpacity(0.15), width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            color: _TaskDetailState._textVariant.withOpacity(0.35),
            size: 52,
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: TextStyle(
              color: _TaskDetailState._textVariant.withOpacity(0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  final String note;

  const _NoteBox({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _TaskDetailState._primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _TaskDetailState._primary.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GHI CHÚ DỊCH VỤ',
            style: TextStyle(
              color: _TaskDetailState._primary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"$note"',
            style: const TextStyle(
              color: _TaskDetailState._textVariant,
              fontSize: 14,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  final String status;
  final bool loading;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  const _BottomAction({
    required this.status,
    required this.loading,
    required this.onStart,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    if (status == 'COMPLETED' || status == 'DONE') {
      return const SizedBox.shrink();
    }

    final isAssigned = status == 'ASSIGNED';
    final label = isAssigned ? 'BẮT ĐẦU' : 'HOÀN THÀNH';
    final icon = isAssigned ? Icons.play_arrow : Icons.check_circle;
    final action = isAssigned ? onStart : onComplete;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
      decoration: BoxDecoration(
        color: _TaskDetailState._surface,
        border: Border(top: BorderSide(color: Colors.green.withOpacity(0.08))),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E8449).withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: loading ? null : action,
            style: ElevatedButton.styleFrom(
              backgroundColor: _TaskDetailState._primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
              elevation: 8,
              shadowColor: _TaskDetailState._primary.withOpacity(0.25),
            ),
            icon: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(icon),
            label: Text(
              loading ? 'ĐANG XỬ LÝ...' : label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final data = _statusData(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: data.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        data.text,
        style: TextStyle(
          color: data.fg,
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  static ({String text, Color bg, Color fg}) _statusData(String status) {
    switch (status) {
      case 'ASSIGNED':
        return (
          text: 'ĐÃ GIAO',
          bg: Colors.orange.withOpacity(0.18),
          fg: Colors.orange.shade700,
        );
      case 'IN_PROGRESS':
        return (
          text: 'ĐANG THỰC HIỆN',
          bg: const Color(0xFF94F4AD),
          fg: const Color(0xFF00723A),
        );
      case 'COMPLETED':
      case 'DONE':
        return (
          text: 'ĐÃ HOÀN THÀNH',
          bg: Colors.green.withOpacity(0.18),
          fg: Colors.green.shade700,
        );
      default:
        return (
          text: status,
          bg: _TaskDetailState._surfaceContainer,
          fg: _TaskDetailState._outline,
        );
    }
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _TaskDetailState._primary),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: _TaskDetailState._textDark,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _TaskDetailState._surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E8449).withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
