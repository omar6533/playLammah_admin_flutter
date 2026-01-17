/*
  # Transform Admin Panel to SeenJeem Game Structure
  
  ## Overview
  This migration transforms the admin panel database to support the SeenJeem game board structure,
  following a hierarchical organization: Main Categories → Sub Categories → Questions (200/400/600 points)
  
  ## Changes Made
  
  ### 1. Main Categories (Previously 'categories')
  - Rename existing 'categories' table to 'main_categories'
  - Add new fields:
    - `name_ar` (text, required) - Arabic name for the main category
    - `media_url` (text, optional) - Image/banner URL for the main category
    - `display_order` (integer) - Display order on the game board
    - `is_active` (boolean) - Active/inactive status
  - Remove old 'name' field (will be replaced by name_ar)
  
  ### 2. Sub Categories (NEW)
  - Create 'sub_categories' table under main categories
  - Fields:
    - `id` (uuid, primary key)
    - `main_category_id` (uuid, foreign key) - Links to parent main category
    - `name_ar` (text, required) - Arabic name for the sub category
    - `media_url` (text, required) - Icon/image shown on game board
    - `display_order` (integer) - Display order within parent category
    - `is_active` (boolean) - Active/inactive status
    - `created_at`, `updated_at` (timestamps)
  
  ### 3. Questions (RESTRUCTURED)
  - Remove multiple-choice fields (option_a, option_b, option_c, option_d, correct_answer)
  - Change category_id to sub_category_id (now links to sub categories)
  - Add new fields:
    - `question_text_ar` (text, required) - Question in Arabic
    - `answer_text_ar` (text, required) - Answer in Arabic
    - `question_media_url` (text, optional) - Media for question (image/video)
    - `answer_media_url` (text, optional) - Media for answer (image/video)
  - Update points field:
    - Must be one of: 200, 400, 600
    - Add constraint to enforce these values
  - Add unique constraint: (sub_category_id + points) must be unique
    - Ensures only ONE question per sub-category per point value
  - Rename 'status' field values to match: active/disabled/draft
  - Remove 'usage' field (not needed for SeenJeem structure)
  
  ## Data Migration Strategy
  - Backup all existing data before transformation
  - Clear questions table for fresh structure (old data preserved in backup)
  - Preserve existing category data during rename
  
  ## Security
  - Enable RLS on all new tables
  - Apply same security policies as original tables
*/

-- Step 0: Backup existing data
DO $$
BEGIN
  -- Backup questions
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'questions_backup_old_structure'
  ) THEN
    CREATE TABLE questions_backup_old_structure AS SELECT * FROM questions;
  END IF;
  
  -- Backup categories
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_name = 'categories_backup_old_structure'
  ) THEN
    CREATE TABLE categories_backup_old_structure AS SELECT * FROM categories;
  END IF;
END $$;

-- Step 0.5: Clear existing questions (they have incompatible structure)
TRUNCATE TABLE questions CASCADE;

-- Step 1: Create sub_categories table first (before modifying questions)
CREATE TABLE IF NOT EXISTS sub_categories (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  main_category_id uuid NOT NULL,
  name_ar text NOT NULL,
  media_url text NOT NULL,
  display_order integer NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Step 2: Rename categories to main_categories and restructure
ALTER TABLE IF EXISTS categories RENAME TO main_categories;

-- Add new columns to main_categories
DO $$
BEGIN
  -- Add name_ar column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'main_categories' AND column_name = 'name_ar'
  ) THEN
    ALTER TABLE main_categories ADD COLUMN name_ar text;
    -- Copy existing name to name_ar for data preservation
    UPDATE main_categories SET name_ar = name WHERE name_ar IS NULL;
    ALTER TABLE main_categories ALTER COLUMN name_ar SET NOT NULL;
  END IF;

  -- Add media_url column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'main_categories' AND column_name = 'media_url'
  ) THEN
    ALTER TABLE main_categories ADD COLUMN media_url text;
  END IF;

  -- Add display_order column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'main_categories' AND column_name = 'display_order'
  ) THEN
    ALTER TABLE main_categories ADD COLUMN display_order integer NOT NULL DEFAULT 0;
  END IF;

  -- Add is_active column
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'main_categories' AND column_name = 'is_active'
  ) THEN
    ALTER TABLE main_categories ADD COLUMN is_active boolean NOT NULL DEFAULT true;
    -- Migrate status to is_active
    UPDATE main_categories SET is_active = (status = 'active');
  END IF;
END $$;

-- Drop old 'name' column after copying to name_ar
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'main_categories' AND column_name = 'name'
  ) THEN
    ALTER TABLE main_categories DROP COLUMN name;
  END IF;
END $$;

-- Add foreign key for sub_categories
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'sub_categories_main_category_id_fkey'
  ) THEN
    ALTER TABLE sub_categories 
      ADD CONSTRAINT sub_categories_main_category_id_fkey 
      FOREIGN KEY (main_category_id) 
      REFERENCES main_categories(id) 
      ON DELETE CASCADE;
  END IF;
END $$;

-- Step 3: Restructure questions table
-- Add new columns to questions
DO $$
BEGIN
  -- Add sub_category_id
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'questions' AND column_name = 'sub_category_id'
  ) THEN
    ALTER TABLE questions ADD COLUMN sub_category_id uuid;
  END IF;

  -- Add question_text_ar
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'questions' AND column_name = 'question_text_ar'
  ) THEN
    ALTER TABLE questions ADD COLUMN question_text_ar text;
  END IF;

  -- Add answer_text_ar
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'questions' AND column_name = 'answer_text_ar'
  ) THEN
    ALTER TABLE questions ADD COLUMN answer_text_ar text;
  END IF;

  -- Add question_media_url
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'questions' AND column_name = 'question_media_url'
  ) THEN
    ALTER TABLE questions ADD COLUMN question_media_url text;
  END IF;

  -- Add answer_media_url
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'questions' AND column_name = 'answer_media_url'
  ) THEN
    ALTER TABLE questions ADD COLUMN answer_media_url text;
  END IF;
END $$;

-- Drop old constraints before adding new ones
ALTER TABLE questions DROP CONSTRAINT IF EXISTS questions_points_check;
ALTER TABLE questions DROP CONSTRAINT IF EXISTS questions_status_check;
ALTER TABLE questions DROP CONSTRAINT IF EXISTS questions_category_id_fkey;

-- Update points constraint to only allow 200, 400, 600
ALTER TABLE questions 
  ADD CONSTRAINT questions_points_check 
  CHECK (points IN (200, 400, 600));

-- Add status constraint to include 'draft'
ALTER TABLE questions 
  ADD CONSTRAINT questions_status_check 
  CHECK (status IN ('active', 'disabled', 'draft'));

-- Drop old multiple choice columns
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'questions' AND column_name = 'option_a') THEN
    ALTER TABLE questions DROP COLUMN option_a;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'questions' AND column_name = 'option_b') THEN
    ALTER TABLE questions DROP COLUMN option_b;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'questions' AND column_name = 'option_c') THEN
    ALTER TABLE questions DROP COLUMN option_c;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'questions' AND column_name = 'option_d') THEN
    ALTER TABLE questions DROP COLUMN option_d;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'questions' AND column_name = 'correct_answer') THEN
    ALTER TABLE questions DROP COLUMN correct_answer;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'questions' AND column_name = 'usage') THEN
    ALTER TABLE questions DROP COLUMN usage;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'questions' AND column_name = 'category_id') THEN
    ALTER TABLE questions DROP COLUMN category_id;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'questions' AND column_name = 'question_text') THEN
    ALTER TABLE questions DROP COLUMN question_text;
  END IF;
END $$;

-- Set default points value
ALTER TABLE questions ALTER COLUMN points SET DEFAULT 200;

-- Add foreign key for questions to sub_categories
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'questions_sub_category_id_fkey'
  ) THEN
    ALTER TABLE questions 
      ADD CONSTRAINT questions_sub_category_id_fkey 
      FOREIGN KEY (sub_category_id) 
      REFERENCES sub_categories(id) 
      ON DELETE CASCADE;
  END IF;
END $$;

-- Add unique constraint: one question per sub-category per point value
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints 
    WHERE constraint_name = 'questions_sub_category_points_unique'
  ) THEN
    ALTER TABLE questions 
      ADD CONSTRAINT questions_sub_category_points_unique 
      UNIQUE (sub_category_id, points);
  END IF;
END $$;

-- Step 4: Enable RLS on new tables
ALTER TABLE sub_categories ENABLE ROW LEVEL SECURITY;

-- Step 5: Create RLS policies for sub_categories
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE policyname = 'Allow read access to all sub_categories'
  ) THEN
    CREATE POLICY "Allow read access to all sub_categories"
      ON sub_categories
      FOR SELECT
      TO authenticated
      USING (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE policyname = 'Allow insert for authenticated users' AND tablename = 'sub_categories'
  ) THEN
    CREATE POLICY "Allow insert for authenticated users"
      ON sub_categories
      FOR INSERT
      TO authenticated
      WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE policyname = 'Allow update for authenticated users' AND tablename = 'sub_categories'
  ) THEN
    CREATE POLICY "Allow update for authenticated users"
      ON sub_categories
      FOR UPDATE
      TO authenticated
      USING (true)
      WITH CHECK (true);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE policyname = 'Allow delete for authenticated users' AND tablename = 'sub_categories'
  ) THEN
    CREATE POLICY "Allow delete for authenticated users"
      ON sub_categories
      FOR DELETE
      TO authenticated
      USING (true);
  END IF;
END $$;

-- Step 6: Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_sub_categories_main_category_id 
  ON sub_categories(main_category_id);

CREATE INDEX IF NOT EXISTS idx_sub_categories_display_order 
  ON sub_categories(display_order);

CREATE INDEX IF NOT EXISTS idx_questions_sub_category_id 
  ON questions(sub_category_id);

CREATE INDEX IF NOT EXISTS idx_questions_points 
  ON questions(points);

CREATE INDEX IF NOT EXISTS idx_main_categories_display_order 
  ON main_categories(display_order);

-- Step 7: Create storage bucket for media (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES ('seenjeem-media', 'seenjeem-media', true)
ON CONFLICT (id) DO NOTHING;

-- Step 8: Create storage policy for public read access
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE policyname = 'Public read access for seenjeem media'
  ) THEN
    CREATE POLICY "Public read access for seenjeem media"
      ON storage.objects FOR SELECT
      USING (bucket_id = 'seenjeem-media');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE policyname = 'Authenticated users can upload media'
  ) THEN
    CREATE POLICY "Authenticated users can upload media"
      ON storage.objects FOR INSERT
      TO authenticated
      WITH CHECK (bucket_id = 'seenjeem-media');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE policyname = 'Authenticated users can update media'
  ) THEN
    CREATE POLICY "Authenticated users can update media"
      ON storage.objects FOR UPDATE
      TO authenticated
      USING (bucket_id = 'seenjeem-media')
      WITH CHECK (bucket_id = 'seenjeem-media');
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE policyname = 'Authenticated users can delete media'
  ) THEN
    CREATE POLICY "Authenticated users can delete media"
      ON storage.objects FOR DELETE
      TO authenticated
      USING (bucket_id = 'seenjeem-media');
  END IF;
END $$;
