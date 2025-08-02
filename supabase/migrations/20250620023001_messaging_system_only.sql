-- Messaging System Migration - Only New Elements
-- This migration adds the new messaging schema without touching existing tables

-- Create conversations table (new)
CREATE TABLE IF NOT EXISTS conversations (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  participant_1_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  participant_2_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  last_message_id UUID,
  last_message_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Ensure unique conversation between two users
  UNIQUE(participant_1_id, participant_2_id)
);

-- Add new columns to existing messages table
DO $$ 
BEGIN
  -- Add conversation_id column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'messages' AND column_name = 'conversation_id') THEN
    ALTER TABLE messages ADD COLUMN conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE;
  END IF;
  
  -- Add message_type column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'messages' AND column_name = 'message_type') THEN
    ALTER TABLE messages ADD COLUMN message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image'));
  END IF;
  
  -- Add image_url column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'messages' AND column_name = 'image_url') THEN
    ALTER TABLE messages ADD COLUMN image_url TEXT;
  END IF;
  
  -- Add is_read column if it doesn't exist (rename from 'read' if needed)
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'messages' AND column_name = 'is_read') THEN
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'messages' AND column_name = 'read') THEN
      ALTER TABLE messages RENAME COLUMN "read" TO is_read;
    ELSE
      ALTER TABLE messages ADD COLUMN is_read BOOLEAN DEFAULT FALSE;
    END IF;
  END IF;
  
  -- Add updated_at column if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                 WHERE table_name = 'messages' AND column_name = 'updated_at') THEN
    ALTER TABLE messages ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
  END IF;
END $$;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_conversations_participants ON conversations(participant_1_id, participant_2_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message ON conversations(last_message_time DESC);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_unread ON messages(conversation_id, is_read) WHERE is_read = FALSE;

-- Function to get or create conversation between two users
CREATE OR REPLACE FUNCTION get_or_create_conversation(user1_id UUID, user2_id UUID)
RETURNS UUID AS $$
DECLARE
  conversation_id UUID;
  ordered_user1 UUID;
  ordered_user2 UUID;
BEGIN
  -- Ensure consistent ordering to avoid duplicates
  IF user1_id < user2_id THEN
    ordered_user1 := user1_id;
    ordered_user2 := user2_id;
  ELSE
    ordered_user1 := user2_id;
    ordered_user2 := user1_id;
  END IF;
  
  -- Try to find existing conversation
  SELECT id INTO conversation_id
  FROM conversations
  WHERE participant_1_id = ordered_user1 AND participant_2_id = ordered_user2;
  
  -- If not found, create new conversation
  IF conversation_id IS NULL THEN
    INSERT INTO conversations (participant_1_id, participant_2_id)
    VALUES (ordered_user1, ordered_user2)
    RETURNING id INTO conversation_id;
  END IF;
  
  RETURN conversation_id;
END;
$$ LANGUAGE plpgsql;

-- Function to update conversation last message
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE conversations
  SET 
    last_message_id = NEW.id,
    last_message_time = NEW.created_at,
    updated_at = NOW()
  WHERE id = NEW.conversation_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update conversation when new message is sent
DROP TRIGGER IF EXISTS trigger_update_conversation_last_message ON messages;
CREATE TRIGGER trigger_update_conversation_last_message
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_last_message();

-- Enable RLS on conversations table
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- RLS Policies for conversations (only add if they don't exist)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'conversations' 
    AND policyname = 'Users can view their own conversations'
  ) THEN
    CREATE POLICY "Users can view their own conversations" ON conversations
      FOR SELECT USING (
        auth.uid() = participant_1_id OR auth.uid() = participant_2_id
      );
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'conversations' 
    AND policyname = 'Users can create conversations'
  ) THEN
    CREATE POLICY "Users can create conversations" ON conversations
      FOR INSERT WITH CHECK (
        auth.uid() = participant_1_id OR auth.uid() = participant_2_id
      );
  END IF;
  
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies 
    WHERE tablename = 'conversations' 
    AND policyname = 'Users can update their own conversations'
  ) THEN
    CREATE POLICY "Users can update their own conversations" ON conversations
      FOR UPDATE USING (
        auth.uid() = participant_1_id OR auth.uid() = participant_2_id
      );
  END IF;
END $$;

-- Update RLS policies for messages to work with conversations
DO $$
BEGIN
  -- Drop old policies if they exist
  DROP POLICY IF EXISTS "Users can view messages in their conversations" ON messages;
  DROP POLICY IF EXISTS "Users can send messages" ON messages;
  DROP POLICY IF EXISTS "Users can update their own messages" ON messages;
  
  -- Create new policies
  CREATE POLICY "Users can view messages in their conversations" ON messages
    FOR SELECT USING (
      conversation_id IS NULL OR
      EXISTS (
        SELECT 1 FROM conversations 
        WHERE id = conversation_id 
        AND (participant_1_id = auth.uid() OR participant_2_id = auth.uid())
      )
    );

  CREATE POLICY "Users can send messages" ON messages
    FOR INSERT WITH CHECK (
      auth.uid() = sender_id AND (
        conversation_id IS NULL OR
        EXISTS (
          SELECT 1 FROM conversations 
          WHERE id = conversation_id 
          AND (participant_1_id = auth.uid() OR participant_2_id = auth.uid())
        )
      )
    );

  CREATE POLICY "Users can update their own messages" ON messages
    FOR UPDATE USING (auth.uid() = sender_id);
END $$;

-- Create function to get conversations with user details and unread counts
CREATE OR REPLACE FUNCTION get_user_conversations(user_id UUID)
RETURNS TABLE (
  conversation_id UUID,
  other_user_id UUID,
  other_user_name TEXT,
  other_user_avatar TEXT,
  last_message TEXT,
  last_message_time TIMESTAMP WITH TIME ZONE,
  unread_count BIGINT,
  message_type TEXT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    c.id as conversation_id,
    CASE 
      WHEN c.participant_1_id = user_id THEN c.participant_2_id 
      ELSE c.participant_1_id 
    END as other_user_id,
    CASE 
      WHEN c.participant_1_id = user_id THEN p2.full_name 
      ELSE p1.full_name 
    END as other_user_name,
    CASE 
      WHEN c.participant_1_id = user_id THEN p2.avatar_url 
      ELSE p1.avatar_url 
    END as other_user_avatar,
    COALESCE(m.content, 
      CASE WHEN m.message_type = 'image' THEN '📷 Image' ELSE 'No messages yet' END
    ) as last_message,
    COALESCE(c.last_message_time, c.created_at) as last_message_time,
    COALESCE(unread.count, 0) as unread_count,
    COALESCE(m.message_type, 'text') as message_type
  FROM conversations c
  LEFT JOIN profiles p1 ON c.participant_1_id = p1.id
  LEFT JOIN profiles p2 ON c.participant_2_id = p2.id
  LEFT JOIN messages m ON c.last_message_id = m.id
  LEFT JOIN (
    SELECT 
      conversation_id, 
      COUNT(*) as count
    FROM messages 
    WHERE is_read = FALSE AND sender_id != user_id
    GROUP BY conversation_id
  ) unread ON c.id = unread.conversation_id
  WHERE c.participant_1_id = user_id OR c.participant_2_id = user_id
  ORDER BY COALESCE(c.last_message_time, c.created_at) DESC;
END;
$$ LANGUAGE plpgsql;

-- Create storage bucket for message images (if it doesn't exist)
DO $$
BEGIN
  INSERT INTO storage.buckets (id, name, public)
  VALUES ('messages', 'messages', true)
  ON CONFLICT (id) DO NOTHING;
END $$; 