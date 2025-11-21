-- Check events table structure
\d events

-- Check if any events exist (should be 0 right now)
SELECT COUNT(*) FROM events;

-- Check recent failed events (if any)
SELECT event_type, user_id, processing_error, received_at 
FROM events 
WHERE received_at > NOW() - INTERVAL '24 hours'
ORDER BY received_at DESC 
LIMIT 5;
