# web-auth

`web-auth` is a **login and authentication web service** implemented in Haskell.
It serves as a testbed for showcasing tooling and technologies commonly used in production-grade web development.

The system exposes both:

* An HTML MVC web application
* A RESTful API

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

## Architecture & Systems

Although the project is experimental in nature, it integrates several **production-ready systems**:

* **Katip** — structured logging
* **PostgreSQL** — persistent user storage (email, password hash, etc.)
* **RabbitMQ** — background email dispatching (verification emails)
* **Redis** — in-memory storage for authentication/session tokens

The project is built around the **Haskell ecosystem**, and includes a Haskell client library for interacting with the service via the RESTful API.

## Local Setup

### Requirements

* **PostgreSQL 16**
* **RabbitMQ**
* **Redis**
* **GHC 9.6.7** (project was built and tested with this version)
* `cabal`

The instructions below assume **macOS with Homebrew**.

## Starting Auxiliary Services

### 1) PostgreSQL

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

### 2) RabbitMQ

```bash
brew services start rabbitmq
```

### 3) Redis

```bash
brew services start redis
```

```
redis://localhost:6379/0
```
(In Haskell code we have hardcoded the default connection URLs: `amqp://guest:guest@localhost:5672/` and `redis://localhost:6379/0`.)

## Starting the Web Service

From the project root:

```bash
cabal run
```

The service will start on the configured port: `localhost:3000`.

## Credits

This project is inspired by the tutorials presented in:

*Ecky Putrady, Practical Web Development with Haskell*, Apress (2018).

It has been modernized and extended to incorporate updated libraries, tooling, and contemporary development practices.