## Starting the React Client

Ensure the backend service is running before starting the client.  From the project root:

From the project root:

```bash
cd frontend
npm install      # only required on first setup
npm run dev
```

The development server will start (typically at [http://localhost:5173](http://localhost:5173)).  The frontend is configured to proxy API requests to the backend during development.

*Note:* Running the React-based client is optional, as a Haskell-based web app is accessible on the same port as the backend service.
