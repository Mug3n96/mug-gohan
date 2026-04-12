import Database from 'better-sqlite3';
import path from 'path';
import fs from 'fs';

const DATA_DIR = process.env.DATA_DIR ?? './data';
const DB_PATH = path.resolve(DATA_DIR, 'muggohan.db');

let db: Database.Database;

export function initDb(): void {
  fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });
  db = new Database(DB_PATH);
  db.pragma('journal_mode = WAL');
  db.pragma('foreign_keys = ON');
  console.log(`Database initialized at ${DB_PATH}`);
}

export function getDb(): Database.Database {
  if (!db) throw new Error('Database not initialized');
  return db;
}
