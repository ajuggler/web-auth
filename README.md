# web-auth

`web-auth` is a **login and authentication web service** implemented in Haskell.
It serves as a testbed for showcasing tooling and technologies commonly used in production-grade web development.

The system exposes:

* A RESTful API implemented in Haskell using Scotty.
* A full-stack web app with a React client

---

## Features

### 🔐 Authentication Flow

* A **login page** (served by default) allows users to authenticate with email and password.

  * Invalid email/password combinations result in a failed login and an error notification.
  * Email **verification is required** before login is permitted.
  * A link to the registration page is provided.

* A **registration page** allows users to create an account using email and password.

  * If the email is already registered, an error notification is displayed.

### ✅ Input Validation

* **Email**

  * Case-insensitive
  * Must follow valid email format
  * Must be unique

* **Password**

  * Minimum length > 5 characters
  * Must contain:

    * At least one number
    * At least one uppercase letter
    * At least one lowercase letter

### 📧 Email Verification

* The service handles email verification logic.
* Verification emails are sent asynchronously.
* Users cannot log in until their email is verified.

### 🍪 Session Handling

* Upon successful login, the user is redirected to a protected **User page**.
* Authentication status is stored via cookies.
* Tokens are managed using an in-memory store.

---

## Architecture & Systems

Although the project is experimental in nature, it integrates several **production-ready systems**:

* **Katip** — structured logging
* **PostgreSQL** — persistent user storage (email, password hash, etc.)
* **RabbitMQ** — background email dispatching (verification emails)
* **Redis** — in-memory storage for authentication/session tokens
* **MailHog** — email testing tool

The project is built around the **Haskell ecosystem**, and includes a Haskell client library for interacting with the service via the RESTful API.

---

## Local Setup

### Requirements

* PostgreSQL 16
* RabbitMQ
* Redis
* MailHog
* GHC 9.6.7 (project was built and tested with this version)
* `cabal`

The instructions below assume **macOS with Homebrew**.

### Starting Auxiliary Services

#### 1) PostgreSQL

Start (or restart) the service:

```bash
brew services start postgresql@16
```

Create the project database:

```bash
createdb hauth
```

You can verify that the database exists:

```bash
psql -l
```

#### 2) RabbitMQ

```bash
brew services start rabbitmq
```

#### 3) Redis

```bash
brew services start redis
```

#### 4) MailHog

```bash
brew services start mailhog
```

Access Web UI at [http://localhost:8025](http://localhost:8025).

(We have configured the default connection URLs: `amqp://guest:guest@localhost:5672/` and `redis://localhost:6379/0`, `mailhog-smtp://localhost:1025`.)

### Starting the Backend Service

From the project root:

```bash
cabal run hauth
````

The Haskell backend service will start on the configured port (default: [http://localhost:3000](http://localhost:3000)).

### Starting the React Client

Ensure the backend service is running before starting the client.

In a separate terminal and from the project root:

```bash
cd frontend
npm install      # only required on first setup
npm run dev
```

The development server will start (typically at [http://localhost:5173](http://localhost:5173)).
The frontend is configured to proxy API requests to the backend during development.

### Starting the Email Worker

Run the dedicated email-worker process in a separate terminal:

```bash
cabal run hauth-email-worker
```

The worker consumes verification events from RabbitMQ and sends emails through SMTP (`localhost:1025`, compatible with MailHog).

---

## Credits

This project is inspired by the tutorials presented in:

*Ecky Putrady, Practical Web Development with Haskell*, Apress (2018).

It has been modernized and extended to incorporate updated libraries, tooling, and contemporary development practices.