import express, { Request, Response } from 'express';
import cors from 'cors';
import { v4 as uuidv4 } from 'uuid';

const app = express();
const PORT = 8080;

// Middleware
app.use(cors());
app.use(express.json());

// In-memory storage (simple array)
interface Note {
  id: string;
  title: string;
  body: string;
  tags: string[];
  createdAt: string;
  updatedAt: string;
}

const notes: Note[] = [
  {
    id: '550e8400-e29b-41d4-a716-446655440000',
    title: 'My Field Note',
    body: 'Observed some interesting patterns...',
    tags: ['nature', 'assessment'],
    createdAt: '2026-01-27T20:20:45+01:00',
    updatedAt: '2026-01-27T20:20:45+01:00',
  },
];

// GET /v1/notes - Get all notes
app.get('/v1/notes', (req: Request, res: Response) => {
  res.json(notes);
});

// GET /v1/notes/:id - Get a single note
app.get('/v1/notes/:id', (req: Request, res: Response) => {
  const note = notes.find((n) => n.id === req.params.id);
  if (!note) {
    return res.status(404).json({ error: 'Note not found' });
  }
  res.json(note);
});

// POST /v1/notes - Create a new note
app.post('/v1/notes', (req: Request, res: Response) => {
  const { title, body, tags } = req.body;

  if (!title || !body) {
    return res.status(400).json({ error: 'Title and body are required' });
  }

  const now = new Date().toISOString();
  const newNote: Note = {
    id: uuidv4(),
    title,
    body,
    tags: tags || [],
    createdAt: now,
    updatedAt: now,
  };

  notes.push(newNote);
  res.status(201).json(newNote);
});

// PATCH /v1/notes/:id - Update a note
app.patch('/v1/notes/:id', (req: Request, res: Response) => {
  const noteIndex = notes.findIndex((n) => n.id === req.params.id);
  
  if (noteIndex === -1) {
    return res.status(404).json({ error: 'Note not found' });
  }

  const { title, body, tags, updatedAt } = req.body;
  const existingNote = notes[noteIndex];

  notes[noteIndex] = {
    ...existingNote,
    title: title ?? existingNote.title,
    body: body ?? existingNote.body,
    tags: tags ?? existingNote.tags,
    updatedAt: updatedAt ?? new Date().toISOString(),
  };

  res.json(notes[noteIndex]);
});

// DELETE /v1/notes/:id - Delete a note
app.delete('/v1/notes/:id', (req: Request, res: Response) => {
  const noteIndex = notes.findIndex((n) => n.id === req.params.id);
  
  if (noteIndex === -1) {
    return res.status(404).json({ error: 'Note not found' });
  }

  notes.splice(noteIndex, 1);
  res.status(204).send();
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📝 Notes API available at http://localhost:${PORT}/v1/notes`);
});
