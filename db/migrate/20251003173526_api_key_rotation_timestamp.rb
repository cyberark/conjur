# frozen_string_literal: true

Sequel.migration do
  up do
    execute "ALTER TABLE public.credentials
             ADD COLUMN updated_at timestamp without time zone;
             UPDATE public.credentials c
             SET updated_at = COALESCE(
               ( 
                 SELECT r.created_at 
                 FROM public.roles r
                 WHERE c.role_id = r.role_id
               ),
               NOW()
             );"
  end
end
