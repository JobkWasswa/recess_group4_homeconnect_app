// web/firebase-messaging-sw.js
importScripts(
  "https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js"
);
importScripts(
  "https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js"
);

// Initialize the Firebase app in the service worker by passing in
// your app's Firebase config object.
// https://firebase.google.com/docs/web/setup#config-object
const firebaseConfig = {
  apiKey: "AIzaSyBmfUWwr3W2J_pJy4tDtn47A7kT0JbUPnw",
  authDomain: "homeconnect-a9d5c.firebaseapp.com",
  projectId: "homeconnect-a9d5c",
  storageBucket: "homeconnect-a9d5c.firebasestorage.app",
  messagingSenderId: "279318295980",
  appId: "1:279318295980:web:6e81cfbc35297a783e7609",
  measurementId: "G-EDCY4369RK",
};

firebase.initializeApp(firebaseConfig);

// Retrieve firebase messaging
const messaging = firebase.messaging();

// Optional:
// messaging.onBackgroundMessage(function(payload) {
//   console.log('[firebase-messaging-sw.js] Received background message ', payload);
//   // Customize notification here
//   const notificationTitle = payload.notification.title;
//   const notificationOptions = {
//     body: payload.notification.body,
//     icon: '/firebase-logo.png' // Or your app's icon
//   };
//
//   return self.registration.showNotification(notificationTitle,
//     notificationOptions);
// });
