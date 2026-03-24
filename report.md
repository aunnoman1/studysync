#### National University of Computer and Emerging Sciences, Lahore

StudySync

```
Muhammad Rohaim 22L-6573 BS(CS)
Aun Noman 22L-6950 BS(CS)
Mahad Farhan Khan 22L-6589 BS(CS)
```
```
Supervisor: Dr. Saira Karim
```
```
Final Year Project
```
#### November 24, 2025


### Anti-Plagiarism Declaration

This is to declare that the above publication was produced under the:

Title: StudySync

is the sole contribution of the author(s), and no part hereof has been reproduced as it is the basis (cut
and paste) that can be considered Plagiarism. All referenced parts have been used to argue the idea and
cited properly. I/We will be responsible and liable for any consequence if a violation of this declaration
is determined.

Date: November 24, 2025

```
Name: Muhammad Rohaim
```
```
Signature:
```
```
Name: Aun Noman
```
```
Signature:
```
```
Name: Mahad Farhan Khan
```
```
Signature:
```

### Author’s Declaration

This states Authors’ declaration that the work presented in the report is their own, and has not been
submitted/presented previously to any other institution or organization.


### Abstract

StudySync is an AI-based study partner app that enables students to digitize, organize and learn from
their handwritten notes. It applies Optical Character Recognition (OCR) to read handwritten notes and
convert them into a searchable digital form and adds a Large Language Model (LLM) with Retrieval-
Augmented Generation (RAG) to provide intelligent and context-driven support. It also includes com-
munity threads in which students are able to post questions and give insights. StudySync makes the
learning process more approachable and efficient by implementing a combination of digitalizing notes,
utilizing AI to aid in learning, and allowing learners to communicate with each other.


### Executive Summary

Storage and retrieval of handwritten notes is a great challenge to students who in most cases find it hard
to organize and search their own notes and to extract meaningful knowledge. Conventional digital note
taking programs have organizational advantages but are not as smart, interactive and collaborative as
a truly modern and effective learning experience. Our Final Year Project, StudySync, is an attempt to
fill this gap by creating an innovative, AI-enhanced, study partner that can help revolutionize the whole
learning process, both in terms of note-taking to in-depth conceptual learning and collaborating with
peers.

StudySync is an integrated system based on three pillars. The first is Notes Digitization that utilizes
the latest Optical Character Recognition (OCR) technology to smartly and precisely scan and transform
the handwritten notes of the students into a fully searchable and editable digital text. This fundamental
service frees the students of the limitations of physical notebooks and makes their learning content
readily available and easily manageable.

The second and the most innovative pillar is the AI-Powered Tutor. Using a powerful Large Language
Model (LLM) that is augmented with Retrieval-Augmented Generation (RAG) pipeline, StudySync is
a student-focused, context-sensitive, and personal learning assistant. The AI tutor, by generating a set
of vectors of the digitized notes and other useful academic textbooks, can respond to inquiries with
particularity, offer detailed explanation and examples, which are directly associated with the personal
coursework of the user. The scope of AI tutor is narrowed down to foundational computer science
courses, such as Programming Fundamentals (PF), Object-Oriented Programming (OOP), Data Struc-
tures and Algorithms (DSA), and Databases (DB), which provides the opportunity to offer targeted and
relevant academic support.

The third pillar is Community-Based Learning. StudySync combines a collaborative environment in
which students will be able to form discussion threads, ask questions, exchange their digitized notes,
and give feedback to their peers. This aspect creates a healthy learning atmosphere that does not replace
the AI tutor but augments it with the priceless insights of human partnership and collective knowledge.

The system is built with a modern and scalable technology stack. The cross-platform app interface is
developed on Flutter, guaranteeing the same experience on web, mobile, and desktop devices. FastAPI
(Python) is used as the backend, and it provides a high-performance API gateway to handle user request
and coordinate services. The information, user data, and notes are stored in a PostgreSQL database using
the pgvector extension to search the data semantically effectively by vectors. The AI layer makes use of
platforms such as Hugging Face models and is organized with the help of LangChain. It has a modular,


containerized architecture that is based on Docker, which is scalable and maintainable to deploy into a
cloud.

StudySync will help to improve accessibility, efficiency, and engagement in learning in accordance with
the UN Sustainable Development Goal 4 (Quality Education). The project offers an effective tool to
individual students, but also it is a good business opportunity in a growing EdTech market. Incorporating
the digitization of notes, smart AI help, and collaborative learning into one, unified platform, StudySync
proposes a solution that is distinctive and powerful and fills the gap between the way people used to
learn traditionally and what modern technology can present.


## TABLE OF CONTENTS vi

# Table of Contents

List of Figures ix




LIST OF FIGURES ix


LIST OF TABLES x

- 1 Introduction List of Tables x
   - 1.1 Purpose of this Document
   - 1.2 Intended Audience
   - 1.3 Definitions, Acronyms, and Abbreviations
   - 1.4 Conclusion
- 2 Project Vision
   - 2.1 Problem Domain Overview
   - 2.2 Problem Statement
   - 2.3 Problem Elaboration
   - 2.4 Goals and Objectives
   - 2.5 Project Scope
   - 2.6 Sustainable Development Goal (SDG)
   - 2.7 Constraints
   - 2.8 Business Opportunity
   - 2.9 Stakeholders Description/ User Characteristics
      - 2.9.1 Stakeholders Summary
      - 2.9.2 Key High-Level Goals and Problems of Stakeholders
   - 2.10 Conclusion
- 3 Literature Review / Related Work
   - 3.1 Definitions, Acronyms, and Abbreviations
   - 3.2 Detailed Literature Review
      - 3.2.1 Digital Note-Taking and OCR Applications
      - 3.2.2 AI-Driven Learning Aids
      - 3.2.3 Community-Based Learning Platforms TABLE OF CONTENTS vii
   - 3.3 Related Work Summary Table
   - 3.4 Conclusion
- 4 Software Requirement Specifications
   - 4.1 List of Features
   - 4.2 Functional Requirements
   - 4.3 Quality Attributes
   - 4.4 Non-Functional Requirements
   - 4.5 Assumptions
   - 4.6 Use Cases
   - 4.7 Hardware and Software Requirements
      - 4.7.1 Hardware Requirements
      - 4.7.2 Software Requirements
   - 4.8 Graphical User Interface
   - 4.9 Database Design
      - 4.9.1 ER Diagram
      - 4.9.2 Data Dictionary
   - 4.10 Risk Analysis
      - 4.10.1 Technical Risks
      - 4.10.2 User Adoption and Engagement Risks
   - 4.11 Conclusion
- 5 High-Level and Low-Level Design
   - 5.1 System Overview
      - 5.1.1 OCR and Notes Digitization
      - 5.1.2 AI Assistant and Intelligent Search
      - 5.1.3 Community Threads
   - 5.2 Design Considerations
      - 5.2.1 Assumptions and Dependencies
      - 5.2.2 General Constraints
      - 5.2.3 Goals and Guidelines
      - 5.2.4 Development Methods
   - 5.3 System Architecture
      - 5.3.1 Subsystem Architecture
   - 5.4 Architectural Strategies TABLE OF CONTENTS viii
      - 5.4.1 Modular and Layered Architecture
      - 5.4.2 Cloud-Based Processing and Data Management
      - 5.4.3 Technology and Framework Selection
      - 5.4.4 API-Driven Communication
   - 5.5 Domain Model/Class Diagram
      - 5.5.1 Server
      - 5.5.2 Client
   - 5.6 Policies and Tactics
      - 5.6.1 Coding Standards and Conventions
      - 5.6.2 Selection of Framework and Technology
      - 5.6.3 Testing and Version Control
      - 5.6.4 Deployment and Maintenance
   - 5.7 Conclusion
- 6 Implementation and Test Cases
   - 6.1 Implementation
      - 6.1.1 Frontend Prototype
      - 6.1.2 Authentication
      - 6.1.3 Backend: API Gateway and AI Pipeline
   - 6.2 Conclusion
- 7 Conclusions
- 2.1 Quality Education List of Figures
- 4.1 Login Screen
- 4.2 Registration Screen
- 4.3 Dashboard Screen
- 4.4 Notes Screen
- 4.5 Notes Editing Screen
- 4.6 AI tutor Screen
- 4.7 Community Screen
- 4.8 Profile Screen
- 4.9 Server Entity Relationship Diagram
- 4.10 Client Entity Relationship Diagram
- 5.1 Architecture Diagram of StudySync
- 5.2 Server Domain Model/Class Diagram
- 5.3 Client Domain Model/Class Diagram
- 3.1 Summary of Related Work Review List of Tables
- 4.1 Use Case 1: User Authentication
- 4.2 Use Case 2: Digitizing Notes
- 4.3 Use Case 3: Review Notes
- 4.4 Use Case 4: Retrieve Contextual Information
- 4.5 Use Case 5: Receive AI-Powered Tutoring
- 4.6 Use Case 6: Share Notes
- 4.7 Use Case 7: Create Discussion Thread
- 4.8 Use Case 8: Reply to Thread
- 4.9 User Table Schema
- 4.10 Course Table Schema
- 4.11 Thread Table Schema
- 4.12 Comment Table Schema
- 4.13 Thread Attachment Table Schema
- 4.14 Course Book Embedding Table Schema
- 4.15 Note Record Table Schema
- 4.16 Note Image Table Schema
- 4.17 OCR Block Table Schema
- 4.18 Text Chunk Table Schema


##### CHAPTER 1. INTRODUCTION 1

### Chapter 1 Introduction

Students tend to use handwritten notes to study, but it can be challenging to find certain information and
manage them. Current digital note-taking tools are useful in organizing but they are not intelligent in
search and collaborative qualities that enable learning more.

In order to resolve these concerns, our project, StudySync, provides an AI-based study partner applica-
tion. It transfers handwritten written notes into searchable digital text with the help of OCR technology
and offers context-aware answers and explanations using an LLM with Retrieval-Augmented Genera-
tion (RAG). Student-to-student interaction through community discussion threads is also available in the
platform whereby students have access to notes and can pose questions and collaborate with others.

StudySync is expected to make the entire learning process more productive and, therefore, interesting
by incorporating the digitization of notes, the use of AI, and collaboration with peers.

### 1.1 Purpose of this Document

This document is meant to provide the design, creation and testing of our Final Year Project, StudySync,
an artificial intelligence-driven note taking and study assistant application. The project is expected to
assist the students in digitizing their handwritten notes, arranging them effectively, and learn through the
smart search and the AI-based tutoring.

In this report, the goals and objectives of the project will be described, as well as the technologies
and methods that will be employed in the project, including Optical Character Recognition (OCR),
Large Language Models (LLM), and Retrieval-Augmented Generation (RAG), and the ways they will
be applied to improve the study habits and information accessibility of students.

The background and the design of the system, implementation, testing and the results of the system,
limitations and future improvement of the system will be discussed in this document.

### 1.2 Intended Audience

The prospective audience of this document is mainly the academic evaluation panel which is com-
posed of professors and examiners who will review the design, implementation and effectiveness of the
StudySync project. The report can also be applied by students and researchers who may be interested in
learning the integration of AI and NLP technologies into educational tools.

Moreover, this document can be used by individuals or developers who want to get an idea of how
AI-based note-taking and learning systems could be developed and improved in terms of the system


##### CHAPTER 1. INTRODUCTION 2

workflow, architecture, and technical methodology.

### 1.3 Definitions, Acronyms, and Abbreviations

List all important definitions, acronyms, and abbreviations used in this document. For example: SDG:
Sustainable Development Goal
FYP: Final Year Project
MVP: Minimum Viable Product
UI: User Interface
UX: User Experience
Agile: Agile Development
SCRUM: Scrum Development
REST: Representational State Transfer
ORM: Object-Relational Mapping
CRUD: Create, Read, Update, Delete
API: Application Programming Interface
AI: Artificial Intelligence
DSA: Data Structures and Algorithms
LLM: Large Language Model
OCR: Optical Character Recognition
OOP: Object-Oriented Programming
PF: Programming Fundamentals
DB: Database
RAG: Retrieval-Augmented Generation

### 1.4 Conclusion

This report provides a comprehensive overview of the StudySync project. Chapter 2 details the project’s
vision, including the problem statement, goals, and scope. Chapter 3 presents a thorough literature
review of related digital note-taking applications, AI-driven learning aids, and community-based plat-
forms. Chapter 4 outlines the software requirement specifications, covering functional requirements, use
cases, database design, and risk analysis. Finally, Chapter 5 elaborates on the high-level and low-level
design, detailing the system architecture, design considerations, and development strategies employed.


##### CHAPTER 2. PROJECT VISION 3

### Chapter 2 Project Vision

This chapter will provide an overview of the project problem domain, the project statement and its
elaboration, the goals and objectives, and the scope of the project.

### 2.1 Problem Domain Overview

Note-taking is a major component of the learning process in the modern world of academia. Even though
digital tools are now common, traditional handwriting is still favored by most students due to the well-
established cognitive advantages of memorization and conceptualization. Nonetheless, this conventional
approach has major flaws in the today’s tech-based academic world. Physical notes are also not easy
to arrange, locate, and exchange. They are prone to destruction or loss and not dynamic like digital
notes. This forms a disconnect wherein the students who find it more advantageous to write by hand
cannot take advantage of the substantial search, collaboration and intelligent analysis capabilities that
the current technology offers and are thus disadvantaged.

### 2.2 Problem Statement

The physical nature of handwritten notes creates critical inefficiencies in the student learning process.
The content of the notes can not be dynamically edited, retrieving information is difficult and time-
consuming to retrieve, and collaboration with others is inconvenient, ultimately limiting the notes’ po-
tential as an effective study tool.

### 2.3 Problem Elaboration

The problem can be divided into a number of specific issues students face. To begin with, there is the
problem of poor information retrieval. During a semester, a student can produce hundreds of pages of
notes. Finding a particular definition, formula, or concept after a while is a very time-consuming process
as it involves flipping through pages upon pages of text in physical notebooks which hinders efficient
learning.

Secondly, the handwritten notes are unresponsive and non-interactive. They are a passive source of in-
formation. Students are not able to challenge their notes to seek clarification, to have easier explanations
of difficult questions, and to automatically recognize important words in their personal work. This does
not provide an interactive learning loop and thus the chance to learn more is lost.

Lastly, these notes are physical in nature which means sharing notes can be tedious as students are forced


##### CHAPTER 2. PROJECT VISION 4

to type or take snapshots of their notes to provide them to the rest of the students. Furthermore, there is
no simple and smooth process of organizing group discussions or providing peer-to-peer support.

### 2.4 Goals and Objectives

The goal of study sync is to make an AI-driven note taking app which will make students’ learning
process more efficient and productive, while also help them store and navigate their notes more easily.

The project’s objectives include:

- Converting handwritten notes into accurate digital text using OCR
- Enabling intelligent search and retrieval of information through a RAG-based LLM
- Providing an AI tutor focused on programming courses (PF, OOP, DSA, DB)
- Allowing users to share notes, ask questions, and interact through community threads

### 2.5 Project Scope

The aim of StudySync is to create an AI-driven note taking app that will scan handwritten notes and
convert them into digital form using AI OCR models. This will enable the app to provide assistance with
what the student is currently studying in their course (currently only Computer Science related courses,
such as PF, OOP, DSA and DB etc.). The app will use AI optical character recognition (OCR) models
(such as Microsoft’s Kosmos model) to convert the notes to digital form. The app will use LLM with
Retrieval-Augmented Generation (RAG) which will have access to the student notes and programming
books (only PF, OOP, DSA, and DB books), hence allowing the LLM to search and retrieve information
from them. This will keep the LLM informed as to what the student is learning at this time and give
intelligent search capabilities to search through the students’ notes. This will also enable an AI tutor to be
added, which will be able to respond to the user queries by using the notes of the user and the textbook.
The project will also have a community section where students can post questions, answers and share
their notes with other students. The project will not seek to substitute the existing learning management
systems (LMS) or other complete e-learning platforms. Instead, it will enhance the learning process of
students by digitizing their notes, enhancing search capabilities, and offering AI-powered support based
on their personal academic requirements.


##### CHAPTER 2. PROJECT VISION 5

### 2.6 Sustainable Development Goal (SDG)

The StudySync project is also in line with the Sustainable Development Goal of ’Quality Education’
which aims at guaranteeing inclusive and equitable education, and also encouraging lifelong learning
opportunities to everyone. StudySync provides students with a better opportunity to access, organize,
and understand their study material by incorporating artificial intelligence into the learning process.

The system allows the students to transform handwritten notes into digital and searchable materials and
offers AI-based support to ensure improved understanding and interaction. It also has a community
discussion option that enhances collaborative learning where students can contribute to knowledge and
also offer help to one another. In these aspects, StudySync helps in making quality education more
accessible, interactive, and personal to learners.

```
Figure 2.1: Quality Education
This figure represents the target Sustainable Development Goal for focused on Quality Education.
```
### 2.7 Constraints

StudySync is vulnerable to performance and accuracy limitations that could result in ineffectiveness.
The system needs to have good lighting and clear pictures of the handwritten notes that can be properly
processed by the OCR. Cloud-based OCR, LLM tasks and interactions with people also require a stable
internet connection. Also, OCR can be inaccurate depending on handwriting styles and this might affect
the quality of digitized text.

### 2.8 Business Opportunity

StudySync offers a good business prospect in the fast expanding edtech market. As more teachers and
students start using AI tools in education, the platform will be able to appeal to students and institutions
that want to find smarter methods of managing and comprehending study material.

With such high-value propositions as advanced AI tutoring, note storage in the clouds, and study groups,
StudySync can implement a freemium business model, with basic features being free and more advanced


##### CHAPTER 2. PROJECT VISION 6

tools being paid subscriptions. The study can also grow through partnership with educational institutions
and online learning platforms that can increase its accessibility and make StudySync a scalable and
sustainable business solution.

### 2.9 Stakeholders Description/ User Characteristics

This section determines the key stakeholders of the StudySync system and their purposes of the platform
along with their objectives and issues.

#### 2.9.1 Stakeholders Summary

- Students: The main consumers of StudySync who will be uploading handwritten notes, trans-
    lating it to digital searchable text, speaking with the AI helper, and engaging in discussions with
    others.
- Educators: Contribute in the community threads, responding to the questions of students, and
    leading the discussion to facilitate group learning.

#### 2.9.2 Key High-Level Goals and Problems of Stakeholders

2.9.2.1 Students

- Goals: Turn written notes into digital format, find study material easy, receive AI-based explana-
    tions, and connect with other people to study together.
- Problems: The inability to deal with handwritten notes easily, there are few methods to locate
    and process information, and there is a lack of a single study platform.

2.9.2.2 Educators

- Goals: Guide the students by answering questions and giving clarifications within the discussion
    forums.
- Problems: There is a shortage of the tools that can help reach the multitude of students and learn
    about the study materials that they share.

### 2.10 Conclusion

To sum up, our vision is to create a one stop application for the student to study from. The aim is to help
students and reduce context switching when studying new concepts and ideas.


##### CHAPTER 3. LITERATURE REVIEW / RELATED WORK 7

### Chapter 3 Literature Review / Related Work

This chapter gives the detailed overview of the existing applications and technologies related to the pro-
posed AI-based study-partner application, StudySync. The primary objective is to assess the currently
available resources for digital note-taking, the use of AI-driven learning solutions, and collaboration
and explore how our application provides a solution to the problems that the existing applications face.
We analyze these apps to identify what they do well and also what they struggle with when it comes to
providing a complete and interactive learning experience.

### 3.1 Definitions, Acronyms, and Abbreviations

- AI: Artificial Intelligence
- DSA: Data Structures and Algorithms
- LLM: Large Language Model
- OCR: Optical Character Recognition
- OOP: Object-Oriented Programming
- PF: Programming Fundamentals
- RAG: Retrieval-Augmented Generation

### 3.2 Detailed Literature Review

This section carefully evaluates existing work in areas related to StudySync. This review divides re-
lated work into three categories, digital note-taking and OCR applications, AI-driven learning aids, and
community-based learning platforms. The review is divided into three categories to first cover applica-
tions focused on note-taking and OCR, followed by platforms that leverage AI for tutoring and learning,
and finally tools that facilitate community-based knowledge sharing.

#### 3.2.1 Digital Note-Taking and OCR Applications

3.2.1.1 Evernote

Evernote [1] is an established app, which is a note-taking, organization, task management, and archiving
tool. It enables the users to make notes, which may be texts, drawings, pictures, or web content saved.
One of the features that are applicable to our project is that it supports Optical Character Recognition
(OCR) that enables text in pictures and in scanned documents to be searched. Users are able to take


##### CHAPTER 3. LITERATURE REVIEW / RELATED WORK 8

handwritten notes using the camera in their device, and the engine in Evernote is used to index the
text. It has been described as having an effective organization capability, such as notebooks, tags and
cross-platform synchronization, which have made it a favorite in personal and professional knowledge
management.

One of the strengths of Evernote is its powerful multi-platform ecosystem and feature set of general-
purpose organization. It has an OCR-based search functionality that gives it an underlying advantage
that StudySync will strive to achieve. The main weakness, though, is that it is a passive method of
learning. The OCR is indexed and searched, but not read and understood or interacted with. The
application does not analyze the text to give summaries or definitions and respond to questions using the
notes. Moreover, it does not have any built-in collaborative or community based capabilities to support
education.

Evernote is used as a baseline to the note digitization and organization aspect of StudySync. It confirms
the user’s need for searchable handwritten notes. The proposed work will take this idea much further
and not only make the notes searchable but also feed the digitized text into a RAG-based LLM. This will
allow semantic search, automatic term recognition, and an AI tutor that is aware of the personal study
material of the user and converts the notes from just written text to an interactive learning tool.

3.2.1.2 Goodnotes

Goodnotes [2] is an app used as a digital note-taking tool, especially on tablets, which is known to be
very successful in its attempts to recreate the feeling of writing on a paper. It gives the user the chance
to write, draw, and annotate documents with a high degree of accuracy by use of a stylus. Similar to
Evernote, Goodnotes has a built-in OCR that enables searching of the text written by hand within the
app. It has an organizational structure of virtual notebooks and folders, and this offers a familiar and
easy system to the students to manage their notes according to various courses. It is also compatible
with the import and annotation of PDFs, and this makes the app a powerhouse among the students who
deal with lecture notes and textbooks.

Goodnotes has a major advantage, the best handwriting experience with an easy-to-use interface, al-
lowing one to feel natural when taking notes on the computer. Its search is powered by OCR and is
correct and quick, which satisfies the minimum requirement of searching the information in a handwrit-
ten document. Its primary shortcoming, though, is that it is not an intelligent tool besides the search.
The application does not break down the text in the notes to help in learning. The ability to summarize
topics, create flashcards, or provide context-based help is absent. Nor does it have an inbuilt community
or sharing system so that the user has to export and share notes using external programs.


##### CHAPTER 3. LITERATURE REVIEW / RELATED WORK 9

Goodnotes is a great model for the user interface and handwriting capture component of StudySync.
The fact that it has been a successful product proves that high-quality user experience is essential to
digital note taking. StudySync will also incorporate this principle but will overcome its weaknesses
with the inclusion of an AI layer. Goodnotes stops at searching through handwritten text, but StudySync
will improve on this by processing that text to drive a RAG-based AI tutor and allowing sharing and
discussion of these notes on commmunity forums, thereby directly connecting the process of taking
notes with further learning and collaboration.

3.2.1.3 Microsoft OneNote

Microsoft OneNote [3] is a multifunctional digital note-taking program which is included in the larger
Microsoft office suite. It is characterized by its free-form, infinite canvas and gives the user the ability to
add text, handwritten notes, drawings, images, and other multimedia on any part of a page. This is similar
to a physical whiteboard or notebook. OneNote has a hierarchical arrangement of Notebooks, Sections,
and Pages that offer a powerful platform of handling complex information. Crucially for this project,
it includes an exceptional Optical Character Recognition (OCR) engine that automatically renders the
text in inserted images and PDF printouts searchable including handwritten text that is captured using
a stylus. It is an extremely popular tool among students and professionals due to its strong integration
with Windows operating system and cross-platform synchronization.

OneNote’s unmatched flexibility and the fact that it is free on all major platforms are one of the major
reasons for its popularity. Freestyle canvas accommodates a wide range of learning styles, including
both linear note-taking and mind-map visual learning. It has a very good OCR that works in the back-
ground and hence is a powerful tool in archiving and retrieving information. Nevertheless, the first major
weakness, similar to other applications in the same category, is that its smart features are not active but
passive and oriented to organization instead of active learning. The OCR feature ends with search in-
dexing; it does not process what is being read to give summaries, definitions or contextual response.
Although OneNote allows collaboration by sharing notebooks, this option is not intended to create a
wider community discussion and learning platform, but rather co-editing documents.

OneNote will be a powerful foundation of the organizational framework and multimedia functionality
of StudySync. The fact that it has succeeded justifies the necessity of having a powerful cross platform
system that can support different categories of notes. The suggested work however directly covers the
limitations of OneNote by creating an active intelligence layer over the underlying features of OneNote.
Whereas OneNote will enable finding the notes, StudySync will enable interactivity of the notes. The
OCR extracted text will be inputted into a dedicated RAG-based AI tutor, which offers domain-specific
support in programming courses- a higher level of academic specialization unavailable in the more


##### CHAPTER 3. LITERATURE REVIEW / RELATED WORK 10

general productivity-oriented AI of OneNote. Moreover, StudySync will also add a special community
option, which will turn the process of taking notes alone into a participatory learning process.

#### 3.2.2 AI-Driven Learning Aids

3.2.2.1 Quizlet

Quizlet [4] is a well-known Internet based learning tool, which enables a user to study information
through learning tools and games. It is most recognized due to its digital flashcards yet it has other study
options such as tests and matching games. Recently Quizlet has launched Q-Chat which is an AI based
tutor that interacts with students in an adaptive conversation, asks students questions about their learning
content and assists them in gaining a deeper knowledge of concepts. This AI tutor can be asked some
questions and allows the student to go through a Socratic-style learning process.

The most important strength of Quizlet is that it uses the active recall and spaced repetition techniques
successfully and makes the process of learning more like a game. Q-Chat has become a great milestone
to individualized AI-enhanced education, making the process of studying more interactive and adaptive.
Nevertheless, the main weakness of Quizlet is that it is a user-created or ready-made study set (flash-
cards). The AI is limited to these explicit sets and not to the unstructured and handwritten notes of a
user. It is not, for example, capable of taking a picture of lecture notes of a student and automatically
generating a learning session out of it.

The Q-Chat of Quizlet is the direct inspiration of the AI tutor of StudySync. It confirms the idea of ap-
plying a conversational AI to the learning process. StudySync is designed to eliminate the shortcomings
of Quizlet by linking the AI tutor to the knowledge base of the user: the digitized handwritten notes. The
StudySync AI tutor will be able to provide a student with very personalized and context-sensitive support
by relying on the user-specific notes and external academic sources (such as programming textbooks),
which will be based on the curriculum of the student.

3.2.2.2 Socratic by Google

Socratic [5] is an artificial intelligence (AI) based learning application that assists high school and uni-
versity students in their course work. Users snap a picture of a question, be it handwritten or in a
textbook and the app relies on Google’s AI to identify the most appropriate online materials to assist
them in learning the concept. It provides instructions, step-by-step problem solvers, videos and web
links to resolve the query. Its technology uses OCR to read the question and a web search engine to
search the web to find educational material.

The key advantage of Socratic is the possibility to decompose complicated issues and combine quality


##### CHAPTER 3. LITERATURE REVIEW / RELATED WORK 11

educational resources of the entire web. It is a smart scholar search engine and works as an effective
instrument of self-study. The main weakness though is its absence of personalization. It is not trained
on the course materials, notes, and learning progress of a user. Its responses are generic and drawn from
public sources, which implies that it is not able to explain anything in the context of what a student has
been taught in a particular lecture. Moreover, it is an isolated tool that has no collaborative features.

The scan-and-learn approach by Socratic is very applicable to the goal of StudySync that enables user
interaction with their notes. StudySync will have the ability to find specific answers by going through
user provided notes, textbooks and other relevant content. This will make sure that the assistance is
custom to the user, aligning with their course material, and assists them in relating ideas in their personal
study materials.

#### 3.2.3 Community-Based Learning Platforms

3.2.3.1 Reddit

Reddit [6] is an enormous collection of user-created communities, called subreddits, that are devoted to
a certain topic. Subreddits such as r/learnprogramming, r/ComputerScience, and r/datascience can serve
as informal learning communities of students. Within such communities, users are able to ask questions,
share resources, discuss complex issues and get feedback on their projects. The threaded discussion
structure and the upvote / downvote system of the platform assist in structuring the discussion and
ranking the most useful content to the community.

One of the advantages of Reddit is its accessibility and the ability to support a variety of types of dis-
cussions, both narrow technical issues and general conceptual discussions and career guidance. This
renders it a more friendly environment to beginners than the rigid structure of other forum-based web-
sites like Stack Overflow. The fact that the quality and accuracy of information varies, however, is the
main weakness of it. Answers may be speculative, incomplete, or even incorrect without formal mod-
eration as to their correctness. Moreover, similar to other open forums, it does not fit into the personal
study process of a student and is not curriculum-specific to a course or an institution.

The design of study sync community threads is inspired by the idea of having specific spaces on Reddit
based on individual subjects (e.g., PF, OOP, DSA). StudySync will embrace the collaborative ethos of
Reddit and overcome its crucial weaknesses. Placing the discussions in the context of an embedded
note-taking and AI-tutoring tool, StudySync will make the discussion focused and contextually engaged
with the real course material of a user. Another reliable source of information is the availability of the AI
tutor, which reduces the possibility of misinformation that is often present on open forums and provides
a more credible learning experience.


##### CHAPTER 3. LITERATURE REVIEW / RELATED WORK 12

3.2.3.2 Stack Overflow

Stack Overflow [7] is a very organized question and answer site that has become a very essential tool to
the programmer and software developers. It is used mainly as a community source of quality solutions
to particular technical issues. The site uses a reputation system with the points given out to users who
pose good questions and give correct and verifiable answers. The community-based voting system and
strict moderation will ensure that the most accurate and useful answers can be easily found to provide a
reliable source of knowledge in technical questions.

The primary asset of Stack Overflow is the huge and well-structured database of solutions to issues
related to programming. Its strict format makes its questions straightforward and answers concise and
to the point making it incredibly efficient in finding solutions to certain mistakes or implementation
problems. Nevertheless, this is also a major constraint in a learning environment. The platform does not
support conceptual discussions, open-ended questions, and beginner-level support, and this may be an
intimidating factor to students. More to the point, it has nothing to do with the learning resources of a
particular person; a user is not able to pose a question in the framework of his or her lecture notes or
textbook examples.

Stack Overflow is an example of what the quality and reliability of the community feature of StudySync
should strive to achieve. It confirms the necessity of a place where students are able to receive certain
answers to their technical questions. StudySync will enhance this model by providing a context-sensitive
and supportive environment. Compared to the public and impersonal design of Stack Overflow, the
community threads on StudySync will be directly embedded into the digitized notes of the user. This
will enable students to pose questions such as, why was this particular sorting algorithm in my DSA
notes?–a question that is highly personal and contextual, and thus not fit to ask on Stack Overflow, but
would be ideal in a learning community.


##### CHAPTER 3. LITERATURE REVIEW / RELATED WORK 13

### 3.3 Related Work Summary Table

The table 3.1 shown below summarizes the analysis of applications related to our project.

```
Table 3.1: Summary of Related Work Review
Application Features Relevance to StudySync Limitations
Evernote [1] Note organization,
cross-platform sync,
OCR for search.
```
```
Establishes the utility of
digitizing and searching
handwritten notes.
```
```
OCR is for indexing only;
no contextual understand-
ing or AI learning fea-
tures. Lacks community
tools.
Goodnotes [2] Superior handwriting
experience, PDF an-
notation, OCR-based
search.
```
```
Sets a high standard for
the note-taking user ex-
perience and handwriting
capture.
```
```
No intelligent features be-
yond search. Lacks AI
assistance and integrated
collaboration.
Microsoft
OneNote [3]
```
```
Free-form digital
notebook, multimedia
notes, OCR, Microsoft
ecosystem integration.
```
```
A strong competitor in
note organization, show-
ing the value of a flexible
canvas.
```
```
AI features are limited
and not focused on edu-
cational tutoring. Collab-
oration is for co-editing,
not community discus-
sion.
Quizlet [4] Digital flashcards,
learning games,
AI-powered tutor
(Q-Chat).
```
```
Provides a model for an
interactive AI tutor and
active recall-based learn-
ing.
```
```
AI is limited to predefined
study sets; cannot process
and learn from a user’s
handwritten notes.
Socratic by
Google [5]
```
```
Photo-based question
answering, aggregates
web resources, step-
by-step explanations.
```
```
Validates the ’scan-to-
learn’ workflow for
academic problem-
solving.
```
```
Not personalized; pro-
vides generic answers
from the web, not context
from user’s notes.
Reddit (e.g.,
r/learnprogram-
ming) [6]
```
```
Forum-based com-
munities (subreddits),
threaded discussions,
voting system.
```
```
Demonstrates large-scale,
topic-specific peer sup-
port and resource sharing.
```
```
Lacks real-time interac-
tion and integration with
personal study materials.
Information can be unre-
liable.
Stack Overflow
[7]
```
```
Public Q&A plat-
form for technical
questions, reputation
system.
```
```
A benchmark for
community-based tech-
nical problem-solving,
especially in program-
ming.
```
```
Strictly Q&A format; not
integrated with a note-
taking workflow or per-
sonalized learning.
```

##### CHAPTER 3. LITERATURE REVIEW / RELATED WORK 14

### 3.4 Conclusion

Based on the analysis, the market is full of specialized tools used in digital note-taking, community col-
laboration, AI-based learning. Evernote and Goodnotes are among these applications that have perfected
the digitization and sorting of notes but have no smart learning functions. AI tutors like Quizlet’s Q-Chat
and Socratic provide interactive learning experiences that are powerful but disconnected. Forum-based
applications like Reddit and Stack Overflow have demonstrated the importance of peer-peer support but
exist as independent ecosystems, not connected to the main note-taking and study process.

There has been a desirable gap in the market due to the lack of a common platform where all these
three pillars of modern learning are integrated seamlessly. Therefore the novelty and importance of
developing StudySync is apparent from this analysis as it bridges the gap between the three components
digital note-taking, AI-driven learning aids and community-based learning.


##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 15

### Chapter 4 Software Requirement Specifications

This chapter highlights important features of the projects. It also includes functional and non-functional
requirement of the project, defines use cases and risk analysis involved in the project.

### 4.1 List of Features

- Converting handwritten notes into accurate digital text using OCR
- Enabling intelligent search and retrieval of information through a RAG-based LLM
- Providing an AI tutor focused on programming courses (PF, OOP, DSA, DB)
- Allowing users to share notes, ask questions, and interact through community thread

### 4.2 Functional Requirements

- The system shall allow users to upload handwritten notes in image formats
- The system shall support batch upload of multiple images simultaneously
- The system shall preserve the structure and formatting of the original notes
- The system shall allow users to review and edit OCR output before saving
- The system shall allow users to add tags and metadata to digitized notes
- The system shall enable users to search through their notes using natural language queries
- The system shall return relevant snippets and complete documents ranked by relevance
- The system shall retrieve contextually relevant information from the entire notes repository
- The system shall answer specific questions based on the content of uploaded notes
- The system shall cite specific notes/sections when providing answers
- The system shall provide tutoring for Programming Fundamentals (PF), OOP, DSA, and Database
    courses
- The system shall answer conceptual questions with explanations and examples
- The system shall allow users to share digitized notes publicly or with specific users/groups
- The system shall enable users to create question threads on specific topics or courses
- The system shall allow users to reply to threads


##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 16

- The system shall provide secure user registration
- The system shall support login via email/password and social authentication

### 4.3 Quality Attributes

- Usability – The system should be simple and intuitive for users to upload, edit, and search their
    digitized notes efficiently.
- Reliability – The system should consistently produce accurate OCR results and reliable search
    outputs for uploaded notes.
- Scalability – The system should efficiently handle a growing number of users and large volumes
    of uploaded notes without performance loss.
- Security – The system should ensure all uploaded notes and user data are protected from unau-
    thorized access or misuse.
- Maintainability – The system should be easy to update, fix, and enhance as new OCR models or
    features are introduced.
- Availability – The system should remain accessible and operational for users with minimal down-
    time.
- Portability – The system should function seamlessly across different devices and platforms, such
    as web and mobile.

### 4.4 Non-Functional Requirements

- Performance: The system should maintain over 85% accuracy in OCR processing and search
    results.
- Scalability: The system should easily expand to handle 100,000 users and large data volumes.
- Security: Data should be protected from unauthorized access.
- Reliability & Availability: The system should remain available 99% of the time with quick
    recovery from failures.
- Usability: The system should be user-friendly, responsive on all devices, and easy to learn.


##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 17

### 4.5 Assumptions

- The user has a working camera available for capturing images.
- The user has access to a stable internet connection.
- The user possesses basic computer literacy skills.
- The user knows how to properly take pictures and has basic photography knowledge.

### 4.6 Use Cases

```
Table 4.1: Use Case 1: User Authentication
Name User Authentication
Actors Student
Summary The user shall provide their email and password on the lo-
gin form, and after successful verification, redirect the user
to the home page.
Pre-Conditions The user must have registered before.
Post-Conditions The user’s session is successfully established and shall be
redirected to the home page.
Special Requirements None
Basic Flow
Actor Action System Response
1 The user opens the login page. 2 The login page is displayed ask-
ing for email and password.
2 The user enters valid email and password. 3 The system verifies the creden-
tials, establishes a session, and
redirects the user to the home
page.
Alternative Flow
3 The user enters invalid email or password. 4-A The system responds with an er-
ror message: “Incorrect email or
password entered.”
```

##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 18

```
Table 4.2: Use Case 2: Digitizing Notes
Name Digitizing Notes
Actors Student
Summary The user shall provide scanned images and the system shall
convert them into digitized text.
Pre-Conditions The user is authenticated.
Post-Conditions The system has generated digital text which is ready for
user review.
Special Requirements None
Basic Flow
Actor Action System Response
1 The user navigates to the digitize notes sec-
tion.
```
```
2 The system displays the upload
interface.
2 The user scans or uploads handwritten note
images.
```
```
3 The system converts images into
digitized text and notifies the
user that the draft is ready.
Alternative Flow
3 The user uploads an unreadable or corrupted
image file.
```
```
4-A The system displays an error
message: “Unable to process
image, please upload a clearer
file.”
Table 4.3: Use Case 3: Review Notes
Name Review Notes
Actors Student
Summary The user reviews the OCR output and fixes any mistakes to
produce the final output.
Pre-Conditions OCR processing for the note is complete (UC 2.1). The
user is in the editing interface.
Post-Conditions A finalized digitized note is available for the student to
search through.
Special Requirements None
Basic Flow
Actor Action System Response
1 The user is presented with the OCR draft. 2 The system displays the editable
text to fix any mistakes.
2 The user reviews the text, corrects any er-
rors, and manually fixes mistakes.
```
```
3 The system updates the file.
3 The user enters a relevant title and adds one
or more tags.
```
```
4 The system validates the input
and prepares the document for
final storage.
4 The user selects “Done.” 5 The system saves the digitized
note and confirms creation.
Alternative Flow A: Discard Draft
4-A The user selects “Discard Draft.” 5-A The system prompts for confir-
mation, then deletes the tempo-
rary OCR draft and associated
image files.
```

##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 19

```
Table 4.4: Use Case 4: Retrieve Contextual Information
Name UC 4 Retrieve Contextual Information
Actors Student
Summary The system searches through the notes through RAG sys-
tem to give user
Pre-Conditions The User has digitized notes for the system to search from
Post-Conditions The User receives a concise answer to their search
Special Requirements None
Basic Flow
Actor Action System Response
1 User enters a search request 2 The system executes a search
across all digitized text.
2 - 3 The system searches multiple
documents and compiles the re-
sults..
3 - 4 The system returns the compiled
answer to the user.
Table 4.5: Use Case 5: Receive AI-Powered Tutoring
Name Receive AI-Powered Tutoring
Actors User (Student)
Summary The User interacts with an AI tutor to receive conceptual
explanations about the subjects or topics they face diffi-
culty in
Pre-Conditions The User is authenticated
Post-Conditions The User receives a clear answer which helps clear their
misunderstandings
Special Requirements None
Basic Flow
Actor Action System Response
1 The user asks a question. 2 The system responds using the
person notes and database it has
been trained on.
Table 4.6: Use Case 6: Share Notes
Name Share Notes
Actors User (Student)
Summary The User has the ability to share to share their notes on
threads for others students to view
Pre-Conditions The User is authenticated. The User has a saved digitized
note.
Post-Conditions The digitized notes are shared on threads.
Special Requirements None
Basic Flow A: Share Publicly
Actor Action System Response
1 The User selects a digitized note and
chooses to share.
```
```
2 The system displays the sharing
dialog.
2 The User selects the sharing button. 3 The system shares the note on
thread notifying the user.
```

##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 20

```
Table 4.7: Use Case 7: Create Discussion Thread
Name UC 5.2: Create Discussion Thread
Actors User (Student)
Summary The User starts a new discussion thread to discuss ques-
tions about any topic
Pre-Conditions The User is authenticated
Post-Conditions A new discussion thread document is created
Special Requirements None
Basic Flow
Actor Action System Response
1 The User navigates to the ’Discussion’ area
and selects ’New Thread’.
```
```
2 The system displays thread cre-
ation interface.
2 The User writes the relevant info and sub-
mits the new thread.
```
```
4 The system creates the thread.
```
```
Table 4.8: Use Case 8: Reply to Thread
Name Reply to Thread
Actors User (Student)
Summary The User participates in a discussion by viewing an exist-
ing thread and submitting a reply.
Pre-Conditions The User is authenticated. The thread is posted.
Post-Conditions Student reply is submitted to thread.
Special Requirements None
Basic Flow
Actor Action System Response
1 The User selects and opens an existing
thread.
```
```
2 The system displays the full
thread history and a reply input
box.
2 The User enters and submits their reply mes-
sage.
```
```
3 The system saves the reply and
shows it on the thread replies.
```

##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 21

### 4.7 Hardware and Software Requirements

The following section outlines the hardware and software requirements necessary for the development,
testing, and deployment of the StudySync application.

#### 4.7.1 Hardware Requirements

- Cloud Server Instance: The backend and AI models will be hosted on a cloud platform such
    as Render, Railway, AWS, or Hugging Face Spaces. A cloud instance with a minimum of 8 GB
    RAM, a Quad-core CPU, and 128 GB SSD storage is required. For optimal performance during
    OCR and AI inference, a GPU-enabled instance (e.g., NVIDIA T4, RTX 3060, or equivalent) is
    recommended.
- Client Devices: Any modern smartphone, tablet, or computer capable of running the Flutter ap-
    plication or accessing the web version. Minimum specifications include 4 GB RAM, a Dual-core
    processor, and an updated operating system (Android 10+/iOS 13+ for mobile; Windows 10+/ma-
    cOS 10.15+ for desktop).
- Development Machine: A local computer with at least 16 GB RAM, a Quad-core processor, and
    256 GB SSD storage for developing and testing the Flutter frontend and FastAPI backend before
    cloud deployment.

#### 4.7.2 Software Requirements

- Frontend: Flutter SDK for building cross-platform mobile and desktop applications and support
    offline notes.
- Local Storage: ObjectBox to store note pictures, OCR results and their embedding on the device
    of the user to allow offline viewing and local semantic search.
- Backend: FastAPI (Python) for creating REST and WebSocket APIs to handle OCR, RAG, and
    user interactions.
- AI Components:
    - Cloud-based OCR Model (e.g., TrOCR, Kosmos) to identify handwritings and bounding
       box.
    - Embeddings Service to create the vector embedding, which is locally (notes) and on the
       server (course books).
    - LLM Service with Retrieval-Augmented Generation (RAG) utilizing local note context (sent


##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 22

```
from device) and course book embeddings on the server
```
- Database: Postgres will be utilized with extension ”pgvector” to:
    - Store Embeddings of course books that are used in RAG..
    - Managing user accounts, authentication and sessions.
    - Support Forum feature which will include threads, replies, attachments etc.
- Containerization: Docker and Docker Compose for packaging the backend and model services
    as well as ensuring portability across cloud platforms.
- Version Control: Git and GitHub for tracking version history of the codebase and collaborative
    development.
- Operating System: Development supported on Windows, macOS, or Linux; cloud deployment
    is recommended on Linux-based environments for stability and scalability.


##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 23

### 4.8 Graphical User Interface

GUI sample of the system is as under:

```
Figure 4.1: Login Screen
This screen is an example of StudySyncs’s login Screen, where users can enter their login details
```

##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 24

Figure 4.2: Registration Screen
This screen is an example of StudySyncs’s registration Screen, where users can enter their profile details

```
Figure 4.3: Dashboard Screen
This screen is an example of StudySyncs’s main Dashboard, where users are quick shortcuts to other
features
```

##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 25

Figure 4.4: Notes Screen
This screen is an example of StudySyncs’s Notes Screen, where users view a list of their notes. They can
select a note to edit, view or add a new note

```
Figure 4.5: Notes Editing Screen
This screen is an example of StudySyncs’s Notes Editing Screen, where users can edit their notes.
```

##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 26

Figure 4.6: AI tutor Screen
This screen is an example of StudySyncs’s AI tutor Screen, where users can chat with the AI tutor or ask
questions about their courses

```
Figure 4.7: Community Screen
This screen is an example of StudySyncs’s Community Screen, where users post queries and also
answer queries of others
```

##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 27

```
Figure 4.8: Profile Screen
This screen is an example of StudySyncs’s Profile Screen, where users view their profile details
```

##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 28

### 4.9 Database Design

The system uses two databases. One is on the server and the other is on the user’s device. this will allow
support for both offline note management and online AI-powered features.Hence two distinct ERDs are
provided.

#### 4.9.1 ER Diagram

```
Figure 4.9: Server Entity Relationship Diagram
```

##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 29

```
Figure 4.10: Client Entity Relationship Diagram
```
#### 4.9.2 Data Dictionary

4.9.2.1 Server

```
Table 4.9: User Table Schema
Column Name Data Type Constraints Description
userid UUID PK, NOT NULL Unique identifier
for each user.
username VARCHAR NOT NULL User’s display
name.
email VARCHAR UNIQUE, NOT NULL User’s email for lo-
gin.
passwordhash VARCHAR NOT NULL Hashed password
for authentication.
createdat TIMESTAMP NOT NULL Account creation
timestamp.
```

##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 30

```
Table 4.10: Course Table Schema
Column Name Data Type Constraints Description
courseid INT PK, NOT NULL Unique course
identifier.
coursecode VARCHAR NOT NULL Short course code
(e.g., PF101).
coursename VARCHAR NOT NULL Full course name.
description TEXT NULL Optional course de-
scription.
```
```
Table 4.11: Thread Table Schema
Column Name Data Type Constraints Description
threadid UUID PK, NOT NULL Unique thread
identifier.
userid UUID FK→ User(userid),
NOT NULL
```
```
Author of the
thread.
courseid INT FK→ Course(courseid),
NOT NULL
```
```
Related course.
title VARCHAR NOT NULL Thread title.
content TEXT NOT NULL Thread content/-
body.
createdat TIMESTAMP NOT NULL Creation times-
tamp.
```
```
Table 4.12: Comment Table Schema
Column Name Data Type Constraints Description
commentid UUID PK, NOT NULL Unique comment
identifier.
threadid UUID FK→ Thread(threadid),
NOT NULL
```
```
Thread this com-
ment belongs to.
userid UUID FK→ User(userid),
NOT NULL
```
```
Author of the com-
ment.
parentcommentid UUID FK→ Com-
ment(commentid),
NULL
```
```
Parent comment
(for replies).
content TEXT NOT NULL Comment text.
createdat TIMESTAMP NOT NULL Creation times-
tamp.
```

##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 31

```
Table 4.13: Thread Attachment Table Schema
Column Name Data Type Constraints Description
attachmentid UUID PK, NOT NULL Unique attachment
identifier.
threadid UUID FK→ Thread(threadid),
NOT NULL
```
```
The thread the
attachment belongs
to.
fileurl VARCHAR NOT NULL Cloud URL point-
ing to the uploaded
file.
filetype VARCHAR NOT NULL MIME type or file
category.
createdat TIMESTAMP NOT NULL Upload timestamp.
```
```
Table 4.14: Course Book Embedding Table Schema
Column Name Data Type Constraints Description
embeddingid UUID PK, NOT NULL Unique embedding
identifier.
courseid INT FK→ Course(courseid),
NOT NULL
```
```
Course the embed-
ding belongs to.
chunktext TEXT NOT NULL Text chunk ex-
tracted from the
textbook.
vectordata VECTOR NOT NULL Vector embedding
of the chunk text.
metadata JSONB NULL Extra data (page
number, chapter,
etc.).
```

##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 32

4.9.2.2 Client

```
Table 4.15: Note Record Table Schema
Column Name Data Type Constraints Description
id INT PK, NOT NULL Local note identi-
fier.
title STRING NOT NULL Title given by the
user.
course STRING NOT NULL Course name/iden-
tifier.
textContent STRING NULL Manually added
text by user.
createdAt DATE NOT NULL Creation times-
tamp.
updatedAt DATE NOT NULL Last update times-
tamp.
ocrProcessed BOOL NOT NULL Whether OCR is
completed.
embeddingProcessedBOOL NOT NULL Whether embed-
ding is completed.
Table 4.16: Note Image Table Schema
Column Name Data Type Constraints Description
id INT PK, NOT NULL Local image identi-
fier.
noteid INT FK→ NoteRecord(id),
NOT NULL
```
```
Parent note.
imageBytes BYTEVECTOR NOT NULL Stored image in
bytes.
createdAt DATE NOT NULL Timestamp when
image was added.
ocrProcessed BOOL NOT NULL Whether OCR was
performed for this
image.
```
```
Table 4.17: OCR Block Table Schema
Column Name Data Type Constraints Description
id INT PK, NOT NULL Unique OCR block
id.
imageid INT FK→ NoteImage(id),
NOT NULL
```
```
Parent image.
text STRING NOT NULL Detected text.
page INT NOT NULL Page index.
readingOrder INT NOT NULL Order within the
page.
quad BYTEVECTOR NOT NULL Quad coordinates
(8 floats).
```

##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 33

```
Table 4.18: Text Chunk Table Schema
Column Name Data Type Constraints Description
id INT PK, NOT NULL Local chunk identi-
fier.
noteid INT FK→ NoteRecord(id),
NOT NULL
```
```
Parent note.
chunkText STRING NOT NULL Chunk text used to
generate embed-
ding.
embedding FLOATVECTOR(384) NOT NULL Embedding vector.
orderIndex INT NOT NULL Position in original
reconstructed note.
```

##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 34

### 4.10 Risk Analysis

This section identifies the most critical risks that could cause problems in the development and imple-
mentation of StudySync. We have classified these challenges and described mitigation measures to be
put in place to make the project successful.

#### 4.10.1 Technical Risks

The main issues of StudySync concern technical aspects, which are the functionality and connectivity
of its main AI elements.

- OCR Accuracy on Varied Handwriting: The success of the whole application will depend on
    the ability to read handwritten notes and translate them into digitized text. Various handwriting
    styles, degree of neatness, and languages may have a strong influence on the performance of the
    OCR model. To minimize these issues we will choose an OCR model, that has been trained on
    a wide range of samples of handwriting and, perhaps, fine-tune it if the need arises. Another
    aspect that we will take into consideration is the implementation of an easy-to-use interface of the
    correction process by users in case of any transcription errors.
- RAG Model Performance: The quality of the AI tutor will be determined by the RAG model
    that is capable of retrieving the right context of the user notes as well as the textbooks presented.
    In case of a poor retrieval, the LLM will produce irrelevant or wrong answers. To minimize these
    issues we will concentrate on the optimization of the vector embedding and search algorithms
    with the use of pgvector. The system will prioritize context obtained from user notes.

#### 4.10.2 User Adoption and Engagement Risks

Even with such powerful technology, it will be successful only when students decide to use the app.

- Competition from Existing Tools: The market of note taking is saturated with other established
    applications such as Goodnotes and Evernote. Learners might want to keep using their exist-
    ing, known workflows. We will counter this by focusing on the unique qualities of StudySync:
    transforming dead, personal notes into a live, AI-driven study companion. Features that the com-
    petition does not offer like the contextual AI tutor and community forums built in will also help
    in standing out.
- Complex Onboarding: Note scanning, AI chat, and community features might be too much at
    once for a user to start with. To solve this, we will provide simple step-by-step instructions on
    using the different components of the app effectively.


##### CHAPTER 4. SOFTWARE REQUIREMENT SPECIFICATIONS 35

### 4.11 Conclusion

The chapter covered all the major functional requirements and use cases of our project. Mainly related
to digitzing notes, the AI tutor and community forums. We also list non-functional requirements like
performance and security. Finally, the risk analysis helped us identify potential challenges like the
importance of ensuring high accuracy of the AI models, user adoption among competition and presenting
our application’s value correclty to make it stand out.


##### CHAPTER 5. HIGH-LEVEL AND LOW-LEVEL DESIGN 36

### Chapter 5 High-Level and Low-Level Design

The complete details of high-level and low-level design of the system we are building is provided in this
chapter.

### 5.1 System Overview

StudySync is a system created to be an AI-enabled study assistant, which assists the students in digitiz-
ing, organizing and engaging with their handwritten notes and allows them to learn within a community,
through community discussion options. There are three main subdivisions of the system architecture:
OCR and Notes Digitization, AI Assistant and Intelligent Search, and Community Threads. All the
modules have their specific purposes in the successful integration of data processing, AI-based retrieval,
and the engagement of users.

#### 5.1.1 OCR and Notes Digitization

The first part of the system is aimed at making handwritten notes readable as digital content that can
be edited and searched. The module uses an Optical Character Recognition (OCR) model (such as Mi-
crosoft’s Kosmos) that can identify and strip text out of images of handwritten notes. Besides extracting
the texts, the system also stores positional metadata, e.g. line coordinates and block positions, to keep
the position of the notes in the space. This information can be properly rendered and better understood
in another context when viewing or searching notes later.

#### 5.1.2 AI Assistant and Intelligent Search

The second key feature is the application of a Large Language Model (LLM) along with Retrieval-
Augmented Generation (RAG) to make a personalized AI study assistant. The digitized notes are pro-
cessed by this module which transforms the notes into a set of vectors and stores these vectors in a vector
database on device which can be searched semantically efficiently. The assistant has the ability to engage
with students and respond to context-specific questions and the RAG pipeline retrieves the appropriate
portions of their notes or textbooks to provide accurate and meaningful responses. This element enables
the system to operate like a context-aware tutor, which can help students in programming related courses
like PF, OOP, DSA, and DB.


##### CHAPTER 5. HIGH-LEVEL AND LOW-LEVEL DESIGN 37

#### 5.1.3 Community Threads

The last element of the system is the community threads module, that will help with collaboration and
peer learning. There is an organized discussion board where students are allowed to ask questions,
exchange notes and answer other questions. This aspect promotes knowledge sharing, problem solving
and scholarly interaction between the users. The community module is an addition to AI assistant that
offers a human-learning aspect spreading the knowledge base not only to the answers offered by AI but
also to the users working on a similar subject.

### 5.2 Design Considerations

Here in this section, we will address the complete design solution.

#### 5.2.1 Assumptions and Dependencies

The StudySync system is designed keeping some assumptions and dependencies in terms of its func-
tioning and environment, as well as users.

- Hardware and Connectivity: The system will be accessed by users using the standard devices
    e.g. laptops or smartphones. Notes may be scanned out of pictures, and therefore no camera
    or scanner is necessary. Cloud-based OCR,embedding, LLM processing as well as community
    interactions assume a stable internet connection.
- Software and System: This system relies on cloud-based OCR models (e.g. Kosmos) and an
    intelligent assist system based on an LLM with a RAG pipeline. Structured data and embeddings
    are going to be handled by a PostgreSQL database with pgvector (tentatively), whereas FastAPI
    is to be used as a backend framework.
- End Users: The app will be used by students mostly in the fields of Computer Science who would
    like to digitize, group, and read by handwritten notes.
- Developmental Assumptions: Future releases can be expanded to more subjects and achieve
    better OCR with all types of handwriting.

#### 5.2.2 General Constraints

StudySync operates within certain constraints that influence its design and functionality:

- Cloud Dependency: OCR, embedding, and LLM operations are performed on the cloud and
    therefore the system is dependent on the presence of internet connectivity and cloud availability.


##### CHAPTER 5. HIGH-LEVEL AND LOW-LEVEL DESIGN 38

```
Any failure or sluggishness of these services may affect the speed and reliability in responding.
```
- Scalability Constraints: As more people join the system and the size of the notes stored in-
    creases, there should be smooth handling of higher workloads by the system especially during
    peak seasons when exams are in progress. Scaling backend services and databases should be done
    properly in order to keep performance.
- Data Privacy and Security: The application will be utilized on user-generated content, such as
    personal notes. It should be able to guarantee secure data processing, encrypted communication,
    and limited access by means of avoiding data leakage and unauthorized dissemination.
- Resource Limitations: OCR, embedding and LLM services using API can have a rate limit or
    cost constraint that may impact the availability of the system or necessitate a system optimization.
- Compatibility Constraints: The app should be compatible with various platforms (desktop and
    mobile browsers) and compatible with common image formats to upload notes.

#### 5.2.3 Goals and Guidelines

StudySync has been designed in accordance with various principles to render usability, reliability and
scalability.

- Simplicity (KISS Principle): The interface and workflow are maintained to be easy to allow
    students to add notes, and communicate with the AI assistant and discuss with no technical com-
    plexity.
- Modularity and Scalability: The system is separated into autonomous parts OCR, LLM, and
    community threads so that the system can be more easily maintained, updated, and expanded in
    the future.
- Consistency and Reliability: As AI processing is conducted on the cloud, the system guarantees
    equal processing time and performance among all users, irrespective of their device specification.
- Security and Privacy: Storage and transmission of all user data and uploaded notes are encrypted
    and controlled access measures are applied.
- Cross-Platform Accessibility: The site will be made to be used both in desktop and mobile apps
    so that students can use it.


##### CHAPTER 5. HIGH-LEVEL AND LOW-LEVEL DESIGN 39

#### 5.2.4 Development Methods

The creation of StudySync is based on the Agile approach, in which the focus is on flexibility, teamwork,
and continuous enhancement. The system will be broken down into three key modules, namely OCR
and Notes Digitization, AI Assistant and Intelligent Search, and Community Threads, which will be
developed simultaneously, with each member of the team focusing on a separate module.

This parallel method allows making early steps and effectively integrating individual parts as soon as
they are ready. The use of Agile was selected instead of other traditional approaches such as the Waterfall
approach so that they could conduct incremental testing, timely feedback, and flexibility during the
development. Both Git and Trello will help in ensuring that coordination and monitoring of progress
proceed without challenges.

### 5.3 System Architecture

StudySync has a system architecture that offers a simple, modern, and robust environment to convert
handwritten study materials into digital text and make them interactive. The high-level architecture is
shown below in Figure 5.1


##### CHAPTER 5. HIGH-LEVEL AND LOW-LEVEL DESIGN 40

```
Figure 5.1: Architecture Diagram of StudySync
```

##### CHAPTER 5. HIGH-LEVEL AND LOW-LEVEL DESIGN 41

Top-Level Responsibilities

At the top-most level, StudySync has the following key functionalities:

- User Interaction & Data Ingestion: The Flutter application supports a cross-platform user inter-
    face for uploading handwritten notes and interacting with the AI tutor.
- Content Transformation: The AI Layer is reponsible for utilizing the Microsoft Kosmos-2.5
    model for OCR.
- Context-Aware AI Tutoring: It allows for a RAG-based LLM, setup using LangChain, to provide
    users with customized and context specific answers.
- Data Storage & Vector-Embeddings: A dual-database approach is used. ObjectBox is used on
    the device for storing offline notes and embeddings, and PostgreSQL is used on the server for
    authentication, community threads, and textbook embeddings.
- Setting Up Services & API Gateway: The FastAPI backend takes care of user requests, manages
    calls between the database and the AI Layer and performs CRUD operations on the database.

Rationale: The design will be modular, offline, and scalable cloud-based AI. Separating the on-device
storage and server components will enable quick note access locally but enable more advanced AI tutor-
ing through the cloud.

#### 5.3.1 Subsystem Architecture

The major subsystems are further detailed below to provide a clearer understanding of their internal
components and interactions.

- Frontend Subsystem (Flutter App)
    This subsystem handles user interactions, data capture, and presentation for the StudySync appli-
    cation across different platforms.
       - Internal Components: UI/UX Components, State Management, API Client, and a Note Cap-
          ture Module using the device camera or gallery.
       - Interactions: The user uploads a note image and the API client sends it to the backend. The
          data is then received and the processed text is displayed.
- Backend Subsystem (FastAPI)
    This subsystem works as the central hub and manages business logic as well as all communication
    between the client and internal services.
       - Internal Components: API Endpoints for routing, Pydantic models for data validation, a


##### CHAPTER 5. HIGH-LEVEL AND LOW-LEVEL DESIGN 42

```
Service Orchestration layer, and a Database interaction layer for CRUD operations.
```
- Interactions: It receives HTTP requests from the Flutter frontend, validates the data, exe-
    cutes calls to the AI Layer and/or Database and then returns the processed data back to the
    frontend.
- AI Layer Subsystem
Provides the handwritten to digital text service through the OCR model and the AI-tutor+Vector
Search service through the RAG-based LLM.
- Internal Components: An OCR Service (Microsoft Kosmos-2.5), an Embedding Generation
Service, the hybrid RAG Orchestrator (LangChain), and the LLM Service.
- Interactions: Receives an image from the backend and returns digitized text. Upon a user
asks a question, the device does similarity search involving note embeddings locally and the
backend requests more context on the question from the course books on the server-side,
after which the final combined prompt gets sent to the service of the LLM.
- Database Subsystem (PostgreSQL + pgvector)
Offers persistent storage of user information, such as structured metadata, digitized text, and the
vector representations needed in semantic search.
- Internal Components: Relational tables for users and books, a table with a vector column
for embeddings (via pgvector), and indexing mechanisms for efficient retrieval.
- Interactions: The user uploads image of notes, which is forwarded to the backend where
they are processed via an OCR, and the digitized text and embeddings are saved to a local
store, provided through ObjectBox allowing offline access and search.

### 5.4 Architectural Strategies

StudySync architecture will be structured to accommodate scalability, modularity and cloud integration.
The following approaches were embraced to guarantee the system is flexible, maintainable, and able to
efficiently support AI-driven features.

#### 5.4.1 Modular and Layered Architecture

StudySync is designed as a modular layered architecture that separates the OCR, LLM and Community
modules. All the components are independent and they are connected with well-defined APIs. Such
separation enhances scalability and enables parallel development by the members of the team. Tightly


##### CHAPTER 5. HIGH-LEVEL AND LOW-LEVEL DESIGN 43

coupled monolithic design was also considered but dismissed because this would lack flexibility and
make updating it harder in the future.

#### 5.4.2 Cloud-Based Processing and Data Management

All the activities involving AI such as OCR and LLM queries are carried out in the cloud, so that all users
can experience the same level of performance. Such a method eliminates hardware dependency, makes it
easier to deploy and allows equal processing time. Local model execution was not implemented because
it has more hardware demands and was not as accessible to students with limited hardware capabilities.

#### 5.4.3 Technology and Framework Selection

FastAPI is employed in the backend to ensure high-performance and scalability in the form of asyn-
chronous communication. ObjectBox was chosen to store notes and embeddings locally due to its speed
and built-in embeddings support.. PostgreSQL using the pgvector extension is chosen to store struc-
tured data of forum and vector data of books, thus making it easy to perform semantic search and RAG
implementation. Flutter is used to create the frontend to deliver a cross-platform experience to the user,
whether on desktop or on mobile. Alternatives such as Django and Mongo DB were also considered and
rejected as they had performance trade-offs and could not support vectors.

#### 5.4.4 API-Driven Communication

Every component of the system interacts through RESTful API which makes sure that the frontend and
the backend are clearly separated. This will enable scaling independently, easier debugging and third
party educational services can be integrated in the future.


##### CHAPTER 5. HIGH-LEVEL AND LOW-LEVEL DESIGN 44

### 5.5 Domain Model/Class Diagram

#### 5.5.1 Server

```
Figure 5.2: Server Domain Model/Class Diagram
```

##### CHAPTER 5. HIGH-LEVEL AND LOW-LEVEL DESIGN 45

#### 5.5.2 Client

```
Figure 5.3: Client Domain Model/Class Diagram
```

##### CHAPTER 5. HIGH-LEVEL AND LOW-LEVEL DESIGN 46

### 5.6 Policies and Tactics

This section describes the key design and development policies embraced by StudySync to provide
consistency, maintainability and allow cross-platform compatibility.

#### 5.6.1 Coding Standards and Conventions

The development is guided by the PEP 8 coding standards of Python to ensure that the readability and
consistency are guaranteed in the backend code. Peer code reviews are also done before the merging of
the code through consistent naming, documentation and modular code design.

#### 5.6.2 Selection of Framework and Technology

FastAPI is used as the backend because of its asynchronous performance and simplicity. The primary
database for server is PostgreSQL(tentatively), and its pgvector extension to store book vector embed-
dings. The frontend is created with Flutter, which was selected due to its cross-platform capabilities
(desktop, Android, iOS) that will guarantee a consistent user experience. The primary database for
client is ObjectBox(tentatively) to store notes and their vector embeddings.

#### 5.6.3 Testing and Version Control

All the modules (OCR, LLM, and Community Threads) will be tested with unit and integration testing.
The project is managed by Git and structured branching model to facilitate co-operation between team
members working on various modules concurrently.

#### 5.6.4 Deployment and Maintenance

This will be managed through a cloud platform (e.g., AWS or Azure) so as to allow OCR and LLM
processing. To achieve the desired consistency of environments and ease of maintenance when updating,
Docker containers will be used.

### 5.7 Conclusion

StudySync makes use of well-defined subsystems that are combined together into a modular and layered
architecture. Compute-intensive tasks like OCR and LLM/RAG processing will be handled through
cloud computing. The technology stack includes Flutter, FastAPI, and PostgreSQL with pgvector for
semantic search. Overall, our design prioritizes simplicity, efficiency and practicality.


##### CHAPTER 6. IMPLEMENTATION AND TEST CASES 47

### Chapter 6 Implementation and Test Cases

This chapter presents the implementation work completed during the initial development phase of the
StudySync application, focusing on the core interface structure and functional workflow of the system.

### 6.1 Implementation

The following section outlines the implementation details of the prototype developed during this phase.
The focus is on the cross-platform frontend components, setting up the initial OCR pipeline, setting up
the RAG-based LLM service and creating a bare-bones usable version of the application.

#### 6.1.1 Frontend Prototype

The end-user app has been built on the Flutter SDK, which ensures that it has a uniform user experience
across the Android, IOS, Windows and Linux systems. An architectural choice was made to store
digitized notes and their vector embeddings locally in the device in the ObjectBox database. This will
provide the offline intelligent search, by which the users will be able to view, search, and sort their notes
even without an internet connection.

#### 6.1.2 Authentication

The FastAPI backend is the one in charge of the authentication system to ensure user integrity and access
control. The Flutter front-end is used to deal with sign-up and sign-in pages. The FastAPI backend
verifies user credentials by comparing the user data stored against user data.

#### 6.1.3 Backend: API Gateway and AI Pipeline

The FastAPI server is the hub API Gateway and the general coordinator of all cloud-based artificial
intelligence processing and the last stage of RAG generation.

6.1.3.1 Notes Digitization and OCR (Cloud Service)

The OCR pipeline transforms images of handwritten text into digital text

1. Image Transmission: The user picks and posts images of handwritten notes. These images are
    transmitted to the cloud OCR service by the device.
2. OCR Processing: The OCR service identifies the text and sends bounding boxes/coordinates, as
    well as the text that was identified, to the device.


##### CHAPTER 6. IMPLEMENTATION AND TEST CASES 48

3. Local Persistence: Picture, OCR text and OCR layout metadata are all stored locally in Object-
    Box.

6.1.3.2 Embedding Generation (Cloud Service)

The index of semantic search is formed using a cloud service by the system:

1. Preprocessing: The device concatenates the text in reading sequence with the aid of the bounding
    boxes. This is then sent to the Embeddings service, which is a cloud-based service to which creates
    vector embeddings.
2. Vectorization: The cloud service returns individual text chunks and their corresponding embed-
    ding vectors (numerical representation of semantic meaning).
3. Local Storage: The device stores these embeddings locally in ObjectBox to enable fast and
    efficient local semantic search.

6.1.3.3 AI Tutor (LLM with RAG)

The AI Tutor is built with a hybrid local/cloud RAG pipeline which needs an internet connection.

1. Device Context Retrieval (Local RAG): When the user asks a question, A local vector similar-
    ity search is done by the device using the notes embeddings stored in ObjectBox. The relevant
    note chunks are gathered to form the Local RAG context.
2. Server Query: The device sends the original question and the local context to the server.
3. Server Context Retrieval: The server will retrieve course book snippets using the course book
    embeddings it has in its own storage.
4. Final Response Generation: The server combines the context of what the user has typed in the
    note (that is on the device) and the course book context (that is on the server) to generate a final
    and complete prompt. This trigger is received by the LLM which produces the final response that
    is in turn received by the device.

### 6.2 Conclusion

This implementation is the systematic foundation of StudySync that has managed to integrate the power
of cloud-based AI with the steady and strong local-first data model. The entire RAG pipeline will
provide a high level of personalization and context-sensitive academic assistance and the local data
storage would allow the user to have more autonomy over their notes.


##### CHAPTER 7. CONCLUSIONS 49

### Chapter 7 Conclusions

The work presented in this document provides the complete framework for StudySync, a study part-
ner application designed to revolutionize students’ interaction with their handwritten notes and engage
in collaborative learning. The difficulties of the physical nature of handwritten notes were identified,
mainly the difficulty in retrieval, the passive learning experience, and the inconvenience of collaboration
of these notes with other students. We also examined specialised tool like Evernotes, Quizlet we ob-
served a significant gap in the market for a common platform that seamlessly integrates notes digitisation
along with AI powered tutoring and a peer-based community.

In this stage, we were able to use the Kosmos model for OCR, store the results in embedding where you
can perform search on them through RAG model and ask AI tutor questions. The system is designed
to leverage Flutter for the cross-platform frontend, ensuring a consistent user experience on all the
supported platforms. The backend is built on FastAPI (Python), serving as a high-performance API
gateway to handle user requests and coordinate services. The notes and their embeddings are stored
on-device using object box meanwhile books and their embeddings on server using PostgreSQL and
pgvector. This enables the system to perform CRUD operations for notes and community threads, while
also powering the intelligent AI layer. A rag model allows User to search the notes that are stored in
embeddings. The overall design includes interfaces such as the Login, Registration, Dashboard, My
Notes, AI Tutor, and Community Forum screens. Together, these elements form an integrated platform
capable of the functionalities reflecting how the system is expected to function.

In the future, the next step will focus on digital reconstruction of the notes also the identification and
understanding of diagrams, increasing accuracy of the model and the deployment of the system. Along-
side this cloud deployment, backend automation improvements, enhancement of the database structure,
and using google drive as backup of notes storage will also be done. Once these resources are brought
together and the system is launched, StudySync will be become a study support platform where students
won’t face the limitations of physical handwritten notes.


##### BIBLIOGRAPHY 50

# Bibliography

[1] Evernote Corporation, “Evernote.” https://evernote.com, 2025. [Accessed: October 12, 2025].

[2] Time Base Technology Limited, “Goodnotes.” https://www.goodnotes.com, 2025. [Accessed:
October 12, 2025].

[3] Microsoft Corporation, “Microsoft onenote.” https://www.onenote.com, 2025. [Accessed: Oc-
tober 12, 2025].

[4] Quizlet, Inc., “Quizlet.” https://quizlet.com, 2025. [Accessed: October 12, 2025].

[5] Google LLC, “Socratic by google.” https://socratic.org, 2025. [Accessed: October 12, 2025].

[6] Reddit Inc., “Reddit.” https://www.reddit.com, 2025. [Accessed: October 12, 2025].

[7] Stack Exchange Inc., “Stack overflow.” https://stackoverflow.com, 2025. [Accessed: October
12, 2025].


