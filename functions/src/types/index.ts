// Common type definitions for Cloud Functions

export interface University {
  id: string;
  name: string;
  state: string;
  city: string;
  campus: string;
  path: string; // e.g., "California/Merced/UC_Merced"
  created_at: Date;
  created_by: string;
}

export interface User {
  id: string;
  name: string;
  email: string;
  userType: 'mentor' | 'mentee' | 'coordinator';
  student_id?: string;
  mentor?: string;
  mentee?: string[];
  acknowledgment_signed: 'yes' | 'no' | 'not_applicable';
  department?: string;
  year_major?: string;
  created_at: Date;
}

export interface Meeting {
  id: string;
  mentor_id: string;
  mentee_id: string;
  start_time: string;
  end_time?: string;
  topic?: string;
  location?: string;
  status: 'pending' | 'accepted' | 'rejected' | 'cancelled';
  availability_id?: string;
  created_at: Date;
}

export interface Message {
  id: string;
  chat_id: string;
  sender_id: string;
  message: string;
  sent_at: Date;
}

export interface Announcement {
  id: string;
  title: string;
  content: string;
  time: string;
  priority: 'high' | 'medium' | 'low' | 'none';
  target_audience: 'mentors' | 'mentees' | 'both';
  created_at: Date;
  created_by: string;
}

export interface ProgressReport {
  id: string;
  mentee_id: string;
  mentor_id: string;
  report_period: string;
  status: 'draft' | 'submitted' | 'reviewed' | 'approved';
  overall_score?: number;
  submission_date?: Date;
  review_date?: Date;
  created_at: Date;
}

export interface AuthContext {
  uid: string;
  email?: string;
  role?: string;
  university_path?: string;
}

export interface DatabaseResult<T> {
  success: boolean;
  data?: T;
  error?: string;
  message?: string;
}