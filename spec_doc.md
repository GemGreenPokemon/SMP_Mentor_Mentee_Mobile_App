# SMP Mentor-Mentee App - Feature Specification Document  
**Prepared by Emerald Nash**  

## Table of Contents  
1. Overview  
2. Core Features  
   - 2.1 User Roles & Authentication  
   - 2.2 Messaging System  
   - 2.3 Checklist & Progress Tracking  
   - 2.4 Calendar & Scheduling  
   - 2.5 Meeting Notes & Takeaways  
   - 2.6 Progress Reports  
   - 2.7 Resources & Information Hub  
   - 2.8 Survey, Feedback, & Attendance System  
   - 2.9 Experimental Feature: Live Transcription  
   - 2.10 After-Meeting Feedback System  
   - 2.11 Announcements System  
   - 2.12 Check-In and Check-Out System  
3. Tech Stack  

---

## 1. Overview  
The SMP Mentor-Mentee App is a cross-platform mobile application (iOS & Android) built using Flutter. It will serve as a central hub for mentors, mentees, and coordinators to communicate, track progress, and access important resources. The app aims to streamline the mentorship experience by integrating messaging, scheduling, progress tracking, attendance tracking, and feedback collection.  

---

## 2. Core Features  

### 2.1 User Roles & Authentication  
The app will have three distinct login options:  

#### **Mentee Login**  
- View assigned mentor  
- Access resources & program requirements  
- Track checklist & progress  
- Submit proof of completed tasks (optional)  
- Sign into events directly from the calendar (via Qualtrics API)  
- Communicate with mentor  

#### **Mentor Login**  
- View assigned mentees  
- Message mentees & schedule meetings  
- Track mentee progress  
- Approve or escalate mentee-submitted progress  
- Take meeting notes & assign action items  

#### **Coordinator Login**  
- View all mentees & mentors  
- Oversee program progress  
- Manage event calendar & program updates  
- Review escalated progress submissions (if feature is implemented)  
- Access and analyze survey & feedback data via Qualtrics API  
- Track attendance using Qualtrics API-based sign-in/sign-out surveys  

#### **Authentication System**  
**Primary Authentication Method:** Currently under consideration. Options include:  
- **UC Merced Single Sign-On (SSO):** Integrating with UC Merced's centralized authentication system, allowing users to log in using their UCMNetID credentials.  
- **Firebase Authentication:** Utilizing Firebase's built-in authentication services, supporting email/password, Google, Facebook, and other providers.  

**User Credentials Storage:**  
- If UC Merced SSO is implemented, user credentials will be managed by the university’s authentication system.  
- If Firebase Authentication is used, credentials will be managed by Firebase.  

**Role-Based Access Control (RBAC):** The relevance and implementation of RBAC are under evaluation.  

---

### 2.2 Messaging System  
- Direct messaging between mentors & mentees  
- Group messaging (optional)  
- Real-time updates using Firebase Firestore  
- Push notifications via snapshot listeners  
- Firebase Cloud Messaging (FCM) as a backup  

---

### 2.3 Checklist & Progress Tracking  
- Program requirements checklist for mentees  
- Mentees can check off completed tasks and optionally submit proof via snapshots  
- Mentors review and approve progress or escalate uncertain submissions to the coordinator  
- Coordinator final approval option (under consideration)  

---

### 2.4 Calendar & Scheduling  
- Mentor availability & scheduling (mentors set available slots)  
- Event calendar with mentor sessions & program events  
- Mentees can sign into events from the calendar  
- Google Calendar API integration (optional)  
- Reminders & notifications for upcoming sessions  

---

### 2.5 Meeting Notes & Takeaways  
- Private notes section for mentors & mentees  
- Action items tracking (mentors set follow-up tasks for mentees)  
- Session history (review past discussions & progress)  

---

### 2.6 Progress Reports  
- Linked to the program guide & checklist  
- Tracks completed tasks & requirements for mentees  
- Mentors and coordinators can review progress over time  

---

### 2.7 Resources & Information Hub  
**Purpose:** Centralized repository for mentorship resources.  

**Implementation Details:**  
- **General Resources:**  
  - **Mentor-Mentee Guide**: FAQs, best practices, and program structure.  
  - **Newsletter Section**: Regular program updates and announcements.  
  - **Embedded Links**: Curated external resources.  
- **Document Repository:**  
  - General & personalized resources for mentees.  
  - Mentors can upload custom materials for mentees.  
- **File Management:**  
  - Upload/download functionality for PDFs, DOCX, XLSX.  
  - Version control to track document updates.  
- **Access Control & Security:**  
  - Encryption for data at rest and in transit.  
  - Secure authentication for verifying user identities.  

---

### 2.8 Survey, Feedback, & Attendance System  
- Surveys & feedback collection via Qualtrics API  
- Attendance tracking via Qualtrics sign-in/sign-out surveys  
- Responses submitted programmatically through API  

---

### 2.9 Experimental Feature: Live Transcription  
**Purpose:** Real-time transcription during mentor-mentee meetings.  

**Implementation Details:**  
- **Uses OpenAI Whisper Tiny Model (39MB)** for local real-time transcription  
- **92% accuracy**, ~500MB RAM usage, 0.3-2s latency  
- Runs **locally** on mobile devices  

**Workflow:**  
- Audio processed in **5-10s chunks**  
- Uses **FFmpeg for audio preprocessing** before Whisper transcribes  
- Latency: **200-500ms delay per 3s audio chunk**  

**Speaker Detection Approaches:**  
- **Turn-Based System (Preferred)**  
- **Speaker Diarization Model (Higher Accuracy, More Power Needed)**  
- **Manual Speaker Labeling (Backup Option)**  

**Status:** **Experimental – May not make it into the final app.**  

---

### 2.10 After-Meeting Feedback System  
- **Feedback Prompt** after each meeting  
- **Mentee Questions:**  
  - Was the meeting helpful? (Yes/No)  
  - Do you have concerns/questions? (Open text)  
  - Next action item? (Short response)  
  - Meeting rating (⭐ to ⭐⭐⭐⭐⭐)  
- **Mentor Questions:**  
  - Additional notes section  

---

### 2.11 Announcements System  
**Purpose:** Disseminate important information to mentors & mentees.  

**Implementation Details:**  
- **Announcement Structure:**  
  - Title  
  - Date & Time  
  - Content  
  - Relevant Links  
- **Targeting:** Send announcements to mentors, mentees, or both.  
- **Notification System:** Alerts for new announcements.  

---

### 2.12 Check-In and Check-Out System  
- **Mentors log meeting start and end times**  
- **Check-In Process:**  
  - Select session > Click "Check-In" > Start time recorded  
- **Meeting Interface:**  
  - **Note-Taking Tools** for documentation  
  - **Experimental Live Transcription (if enabled)**  
- **Check-Out Process:**  
  - Click "Check-Out" > End time recorded  
- **Seamless transition to After-Meeting Feedback System**  

---

## 3. Tech Stack  
- **Frontend:** Flutter (Dart)  
- **Backend:** Firebase for real-time data syncing  
- **Authentication:** Google OAuth (primary), Firebase Authentication (for database connection only)  
- **Database:** Firestore or PostgreSQL  
- **Notifications:** Snapshot listeners (primary) & Firebase Cloud Messaging (backup)  
- **Calendar Syncing:** Google Calendar API (optional)  
- **Survey, Feedback, & Attendance Tracking:** Qualtrics API  
- **Experimental:** OpenAI Whisper Tiny Model (39MB) for live transcription  
- **Potential Future Consideration:** Supabase  

---
