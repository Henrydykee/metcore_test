# Notes API Server

Simple TypeScript Node.js server for the Notes API.

## Setup

1. Install dependencies:
```bash
npm install
```

2. Build TypeScript:
```bash
npm run build
```

3. Start the server:
```bash
npm start
```

Or run in development mode with auto-reload:
```bash
npm run dev
```

Or run with watch mode:
```bash
npm run watch
```

## API Endpoints

- `GET /v1/notes` - Get all notes
- `GET /v1/notes/:id` - Get a single note
- `POST /v1/notes` - Create a new note
- `PATCH /v1/notes/:id` - Update a note
- `DELETE /v1/notes/:id` - Delete a note

## Example Requests

### Create a note
```bash
curl -X POST http://localhost:8080/v1/notes \
  -H "Content-Type: application/json" \
  -d '{
    "title": "New Note",
    "body": "Note content",
    "tags": ["tag1", "tag2"]
  }'
```

### Get all notes
```bash
curl http://localhost:8080/v1/notes
```

### Update a note
```bash
curl -X PATCH http://localhost:8080/v1/notes/{id} \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Updated Title",
    "body": "Updated content"
  }'
```

### Delete a note
```bash
curl -X DELETE http://localhost:8080/v1/notes/{id}
```
