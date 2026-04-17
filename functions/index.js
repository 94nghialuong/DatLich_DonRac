const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// 🔥 1. AUTO GÁN ROLE
exports.setDefaultRole = functions.auth.user().onCreate(async (user) => {
  await admin.auth().setCustomUserClaims(user.uid, {
    role: "CUSTOMER",
  });

  console.log("✅ Set role CUSTOMER:", user.uid);
});

// 🔥 2. AUTO TẠO USER PROFILE
exports.createUserProfile = functions.auth.user().onCreate(async (user) => {
  const db = admin.firestore();

  await db.collection("users").doc(user.uid).set({
    fullName: user.displayName || "",
    email: user.email || "",
    phone: user.phoneNumber || "",
    avatar: "",
    status: true,
    roles: ["CUSTOMER"],
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log("✅ Created user profile");
});

// 🔥 3. TẠO PAYMENT KHI BOOKING
exports.createPayment = functions.firestore
    .document("bookings/{bookingId}")
    .onCreate(async (snap, context) => {
      const db = admin.firestore();
      const bookingId = context.params.bookingId;

      await db.collection("payments").add({
        bookingId: bookingId,
        amount: 50000,
        method: "CASH",
        status: "PENDING",
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("✅ Payment created");
    });

// 🔥 4. TẠO CHAT ROOM
exports.createChatRoom = functions.firestore
    .document("bookings/{bookingId}")
    .onCreate(async (snap, context) => {
      const data = snap.data();
      const db = admin.firestore();

      await db.collection("chatRooms").add({
        bookingId: context.params.bookingId,
        members: [data.userId],
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log("✅ Chat room created");
    });
