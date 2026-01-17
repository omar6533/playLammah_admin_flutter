/*
  # Create users table

  1. New Tables
    - `users`
      - `id` (uuid, primary key)
      - `first_name` (text) - User's first name
      - `last_name` (text) - User's last name
      - `email` (text, unique) - User's email address
      - `phone_number` (text) - User's phone number
      - `login_type` (text) - Login method (email, google, facebook, apple)
      - `games_played` (integer, default 0) - Count of games played
      - `created_at` (timestamptz) - Registration date
      - `updated_at` (timestamptz) - Last update timestamp

  2. Security
    - Enable RLS on `users` table
    - Add policy for reading all users (for admin dashboard)
*/

CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  first_name text NOT NULL,
  last_name text NOT NULL,
  email text UNIQUE NOT NULL,
  phone_number text DEFAULT '',
  login_type text NOT NULL DEFAULT 'email',
  games_played integer NOT NULL DEFAULT 0,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow read access to all users"
  ON users
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Allow insert for authenticated users"
  ON users
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

CREATE POLICY "Allow update for authenticated users"
  ON users
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);
