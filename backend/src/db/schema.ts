import { getDb } from './database';

export function runMigrations(): void {
  const db = getDb();

  db.exec(`
    CREATE TABLE IF NOT EXISTS recipes (
      id          TEXT PRIMARY KEY,
      title       TEXT NOT NULL DEFAULT '',
      description TEXT NOT NULL DEFAULT '',
      portions    INTEGER NOT NULL DEFAULT 4,
      prep_time   TEXT NOT NULL DEFAULT '',
      cook_time   TEXT NOT NULL DEFAULT '',
      difficulty  TEXT NOT NULL DEFAULT 'einfach' CHECK (difficulty IN ('einfach', 'mittel', 'schwer')),
      cuisine     TEXT NOT NULL DEFAULT '',
      category    TEXT NOT NULL DEFAULT '',
      tags        TEXT NOT NULL DEFAULT '[]',
      ingredients TEXT NOT NULL DEFAULT '[]',
      steps       TEXT NOT NULL DEFAULT '[]',
      notes       TEXT NOT NULL DEFAULT '',
      image_url   TEXT,
      status      TEXT NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'complete')),
      created_at  TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at  TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE TABLE IF NOT EXISTS chat_messages (
      id          TEXT PRIMARY KEY,
      recipe_id   TEXT NOT NULL REFERENCES recipes(id) ON DELETE CASCADE,
      role        TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
      content     TEXT NOT NULL,
      proposal    TEXT,
      created_at  TEXT NOT NULL DEFAULT (datetime('now'))
    );

    CREATE INDEX IF NOT EXISTS idx_chat_messages_recipe_id ON chat_messages(recipe_id);
  `);

  // Add columns introduced after initial schema (safe to run multiple times)
  const columns = db.prepare(`PRAGMA table_info(recipes)`).all() as { name: string }[];
  const colNames = columns.map(c => c.name);
  if (!colNames.includes('cuisine')) {
    db.exec(`ALTER TABLE recipes ADD COLUMN cuisine TEXT NOT NULL DEFAULT ''`);
  }
  if (!colNames.includes('category')) {
    db.exec(`ALTER TABLE recipes ADD COLUMN category TEXT NOT NULL DEFAULT ''`);
  }

  console.log('Database migrations complete');
}
