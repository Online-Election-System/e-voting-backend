# 🗳️ Online Election System – E-Voting Backend

Welcome to the **E-Voting Backend** for the Online Election System! This repository implements the secure, robust, and scalable server-side logic powering digital elections. Built entirely in Ballerina, it handles authentication, vote management, user enrollment, candidate management, and more—providing a trustworthy backbone for modern, transparent elections.

---

## 📋 Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Installation](#installation)
- [Usage](#usage)
- [Project Structure](#project-structure)
- [Contributors](#contributors)
- [Acknowledgments](#acknowledgments)

---

## 🏛️ Introduction

The E-Voting Backend is designed to deliver secure, efficient, and auditable election management for organizations, institutions, and government bodies. It exposes a set of RESTful APIs for election workflows and handles all business logic required for digital voting—ensuring privacy, integrity, and compliance.

### ⚡ Why This Backend?

Traditional election systems are vulnerable to errors, fraud, and inefficiencies. Our backend automates, secures, and streamlines the entire process:
- Securely manages user and role data
- Validates and records votes
- Provides verifiable audit trails
- Supports real-time result reporting
- Integrates easily with modern frontend applications

---

## ✨ Features

- **Role-Based Authentication & Authorization**: Comprehensive user management (voters, officials, admins, etc.) with granular permissions.
- **Secure Voting Logic**: Ensures vote privacy, prevents double-voting, and verifies eligibility.
- **Candidate & Election Management**: Handles registration, approval, and management of candidates and elections.
- **Robust Enrollment & Verification**: Manages voter registration, household relationships, and verification workflows.
- **Audit & Logging**: Transparent logs for election integrity and traceability.
- **Token-Based Session Management**: Secure JWT tokens for authentication and session control.
- **Automated Token Cleanup**: Periodic removal of expired session tokens for security.
- **Modular Architecture**: Ballerina modules for separation of concerns (auth, vote, enrollment, verification, etc.).

---

## 🧰 Technology Stack

- **Ballerina**: 100% backend logic, leveraging Ballerina's strengths in integration, APIs, and reliability.
- **Persist Module**: For database integration and ORM-like features.
- **Ballerina HTTP Module**: For RESTful API endpoints.
- **Crypto, JWT, Email Modules**: For password hashing, token management, and notifications.
- **SQL/Database**: External relational database for persistent storage (configured via Ballerina).

---

## 🖥️ Installation

### Prerequisites

- **Ballerina** (latest stable version recommended)
- Supported relational database (MySQL, PostgreSQL, etc.)
- [Optional] Docker (for containerized deployment)
- Node.js + npm (only if developing alongside the frontend)

### Setup Steps

1. **Clone the Repository**
   ```bash
   git clone https://github.com/Online-Election-System/e-voting-backend.git
   cd e-voting-backend
   ```

2. **Configure Environment Variables / Database**
   - Set up your database and update connection parameters in your Ballerina config files or as environment variables.
   - Example config keys: `DB_HOST`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`, etc.

3. **Install Dependencies**
   - Ballerina will resolve dependencies automatically during build.

4. **Build & Run the Service**
   ```bash
   bal build
   bal run
   ```
   The backend APIs will be available at the port specified in your configuration.

5. **API Documentation**
   - API endpoints and OpenAPI docs can be viewed by navigating to the Ballerina service port in your browser (if enabled).

---

## 🚀 Usage

- Integrate this backend with the [Voting System Frontend](https://github.com/Online-Election-System/voting-system-frontend).
- Use the provided RESTful endpoints to:
  - Register and verify voters
  - Manage elections and candidates
  - Authenticate users and manage sessions
  - Cast and count votes
  - Access logs and audit trails (admin only)
- See documentation in each module or OpenAPI spec for endpoint details.

---

## 📁 Project Structure

```plaintext
├── persist/
│   └── model.bal                 # Data models and DB schema mapping
├── modules/
│   ├── auth/
│   │   ├── middleware.bal        # JWT/token middleware, role/permissions logic
│   │   ├── permissions.bal       # Role-based permission management
│   │   ├── utils.bal             # Utilities for hashing, email, etc.
│   │   ├── official.bal          # Government official and commission registration
│   │   ├── cookie_helper.bal     # Cookie and session management
│   │   ├── token_cleanup.bal     # Automated token cleanup scheduler
│   ├── vote/
│   │   └── vote.bal              # Voting logic, voter verification, vote recording
│   ├── enrollment/
│   │   └── enrollment.bal        # Voter registration and enrollment flows
│   ├── verification/
│   │   └── types.bal             # Types and view models for verification and registration APIs
│   └── ...                       # Other modules for results, candidates, etc.
├── tests/
│   └── ...                       # Unit/integration tests for backend modules
├── Ballerina.toml                # Ballerina project configuration
├── README.md                     # This README file
└── ...                           # Other supporting files
```
> **Note:** Only main files/folders are shown. See [GitHub code search](https://github.com/Online-Election-System/e-voting-backend/search) for the full structure.

---

## 👨‍💻 Contributors

- **G.D. Punchihewa**: [Cookie-based Authentication, RBAC Authorization, Admin Module, Election Module, Candidate Module]
- **A.M.A.D. Weerasinghe**: [Voting Module]
- **W.H.P. Anuththara**: [Voter Verification Module]
- **R.A.D.P. Ranasinghe**: [Results Module]
- **J.G.J.M.R.K. Bandara**: [Voter Registration Module]

Feel free to contribute to the project by submitting pull requests or reporting issues!

---

## 🙏 Acknowledgments

- Special thanks to [University of Moratuwa](https://uom.lk) Faculty of Information Technology for supporting this project.
- This project architecture is inspired by best practices in secure, modern e-voting systems.

---

> **Disclaimer:** This backend is intended for research and demonstration purposes. For use in real elections, consult security, legal, and compliance experts.
