// Required for Firebase Messaging in the web
importScripts(
  "https://www.gstatic.com/firebasejs/9.6.10/firebase-app-compat.js"
);
importScripts(
  "https://www.gstatic.com/firebasejs/9.6.10/firebase-messaging-compat.js"
);

firebase.initializeApp({
  apiKey: "AIzaSyB2_NdDlF_OAo5LYYclzki7bk0UfQujh7A",
  authDomain: "snenh-ade4e.firebaseapp.com",
  projectId: "snenh-ade4e",
  storageBucket: "snenh-ade4e.firebasestorage.app",
  messagingSenderId: "126885412714",
  appId: "1:126885412714:android:dbc53878a17fdc5504af13",
});

const messaging = firebase.messaging();
