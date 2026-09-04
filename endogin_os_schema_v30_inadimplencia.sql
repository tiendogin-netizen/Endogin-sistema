-- v30: campo de inadimplência pro Dashboard Executivo (Dr. Caio/Dr. Vinícius).
--
-- A fonte "de verdade" é a Guru (plataforma de cobrança que a Endogin usa),
-- mas ainda não existe um webhook recebendo os eventos de cobrança atrasada/
-- assinatura cancelada por falta de pagamento dentro do Supabase — só o
-- `guru_transaction_id` em `referrals` (venda confirmada), não o status
-- contínuo do pagamento. Enquanto isso não é conectado automaticamente, a
-- CS marca manualmente quando o financeiro avisar.

alter table students
  add column if not exists is_delinquent boolean not null default false,
  add column if not exists delinquent_since date;

-- não precisa de policy nova: já coberto pela RLS de students (v9).

notify pgrst, 'reload schema';
