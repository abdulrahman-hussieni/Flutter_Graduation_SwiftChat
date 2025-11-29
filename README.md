Sampark Chat Application – Full Documentation
1. Introduction

Sampark Chat is a real-time messaging application built to provide seamless, fast, and modern communication. The app allows users to interact through private chats, group messaging, and multimedia sharing with a clean and intuitive user interface.

This documentation outlines the full system, including project idea, architecture, user journey, wireframes, database design, technology stack, development workflow, and team contributions.

2. Project Overview
2.1 Project Idea

Sampark Chat aims to deliver an easy-to-use, reliable, and modern messaging platform supporting:

One-to-one chat

Group messaging

Real-time notifications

User presence status

Multimedia sharing (images, voice notes)

Basic voice & video calling capabilities

2.2 Project Objectives

Build a scalable chat system using Firebase services.

Provide smooth user experience with an intuitive UI/UX.

Support media-rich communication.

Maintain fast and secure data processing.

2.3 Design & Prototyping

Full UI/UX workflow created using Figma:

🔗 Figma Design File:
https://www.figma.com/design/4PV5npoc2co8sSzhUDDZpx/SMPARK-DEPI-Final-Project

3. User Journey
3.1 Onboarding Flow

Splash Screen – App logo animation.

Welcome Screen – Option to log in or create an account.

Account Creation – Email/password authentication.

Profile Setup – User uploads profile image and sets display name.

Redirect to Home Screen – User lands on chat list.

3.2 Core User Actions

Open chats

Start a new chat

Send text messages, images, emojis, and voice notes

Group messaging

Voice and video calls

Access Settings (profile, theme, privacy)

4. Wireframes (Concept Overview)
4.1 Home Screen

Recent chats list

Floating action button for creating new chats

4.2 Chat Screen

Message list with timestamps

Text input bar

Attachments (images, voice messages)

Online/typing indicators

4.3 Settings Screen

Profile settings

Notification preferences

Privacy options

Logout

4.4 Group Chat Screen

Group details

Members list

Admin control options

🎨 All wireframes available in the Figma link above

5. Features Breakdown
5.1 Core Features

Real-time chatting (Firebase Firestore)

Secure Authentication (Firebase Auth)

Online/offline status tracking

Push notifications

5.2 Media Features

Image uploading (Firebase Storage)

Voice messages recording + upload

5.3 Calling Features

Basic Voice/Video calling (WebRTC / Firebase integration)

5.4 User Settings

Update username

Change profile picture

Manage notifications

6. Database Architecture
6.1 Key Collections
Users

userId

name

email

profileImage

status

Chats

chatId

members[]

lastMessage

timestamp

Messages

senderId

messageType (text/image/voice)

content

timestamp

6.2 Data Flow

User enters input

Firebase Auth validates

Firestore stores chats/messages

Firebase Storage handles media

App listens to message snapshots in real-time

6.3 Security

Firebase security rules

Authentication required

Private chat access restricted to members

7. Technology Stack
Frontend

Flutter

Dart

Backend & Storage

Firebase Authentication

Firebase Firestore

Firebase Storage

Firebase Cloud Messaging

Node.js (optional backend)

State Management

GetX

8. Development Progress & Testing
8.1 Development Stage

Authentication ✓

User profiles ✓

One-to-one chat ✓

Group chat ✓

Media sharing ✓

Basic calling ✓

8.2 Testing

Unit Testing

Integration Testing

User Acceptance Testing

Feedback showed:

Smooth UI

Good messaging performance

Small UI improvements needed

9. Project Timeline & Milestones
Milestone	Description	Deadline
Project Proposal	Define objectives and tools	Sep 15, 2025
UI/UX & System Design	Architecture and Figma wireframes	Oct 1, 2025
Core Development	Chat, Auth, Firebase setup	Oct 15, 2025
Advanced Features	Images, voice, video	Oct 25, 2025
Testing & Debugging	Fix issues and optimize	Nov 22, 2025
Final Submission	Full presentation & documentation	Nov 29, 2025
10. Team Members & Roles
Abdalrhman Hussieni Abdallah Khalil (Team Leader)

UI/UX Design

Authentication

One-to-one chat

Mahmoud Ahmed Abdelghani

Authentication

Group Chat

Omar Mohamed Elsayed

One-to-one Chat

Group Chat

11. Conclusion

Sampark Chat represents a fully functional, scalable, and modern messaging platform. With a robust backend, intuitive UI design, and well-structured architecture, the app is ready for real-world deployment and future enhancements.

Thank you for reviewing the documentation.
