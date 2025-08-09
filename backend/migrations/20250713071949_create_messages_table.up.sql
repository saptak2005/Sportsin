-- Migration: create_messages_table (UP)
-- Created: 2025-07-13 07:19:49

CREATE TABLE IF NOT EXISTS "Messages" (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chat_room_id UUID NOT NULL,
    sent_from UUID NOT NULL,
    sent_at DATE NOT NULL,
    read_status BOOLEAN NOT NULL DEFAULT FALSE,
    content TEXT NOT NULL,
    FOREIGN KEY (chat_room_id) REFERENCES "ChatRoom"(id) ON DELETE CASCADE,
    FOREIGN KEY (sent_from) REFERENCES "User"(id) ON DELETE CASCADE
);

