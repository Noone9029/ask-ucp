# AskUCP 📱

AskUCP is a cross-platform mobile application built to help students quickly access information related to university life, resources, and services. The application focuses on providing a simple and efficient interface for navigating academic tools, institutional resources, and helpful information within a single mobile platform.

The project is built using modern mobile development technologies with a focus on performance, maintainability, and scalability.

---

## 🚀 Overview

AskUCP was designed to simplify how students interact with university information. Instead of navigating multiple systems or websites, the application centralizes essential tools and resources in one place.

Key goals of the project include:

* Providing a clean and intuitive mobile experience
* Centralizing university-related resources
* Enabling scalable architecture for future feature additions
* Leveraging modern cross-platform mobile development tools

---

## 🧠 Core Technologies

AskUCP combines modern mobile development with AI-powered services and real-time mapping to provide students with an intelligent campus assistant.

### Mobile Application

* **Flutter**

  * Cross-platform UI framework used to build the application from a single codebase.
* **Dart**

  * Programming language used for all application logic and UI implementation.

### Artificial Intelligence & Data Processing

**Google Cloud Vision**

* Used for image analysis and fraud detection.
* Allows the application to analyze uploaded images and detect suspicious or manipulated content.
* Provides machine learning powered optical recognition and classification.

**Retrieval-Augmented Generation (RAG) Model**

* Used to answer campus-related questions.
* Combines a knowledge database with an AI model to generate accurate responses.
* Enables students to ask natural language questions about campus resources, policies, and services.

Workflow:

1. User submits a query
2. Relevant documents are retrieved from the campus knowledge base
3. The AI model generates a contextual response using retrieved information

### Mapping & Navigation

**OpenStreetMap API**

* Used for the campus navigation system.
* Provides open-source geospatial data for rendering maps.

**Real-Time Campus Navigation**

* Interactive map interface
* Allows students to explore buildings and campus locations
* Enables location-based navigation across the university.

### Backend & Cloud Infrastructure

**Firebase**

* Cloud infrastructure used for backend services.

Services include:

* Cloud Functions for server-side logic
* Data storage and configuration
* Backend integration with the mobile app

---

## ⚡ Key Features

* 📱 Cross-platform mobile application built with Flutter
* 🤖 AI-powered campus question answering using a RAG model
* 🔍 Fraud detection using Google Cloud Vision
* 🗺 Real-time campus navigation using OpenStreetMap
* ☁️ Cloud-powered backend using Firebase
* 🧩 Modular architecture for scalability and future expansion

---

## 🏗 System Architecture

```
User
 │
 ▼
Flutter Mobile App
 │
 ├── Campus Query → RAG Model → Knowledge Base
 │
 ├── Image Upload → Google Cloud Vision → Fraud Detection
 │
 └── Map Requests → OpenStreetMap API → Real-time Navigation
 │
 ▼
Firebase Backend
```

---

## 📥 Download APK

[![Download APK](https://img.shields.io/badge/Download-AskUCP%20APK-blue?style=for-the-badge\&logo=android)](https://github.com/Noone9029/ask-ucp/releases/tag/v1.0.0)

### Frontend

* **Flutter**
  The core framework used to build the mobile application. Flutter allows development of high-performance native apps from a single codebase.

* **Dart**
  The primary programming language used for building the application logic and UI.

### Backend / Services

* **Firebase Integration**

  * Cloud services used for backend infrastructure
  * Potential services include authentication, data storage, and cloud functions

* **Firebase Cloud Functions**
  Server-side logic implemented using cloud functions for handling backend operations.

### Mobile Platform Support

* **Android** (primary supported platform)

---

## 🗂 Project Structure

```
ask_ucp_flutter/
│
├── android/           # Android native configuration
├── assets/            # Images, icons, and static resources
├── lib/               # Main Flutter application source code
│   ├── screens/       # UI screens
│   ├── widgets/       # Reusable UI components
│   ├── services/      # API and backend service integrations
│   └── main.dart      # Application entry point
│
├── functions/         # Firebase Cloud Functions
├── scripts/           # Development scripts and utilities
├── test/              # Automated tests
│
├── pubspec.yaml       # Flutter dependencies and configuration
├── firebase.json      # Firebase project configuration
└── README.md
```

---

## ⚙️ Features

* Student-focused mobile interface
* Modular Flutter architecture
* Backend integration using Firebase
* Cloud-based server logic
* Scalable application structure
* Cross-platform ready codebase

---

## 🛠 Development Setup

### Prerequisites

Install the following tools before running the project:

* Flutter SDK
* Dart SDK
* Android Studio or VS Code
* Git

---

### Clone the Repository

```
git clone https://github.com/YOUR_USERNAME/askucp.git
cd askucp
```

---

### Install Dependencies

```
flutter pub get
```

---

### Run the Application

```
flutter run
```

This will launch the application on a connected Android device or emulator.

---

## 🔧 Build the App

To build the Android release APK:

```
flutter build apk
```

---

## 🧪 Testing

Run tests using:

```
flutter test
```

---

## 📦 Dependencies

All dependencies are managed through:

```
pubspec.yaml
```

Flutter automatically resolves and installs required packages.

---

## 🔮 Future Improvements

Potential improvements for the project include:

* Expanded university resource integration
* Real-time notifications
* Authentication and user accounts
* Enhanced UI/UX design
* Support for iOS devices
* Analytics and usage tracking

---

## 📄 License

This project is currently maintained as a private or internal application.

---

## 👨‍💻 Author

Developed as part of the AskUCP project using Flutter and modern mobile development technologies.
