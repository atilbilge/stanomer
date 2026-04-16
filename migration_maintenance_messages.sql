-- Create the maintenance_messages table
CREATE TABLE public.maintenance_messages (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  request_id uuid NOT NULL,
  user_id uuid NOT NULL,
  message text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT maintenance_messages_pkey PRIMARY KEY (id),
  CONSTRAINT maintenance_messages_request_id_fkey FOREIGN KEY (request_id) REFERENCES public.maintenance_requests(id) ON DELETE CASCADE,
  CONSTRAINT maintenance_messages_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE
);

-- Enable RLS
ALTER TABLE public.maintenance_messages ENABLE ROW LEVEL SECURITY;

-- Enable Realtime for the table
ALTER PUBLICATION supabase_realtime ADD TABLE public.maintenance_messages;

-- RLS Policies
-- Users can read messages if they are the reporter of the request, or the landlord of the property
CREATE POLICY "Users can view maintenance messages" 
ON public.maintenance_messages FOR SELECT 
USING (
  EXISTS (
    SELECT 1 FROM public.maintenance_requests r
    LEFT JOIN public.properties p ON p.id = r.property_id
    WHERE r.id = maintenance_messages.request_id
      AND (r.reporter_id = auth.uid() OR p.landlord_id = auth.uid())
  )
);

-- Users can insert messages if they are the reporter or landlord
CREATE POLICY "Users can insert maintenance messages" 
ON public.maintenance_messages FOR INSERT 
WITH CHECK (
  auth.uid() = user_id
  AND EXISTS (
    SELECT 1 FROM public.maintenance_requests r
    LEFT JOIN public.properties p ON p.id = r.property_id
    WHERE r.id = request_id
      AND (r.reporter_id = auth.uid() OR p.landlord_id = auth.uid())
  )
);
