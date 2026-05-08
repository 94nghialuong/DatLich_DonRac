import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReviewCreateScreen extends StatefulWidget {
  final String bookingId;
  final String employeeId;

  const ReviewCreateScreen({
    super.key,
    required this.bookingId,
    required this.employeeId,
  });

  @override
  State<ReviewCreateScreen> createState() => _ReviewCreateScreenState();
}

class _ReviewCreateScreenState extends State<ReviewCreateScreen> {
  final commentController = TextEditingController();

  int rating = 5;

  bool loading = false;

  Future<void> submitReview() async {
    try {
      setState(() => loading = true);

      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection("reviews").add({
        "bookingId": widget.bookingId,
        "employeeId": widget.employeeId,
        "userId": user!.uid,
        "rating": rating,
        "comment": commentController.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đánh giá thành công")));

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => loading = false);
    }
  }

  Widget buildStar(int index) {
    return IconButton(
      onPressed: () {
        setState(() {
          rating = index;
        });
      },
      icon: Icon(
        Icons.star,
        color: index <= rating ? Colors.amber : Colors.grey,
        size: 36,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Đánh giá")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            const Text(
              "Bạn hài lòng như thế nào?",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) => buildStar(index + 1)),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: commentController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Nhập đánh giá...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : submitReview,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Gửi đánh giá"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
