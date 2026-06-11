-- Seed: admin-service (BD admin_service_db, tablas metrics, audit_logs, reports)
-- user_id / admin_id referencian (lógicamente) a users.id_user de user-login.

INSERT INTO metrics (id, user_id, credit_score, pending_loans, total_loans, risk_level) VALUES
  ('dddd1111-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222',
   78, 1, 2, 'low'),
  ('dddd1111-0000-0000-0000-000000000002', '33333333-3333-3333-3333-333333333333',
   55, 1, 1, 'medium')
ON CONFLICT (id) DO NOTHING;

INSERT INTO audit_logs (id, admin_id, user_id, action, details) VALUES
  ('eeee1111-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111',
   '22222222-2222-2222-2222-222222222222', 'LOAN_APPROVED',
   '{"loanId":"bbbb1111-0000-0000-0000-000000000001","interestRate":2.0,"termMonths":12}'),
  ('eeee1111-0000-0000-0000-000000000002', '11111111-1111-1111-1111-111111111111',
   '33333333-3333-3333-3333-333333333333', 'METRICS_RECALCULATED',
   '{"creditScore":55,"riskLevel":"medium"}')
ON CONFLICT (id) DO NOTHING;

INSERT INTO reports (id, period, total_clients_high_risk, average_credit_score, total_pending_loans) VALUES
  ('ffff1111-0000-0000-0000-000000000001', '2026-05', 0, 66.5, 1)
ON CONFLICT (id) DO NOTHING;
