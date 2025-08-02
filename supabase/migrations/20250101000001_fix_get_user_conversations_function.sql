-- Fix get_user_conversations function parameter name
-- The app calls it with 'p_user_id' but the function expects 'user_id'

CREATE OR REPLACE FUNCTION get_user_conversations(p_user_id UUID)
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
      WHEN c.participant_1_id = p_user_id THEN c.participant_2_id 
      ELSE c.participant_1_id 
    END as other_user_id,
    CASE 
      WHEN c.participant_1_id = p_user_id THEN p2.full_name 
      ELSE p1.full_name 
    END as other_user_name,
    CASE 
      WHEN c.participant_1_id = p_user_id THEN p2.avatar_url 
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
    WHERE is_read = FALSE AND sender_id != p_user_id
    GROUP BY conversation_id
  ) unread ON c.id = unread.conversation_id
  WHERE c.participant_1_id = p_user_id OR c.participant_2_id = p_user_id
  ORDER BY COALESCE(c.last_message_time, c.created_at) DESC;
END;
$$ LANGUAGE plpgsql;