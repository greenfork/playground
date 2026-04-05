# Client Notes Application

## Project Overview

Client Notes is a SvelteKit-based web application that serves as a client management system with notes functionality. The application connects to a CouchDB database using PouchDB for synchronization and offline capabilities. It's designed for therapists, coaches, or professionals who need to manage client information and session notes.

Key technologies used:
- Svelte 5 (latest version)
- SvelteKit framework
- Vite as build tool
- PouchDB for database operations and offline sync with CouchDB
- Vitest for unit testing
- Playwright for end-to-end testing
- Pico CSS for styling

## Architecture

The application follows a client-server architecture where:
- The frontend is a SvelteKit application
- The backend is a CouchDB database
- PouchDB handles client-side storage and synchronization with CouchDB
- Authentication is handled through CouchDB's session mechanism

## Development Conventions

### Code Style
- Uses ESLint and Prettier for consistent code formatting
- Follows Svelte 5 best practices
- Uses TypeScript-style JSDoc annotations for type checking

### File Structure
- `src/` - Main source code
  - `lib/` - Shared utilities and database functions
  - `routes/` - SvelteKit route components
  - `app.html` - Main HTML template
- `couchdb/` - Database initialization scripts
- `e2e/` - End-to-end tests
- `static/` - Static assets
- `configs/` - Configuration files (Caddy, etc.)

### Authentication
- Uses CouchDB's built-in session authentication
- Redirects unauthenticated users to `/login`
- Session timeout configured to 24 hours in CouchDB

## Key Features

1. **Client Management**: Add, view, and manage client profiles
2. **Session Notes**: Create and finalize session notes with timestamps
3. **Draft System**: Automatic draft saving with finalization workflow
4. **Offline Support**: PouchDB enables offline access with sync when online
5. **Authentication**: Secure session-based authentication with automatic redirects
6. **Responsive Design**: Mobile-friendly interface using Pico CSS

## Environment Variables

- `VITE_HOST`: Defines the CouchDB host URL (e.g., `http://client-notes.local:5900`)