-- Clean Messaging System Migration
-- Apply this in your Supabase SQL Editor

-- 1. Create conversations table
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

-- 2. Add new columns to messages table
ALTER TABLE messages ADD COLUMN IF NOT EXISTS conversation_id UUID REFERENCES conversations(id) ON DELETE CASCADE;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS message_type VARCHAR(20) DEFAULT 'text';
ALTER TABLE messages ADD COLUMN IF NOT EXISTS image_url TEXT;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS is_read BOOLEAN DEFAULT FALSE;
ALTER TABLE messages ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 3. Add check constraint for message_type
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_message_type_check;
ALTER TABLE messages ADD CONSTRAINT messages_message_type_check CHECK (message_type IN ('text', 'image'));

-- 4. Create indexes
CREATE INDEX IF NOT EXISTS idx_conversations_participants ON conversations(participant_1_id, participant_2_id);
CREATE INDEX IF NOT EXISTS idx_conversations_last_message ON conversations(last_message_time DESC);
CREATE INDEX IF NOT EXISTS idx_messages_conversation ON messages(conversation_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_unread ON messages(conversation_id, is_read) WHERE is_read = FALSE;

-- 5. Function to get or create conversation
CREATE OR REPLACE FUNCTION get_or_create_conversation(user1_id UUID, user2_id UUID)
RETURNS UUID AS $$
DECLARE
  conversation_id UUID;
  ordered_user1 UUID;
  ordered_user2 UUID;
BEGIN
  -- Ensure consistent ordering
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

-- 6. Function to update conversation last message
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

-- 7. Create trigger
DROP TRIGGER IF EXISTS trigger_update_conversation_last_message ON messages;
CREATE TRIGGER trigger_update_conversation_last_message
  AFTER INSERT ON messages
  FOR EACH ROW
  EXECUTE FUNCTION update_conversation_last_message();

-- 8. Enable RLS
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;

-- 9. Create RLS policies for conversations
DROP POLICY IF EXISTS "Users can view their own conversations" ON conversations;
CREATE POLICY "Users can view their own conversations" ON conversations
  FOR SELECT USING (
    auth.uid() = participant_1_id OR auth.uid() = participant_2_id
  );

DROP POLICY IF EXISTS "Users can create conversations" ON conversations;
CREATE POLICY "Users can create conversations" ON conversations
  FOR INSERT WITH CHECK (
    auth.uid() = participant_1_id OR auth.uid() = participant_2_id
  );

DROP POLICY IF EXISTS "Users can update their own conversations" ON conversations;
CREATE POLICY "Users can update their own conversations" ON conversations
  FOR UPDATE USING (
    auth.uid() = participant_1_id OR auth.uid() = participant_2_id
  );

-- 10. Update messages RLS policies
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON messages;
CREATE POLICY "Users can view messages in their conversations" ON messages
  FOR SELECT USING (
    conversation_id IS NULL OR
    EXISTS (
      SELECT 1 FROM conversations 
      WHERE id = conversation_id 
      AND (participant_1_id = auth.uid() OR participant_2_id = auth.uid())
    )
  );

DROP POLICY IF EXISTS "Users can send messages" ON messages;
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

DROP POLICY IF EXISTS "Users can update their own messages" ON messages;
CREATE POLICY "Users can update their own messages" ON messages
  FOR UPDATE USING (auth.uid() = sender_id);

-- 11. Function to get user conversations
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

-- 12. Create storage bucket for message images
INSERT INTO storage.buckets (id, name, public)
VALUES ('messages', 'messages', true)
ON CONFLICT (id) DO NOTHING;

-- 13. Create storage policies
DROP POLICY IF EXISTS "Users can upload message images" ON storage.objects;
CREATE POLICY "Users can upload message images" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'messages' AND
    auth.uid()::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS "Users can view message images" ON storage.objects;
CREATE POLICY "Users can view message images" ON storage.objects
  FOR SELECT USING (bucket_id = 'messages'); 