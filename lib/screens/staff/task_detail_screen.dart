import 'dart:io';
import 'package:booking_don_rac/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/task_model.dart';
import '../../models/booking_model.dart';
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
  File? beforeImage;
  File? afterImage;

  final picker = ImagePicker();
  final service = CommonService();

  Future<void> pickBefore() async {
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      setState(() => beforeImage = File(file.path));
    }
  }

  Future<void> pickAfter() async {
    final file = await picker.pickImage(source: ImageSource.camera);
    if (file != null) {
      setState(() => afterImage = File(file.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EmployeeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Task Detail")),

      body: FutureBuilder(
        future: FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.task.bookingId)
            .get(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final booking = BookingModel.fromDoc(
            snap.data!.id,
            snap.data!.data()!,
          );

          return FutureBuilder(
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

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ===============================
                    // 🔥 INFO
                    // ===============================
                    Text(
                      "🧹 ${serviceData?["name"]}",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text("📍 ${address?["fullAddress"]}"),
                    Text("👤 ${address?["receiverName"]}"),
                    Text("📞 ${address?["phone"]}"),

                    const SizedBox(height: 10),

                    // ===============================
                    // 💬 CHAT BUTTON
                    // ===============================
                    ElevatedButton(
                      onPressed: () async {
                        final roomId = await ChatService().getRoomId(
                          widget.task.bookingId,
                          booking.userId,
                          provider.userId,
                        );

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              roomId: roomId,
                              myId: provider.userId,
                              myName: provider.userId, // 🔥 thêm tên
                            ),
                          ),
                        );
                      },
                      child: const Text("CHAT"),
                    ),

                    const SizedBox(height: 20),

                    // ===============================
                    // 📸 BEFORE
                    // ===============================
                    const Text("Before Image"),
                    const SizedBox(height: 10),

                    beforeImage != null
                        ? Image.file(beforeImage!, height: 150)
                        : widget.task.beforeImage.isNotEmpty
                        ? Image.network(widget.task.beforeImage, height: 150)
                        : const Text("No image"),

                    ElevatedButton(
                      onPressed: pickBefore,
                      child: const Text("Chụp BEFORE"),
                    ),

                    const SizedBox(height: 20),

                    // ===============================
                    // 📸 AFTER
                    // ===============================
                    const Text("After Image"),
                    const SizedBox(height: 10),

                    afterImage != null
                        ? Image.file(afterImage!, height: 150)
                        : widget.task.afterImage.isNotEmpty
                        ? Image.network(widget.task.afterImage, height: 150)
                        : const Text("No image"),

                    ElevatedButton(
                      onPressed: pickAfter,
                      child: const Text("Chụp AFTER"),
                    ),

                    const SizedBox(height: 30),

                    // ===============================
                    // ▶ START
                    // ===============================
                    if (widget.task.status == "ASSIGNED")
                      ElevatedButton(
                        onPressed: () {
                          provider.startTask(
                            widget.task.id,
                            widget.task.bookingId,
                          );
                        },
                        child: const Text("START"),
                      ),

                    // ===============================
                    // ✅ COMPLETE
                    // ===============================
                    if (widget.task.status == "IN_PROGRESS")
                      ElevatedButton(
                        onPressed: () async {
                          if (afterImage == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Chụp ảnh AFTER trước"),
                              ),
                            );
                            return;
                          }

                          await provider.completeTaskWithImage(
                            widget.task.id,
                            widget.task.bookingId,
                            afterImage!,
                          );

                          Navigator.pop(context);
                        },
                        child: const Text("COMPLETE"),
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
}
