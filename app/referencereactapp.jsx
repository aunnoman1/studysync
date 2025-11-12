import React, { useState } from "react";

// Main App Component
export default function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [activeTab, setActiveTab] = useState("dashboard");
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [editingNote, setEditingNote] = useState(null); // null, 'new', or a note object

  if (!isAuthenticated) {
    return <AuthPage onLogin={() => setIsAuthenticated(true)} />;
  }

  const handleEditNote = (note) => {
    setEditingNote(note);
    setActiveTab("my-notes"); // Switch to the notes tab if not already there
  };

  const handleCloseEditor = () => {
    setEditingNote(null);
  };

  const renderContent = () => {
    if (activeTab === "my-notes" && editingNote) {
      return <NoteEditor note={editingNote} onBack={handleCloseEditor} />;
    }

    switch (activeTab) {
      case "dashboard":
        return <Dashboard />;
      case "my-notes":
        return <MyNotes onEditNote={handleEditNote} />;
      case "ai-tutor":
        return <AITutor />;
      case "community":
        return <CommunityForums />;
      case "profile":
        return <Profile />;
      default:
        return <Dashboard />;
    }
  };

  return (
    <div className="relative min-h-screen md:flex bg-gray-900 text-gray-200 font-sans">
      {/* Mobile menu overlay */}
      <div
        className={`fixed inset-0 bg-black bg-opacity-50 z-30 md:hidden ${
          isMenuOpen ? "block" : "hidden"
        }`}
        onClick={() => setIsMenuOpen(false)}
      ></div>

      <Sidebar
        activeTab={activeTab}
        setActiveTab={setActiveTab}
        isMenuOpen={isMenuOpen}
        setIsMenuOpen={setIsMenuOpen}
      />

      <main className="flex-1 p-4 md:p-8 overflow-y-auto">
        {/* Mobile Header */}
        <header className="md:hidden flex justify-between items-center mb-6">
          <h1 className="text-2xl font-bold text-blue-400">StudySync</h1>
          <button onClick={() => setIsMenuOpen(true)}>
            <MenuIcon />
          </button>
        </header>
        {renderContent()}
      </main>
    </div>
  );
}

// Authentication Page Component
const AuthPage = ({ onLogin }) => {
  const [isLoginView, setIsLoginView] = useState(true);

  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-900 p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-blue-400">StudySync</h1>
          <p className="text-gray-400">Your AI-powered study partner.</p>
        </div>
        <div className="bg-gray-800 p-8 rounded-lg shadow-lg">
          {isLoginView ? (
            <LoginForm onLogin={onLogin} />
          ) : (
            <RegisterForm onLogin={onLogin} />
          )}
          <p className="text-center text-gray-400 mt-6">
            {isLoginView
              ? "Don't have an account? "
              : "Already have an account? "}
            <button
              onClick={() => setIsLoginView(!isLoginView)}
              className="text-blue-400 hover:underline font-semibold"
            >
              {isLoginView ? "Register" : "Login"}
            </button>
          </p>
        </div>
      </div>
    </div>
  );
};

// Login Form
const LoginForm = ({ onLogin }) => (
  <form
    onSubmit={(e) => {
      e.preventDefault();
      onLogin();
    }}
  >
    <h2 className="text-2xl font-bold text-white text-center mb-6">Login</h2>
    <div className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-gray-300 mb-1">
          Student ID or Email
        </label>
        <input
          type="email"
          defaultValue="22L-6573@lhr.nu.edu.pk"
          className="w-full p-3 bg-gray-700 border border-gray-600 rounded-lg text-white"
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-300 mb-1">
          Password
        </label>
        <input
          type="password"
          defaultValue="password"
          className="w-full p-3 bg-gray-700 border border-gray-600 rounded-lg text-white"
        />
      </div>
    </div>
    <button
      type="submit"
      className="w-full mt-6 bg-blue-600 text-white p-3 rounded-lg font-semibold hover:bg-blue-700 transition"
    >
      Login
    </button>
  </form>
);

// Registration Form
const RegisterForm = ({ onLogin }) => (
  <form
    onSubmit={(e) => {
      e.preventDefault();
      onLogin();
    }}
  >
    <h2 className="text-2xl font-bold text-white text-center mb-6">
      Create Account
    </h2>
    <div className="space-y-4">
      <div>
        <label className="block text-sm font-medium text-gray-300 mb-1">
          Full Name
        </label>
        <input
          type="text"
          placeholder="e.g., Mahad Farhan Khan"
          className="w-full p-3 bg-gray-700 border border-gray-600 rounded-lg text-white"
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-300 mb-1">
          Student ID
        </label>
        <input
          type="text"
          placeholder="e.g., 22L-6589"
          className="w-full p-3 bg-gray-700 border border-gray-600 rounded-lg text-white"
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-300 mb-1">
          Email
        </label>
        <input
          type="email"
          placeholder="e.g., 22L-6589@lhr.nu.edu.pk"
          className="w-full p-3 bg-gray-700 border border-gray-600 rounded-lg text-white"
        />
      </div>
      <div>
        <label className="block text-sm font-medium text-gray-300 mb-1">
          Password
        </label>
        <input
          type="password"
          placeholder="••••••••"
          className="w-full p-3 bg-gray-700 border border-gray-600 rounded-lg text-white"
        />
      </div>
    </div>
    <button
      type="submit"
      className="w-full mt-6 bg-blue-600 text-white p-3 rounded-lg font-semibold hover:bg-blue-700 transition"
    >
      Register
    </button>
  </form>
);

// Sidebar Navigation
const Sidebar = ({ activeTab, setActiveTab, isMenuOpen, setIsMenuOpen }) => {
  const navItems = [
    { id: "dashboard", label: "Dashboard", icon: <HomeIcon /> },
    { id: "my-notes", label: "My Notes", icon: <NotesIcon /> },
    { id: "ai-tutor", label: "AI Tutor", icon: <TutorIcon /> },
    { id: "community", label: "Community", icon: <CommunityIcon /> },
    { id: "profile", label: "Profile", icon: <ProfileIcon /> },
  ];

  const handleNavClick = (tabId) => {
    setActiveTab(tabId);
    setIsMenuOpen(false); // Close menu on navigation
  };

  return (
    <aside
      className={`fixed inset-y-0 left-0 bg-gray-800 w-64 flex flex-col transform ${
        isMenuOpen ? "translate-x-0" : "-translate-x-full"
      } md:relative md:translate-x-0 transition-transform duration-300 ease-in-out z-40`}
    >
      <div className="flex items-center justify-between p-6">
        <h1 className="text-2xl font-bold text-blue-400">StudySync</h1>
        <button className="md:hidden" onClick={() => setIsMenuOpen(false)}>
          <CloseIcon />
        </button>
      </div>
      <nav className="flex-1 px-4">
        <ul>
          {navItems.map((item) => (
            <li key={item.id}>
              <a
                href="#"
                onClick={() => handleNavClick(item.id)}
                className={`flex items-center p-3 my-2 rounded-lg transition-colors ${
                  activeTab === item.id
                    ? "bg-blue-600 text-white"
                    : "text-gray-300 hover:bg-gray-700"
                }`}
              >
                {item.icon}
                <span className="ml-4">{item.label}</span>
              </a>
            </li>
          ))}
        </ul>
      </nav>
      <div className="p-4">
        <button className="w-full bg-blue-600 text-white p-3 rounded-lg flex items-center justify-center hover:bg-blue-700">
          <UploadIcon />
          <span className="ml-2">Upload Notes</span>
        </button>
      </div>
    </aside>
  );
};

// Dashboard Component
const Dashboard = () => (
  <div>
    <h1 className="text-3xl font-bold text-gray-100 mb-6">Dashboard</h1>
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      <div className="bg-gray-800 p-6 rounded-lg shadow-lg">
        <h2 className="text-xl font-semibold text-gray-200 mb-4">
          Recent Notes
        </h2>
        <ul>
          <li className="mb-2 p-2 rounded-md hover:bg-gray-700 cursor-pointer">
            Data Structures - Lecture 3
          </li>
          <li className="mb-2 p-2 rounded-md hover:bg-gray-700 cursor-pointer">
            OOP Concepts
          </li>
          <li className="mb-2 p-2 rounded-md hover:bg-gray-700 cursor-pointer">
            Database Schema Design
          </li>
        </ul>
      </div>
      <div className="bg-gray-800 p-6 rounded-lg shadow-lg">
        <h2 className="text-xl font-semibold text-gray-200 mb-4">
          AI Tutor Quick Access
        </h2>
        <p className="text-gray-400 mb-4">
          Ask a question about your recent notes:
        </p>
        <input
          type="text"
          placeholder="E.g., Explain polymorphism in OOP"
          className="w-full p-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
        />
      </div>
      <div className="bg-gray-800 p-6 rounded-lg shadow-lg">
        <h2 className="text-xl font-semibold text-gray-200 mb-4">
          Community Activity
        </h2>
        <p className="text-gray-400">
          New post in "DSA Helpers": "How to implement a binary search tree?"
        </p>
      </div>
    </div>
  </div>
);

// My Notes Component
const MyNotes = ({ onEditNote }) => {
  const notes = [
    {
      id: 1,
      title: "Data Structures",
      course: "CS201",
      date: "2023-10-26",
      content:
        "A data structure is a particular way of organizing data in a computer so that it can be used effectively. Common examples include arrays, linked lists, stacks, queues, trees, and graphs.",
    },
    {
      id: 2,
      title: "Object-Oriented Programming",
      course: "CS101",
      date: "2023-10-24",
      content:
        'OOP is a programming paradigm based on the concept of "objects", which can contain data and code. The main principles are encapsulation, inheritance, and polymorphism.',
    },
    {
      id: 3,
      title: "Database Systems",
      course: "CS305",
      date: "2023-10-22",
      content:
        "A database is an organized collection of structured information, or data. Relational databases model data in tables. SQL is used to query this data.",
    },
  ];

  return (
    <div>
      <h1 className="text-3xl font-bold text-gray-100 mb-6">My Notes</h1>
      <div className="bg-gray-800 p-6 rounded-lg shadow-lg">
        <div className="flex flex-col md:flex-row justify-between md:items-center mb-4 gap-4">
          <h2 className="text-xl font-semibold text-gray-200">All Notes</h2>
          <button
            onClick={() => onEditNote("new")}
            className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700 w-full md:w-auto"
          >
            Add New
          </button>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-left">
            <thead>
              <tr className="border-b border-gray-700">
                <th className="p-2">Title</th>
                <th className="p-2">Course</th>
                <th className="p-2">Date</th>
              </tr>
            </thead>
            <tbody>
              {notes.map((note) => (
                <tr
                  key={note.id}
                  className="border-b border-gray-700 hover:bg-gray-700 cursor-pointer"
                  onClick={() => onEditNote(note)}
                >
                  <td className="p-2 whitespace-nowrap">{note.title}</td>
                  <td className="p-2">{note.course}</td>
                  <td className="p-2">{note.date}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};

// Note Editor Component
const NoteEditor = ({ note, onBack }) => {
  const isNewNote = note === "new";
  const [title, setTitle] = useState(isNewNote ? "" : note.title);
  const [course, setCourse] = useState(isNewNote ? "" : note.course);
  const [content, setContent] = useState(isNewNote ? "" : note.content);

  return (
    <div>
      <div className="flex items-center mb-6">
        <button
          onClick={onBack}
          className="mr-4 p-2 rounded-full hover:bg-gray-700"
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            className="h-6 w-6"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M10 19l-7-7m0 0l7-7m-7 7h18"
            />
          </svg>
        </button>
        <h1 className="text-3xl font-bold text-gray-100">
          {isNewNote ? "Create New Note" : "Edit Note"}
        </h1>
      </div>
      <div className="bg-gray-800 p-6 rounded-lg shadow-lg">
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-4">
          <input
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="Note Title"
            className="w-full p-3 bg-gray-700 border border-gray-600 rounded-lg text-white"
          />
          <input
            type="text"
            value={course}
            onChange={(e) => setCourse(e.target.value)}
            placeholder="Course Code (e.g., CS201)"
            className="w-full p-3 bg-gray-700 border border-gray-600 rounded-lg text-white"
          />
        </div>
        <textarea
          value={content}
          onChange={(e) => setContent(e.target.value)}
          placeholder="Start typing your digitized note here..."
          className="w-full h-96 p-3 bg-gray-700 border border-gray-600 rounded-lg text-white resize-none"
        ></textarea>
        <div className="flex justify-end mt-4">
          <button
            onClick={onBack}
            className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700"
          >
            Save
          </button>
        </div>
      </div>
    </div>
  );
};

// AI Tutor Component
const AITutor = () => (
  <div>
    <h1 className="text-3xl font-bold text-gray-100 mb-6">AI Tutor</h1>
    <div className="bg-gray-800 p-4 md:p-6 rounded-lg shadow-lg max-w-4xl mx-auto">
      <div className="flex flex-col h-[70vh] md:h-[60vh]">
        <div className="flex-1 overflow-y-auto p-4 bg-black/20 rounded-lg">
          {/* Chat messages */}
          <div className="mb-4">
            <p className="font-bold text-blue-400">StudySync AI</p>
            <p className="bg-gray-700 p-3 rounded-lg inline-block">
              Hello! How can I help you study today? Ask me anything about your
              notes.
            </p>
          </div>
          <div className="mb-4 text-right">
            <p className="font-bold text-gray-300">You</p>
            <p className="bg-blue-600 text-white p-3 rounded-lg inline-block">
              Explain the concept of inheritance in OOP based on my notes.
            </p>
          </div>
          <div className="mb-4">
            <p className="font-bold text-blue-400">StudySync AI</p>
            <p className="bg-gray-700 p-3 rounded-lg inline-block">
              Of course. In your notes on Object-Oriented Programming, you've
              written that inheritance allows a class to acquire the properties
              and behavior of another class. For example, a 'Car' class can
              inherit from a 'Vehicle' class, gaining attributes like 'speed'
              and 'color'. This promotes code reusability.
            </p>
          </div>
        </div>
        <div className="mt-4 flex">
          <input
            type="text"
            placeholder="Ask a question..."
            className="flex-1 p-3 bg-gray-700 border border-gray-600 rounded-l-lg text-white focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
          <button className="bg-blue-600 text-white px-6 py-3 rounded-r-lg hover:bg-blue-700">
            Send
          </button>
        </div>
      </div>
    </div>
  </div>
);

// Community Forums Component
const CommunityForums = () => (
  <div>
    <h1 className="text-3xl font-bold text-gray-100 mb-6">Community Forums</h1>
    <div className="bg-gray-800 p-6 rounded-lg shadow-lg">
      <div className="flex flex-col md:flex-row gap-4 mb-6">
        <input
          type="text"
          placeholder="Search forums..."
          className="flex-1 p-2 bg-gray-700 border border-gray-600 rounded-lg text-white"
        />
        <div className="flex gap-4">
          <select className="flex-1 p-2 bg-gray-700 border border-gray-600 rounded-lg text-white">
            <option>All</option>
            <option>PF</option>
            <option>OOP</option>
            <option>DSA</option>
            <option>DB</option>
          </select>
          <button className="bg-blue-600 text-white px-4 py-2 rounded-lg hover:bg-blue-700">
            New Post
          </button>
        </div>
      </div>

      <div className="space-y-4">
        <div className="p-4 border border-gray-700 rounded-lg hover:bg-gray-700/50 transition-colors">
          <h3 className="font-semibold text-lg text-blue-400">
            Can someone explain Big O notation for DSA?
          </h3>
          <p className="text-sm text-gray-400">
            Posted by Aun Noman in <span className="font-medium">DSA</span> - 2
            hours ago
          </p>
          <p className="mt-2 text-gray-300">
            I'm having trouble understanding how to calculate time complexity.
            My notes are a bit confusing.
          </p>
          <div className="mt-3 text-sm text-gray-500">
            <span>5 replies</span> | <span>2 helpful</span>
          </div>
        </div>
        <div className="p-4 border border-gray-700 rounded-lg hover:bg-gray-700/50 transition-colors">
          <h3 className="font-semibold text-lg text-blue-400">
            Sharing my notes on OOP Polymorphism
          </h3>
          <p className="text-sm text-gray-400">
            Posted by Mahad Farhan Khan in{" "}
            <span className="font-medium">OOP</span> - 1 day ago
          </p>
          <p className="mt-2 text-gray-300">
            Hey everyone, here are my digitized notes on polymorphism. Hope it
            helps someone!
          </p>
          <div className="mt-3 text-sm text-gray-500">
            <span>12 replies</span> | <span>8 helpful</span>
          </div>
        </div>
      </div>
    </div>
  </div>
);

// Profile Component
const Profile = () => (
  <div>
    <h1 className="text-3xl font-bold text-gray-100 mb-6">Profile</h1>
    <div className="bg-gray-800 p-8 rounded-lg shadow-lg max-w-2xl mx-auto">
      <div className="flex flex-col items-center text-center md:flex-row md:text-left md:items-center space-y-4 md:space-y-0 md:space-x-6">
        <div className="w-24 h-24 bg-gray-700 rounded-full flex-shrink-0"></div>
        <div>
          <h2 className="text-2xl font-bold text-white">Muhammad Rohaim</h2>
          <p className="text-gray-400">22L-6573</p>
        </div>
      </div>
      <div className="mt-8">
        <h3 className="text-xl font-semibold mb-4 text-gray-200">
          Account Details
        </h3>
        <div className="space-y-3 text-gray-300">
          <p>
            <strong>Email:</strong> 22L-6573@lhr.nu.edu.pk
          </p>
          <p>
            <strong>University:</strong> National University of Computer and
            Emerging Sciences
          </p>
          <p>
            <strong>Courses Enrolled:</strong> PF, OOP, DSA, DB
          </p>
        </div>
      </div>
    </div>
  </div>
);

// SVG Icons - These will inherit color via `currentColor`
const HomeIcon = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    className="h-6 w-6"
    fill="none"
    viewBox="0 0 24 24"
    stroke="currentColor"
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={2}
      d="M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6"
    />
  </svg>
);
const NotesIcon = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    className="h-6 w-6"
    fill="none"
    viewBox="0 0 24 24"
    stroke="currentColor"
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={2}
      d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01"
    />
  </svg>
);
const TutorIcon = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    className="h-6 w-6"
    fill="none"
    viewBox="0 0 24 24"
    stroke="currentColor"
  >
    <path d="M12 14l9-5-9-5-9 5 9 5z" />
    <path d="M12 14l6.16-3.422a12.083 12.083 0 01.665 6.479A11.952 11.952 0 0012 20.055a11.952 11.952 0 00-6.824-9.998 12.078 12.078 0 01.665-6.479L12 14z" />
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={2}
      d="M12 14l9-5-9-5-9 5 9 5zm0 0v6"
    />
  </svg>
);
const CommunityIcon = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    className="h-6 w-6"
    fill="none"
    viewBox="0 0 24 24"
    stroke="currentColor"
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={2}
      d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z"
    />
  </svg>
);
const ProfileIcon = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    className="h-6 w-6"
    fill="none"
    viewBox="0 0 24 24"
    stroke="currentColor"
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={2}
      d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
    />
  </svg>
);
const UploadIcon = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    className="h-6 w-6"
    fill="none"
    viewBox="0 0 24 24"
    stroke="currentColor"
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={2}
      d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12"
    />
  </svg>
);
const MenuIcon = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    className="h-6 w-6"
    fill="none"
    viewBox="0 0 24 24"
    stroke="currentColor"
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={2}
      d="M4 6h16M4 12h16m-7 6h7"
    />
  </svg>
);
const CloseIcon = () => (
  <svg
    xmlns="http://www.w3.org/2000/svg"
    className="h-6 w-6"
    fill="none"
    viewBox="0 0 24 24"
    stroke="currentColor"
  >
    <path
      strokeLinecap="round"
      strokeLinejoin="round"
      strokeWidth={2}
      d="M6 18L18 6M6 6l12 12"
    />
  </svg>
);
