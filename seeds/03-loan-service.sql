-- Seed: loan-service (BD loans-service, tablas loans y payments)
-- user_id referencia (lógicamente) a users.id_user.
-- interest_rate es tasa MENSUAL (%). Los montos de payments son coherentes:
--   interés del periodo = remaining_balance * (interest_rate/100).

-- Préstamo 1: ACTIVO de seed.client1 (3.000.000 al 2% mensual, 12 meses, 2 pagos hechos)
-- Préstamo 2: PENDIENTE de seed.client2 (4.000.000, sin aprobar: interés 0)
-- Préstamo 3: PAGADO de seed.client1 (histórico para el análisis crediticio)

INSERT INTO loans (id, user_id, amount, interest_rate, status, loan_type, term_months, installment_value, payment_frequency, remaining_balance, created_at, approved_at) VALUES
  ('bbbb1111-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222',
   3000000.00, 2.00, 'activo', 'monthly_interest', 12, 280000.00, 'monthly',
   2000000.00, NOW() - INTERVAL '90 days', NOW() - INTERVAL '85 days'),
  ('bbbb1111-0000-0000-0000-000000000002', '33333333-3333-3333-3333-333333333333',
   4000000.00, 0.00, 'pendiente_aprobacion', 'fixed_installments', NULL, NULL, NULL,
   4000000.00, NOW() - INTERVAL '2 days', NULL),
  ('bbbb1111-0000-0000-0000-000000000003', '22222222-2222-2222-2222-222222222222',
   1000000.00, 2.00, 'pagado', 'monthly_interest', 6, 180000.00, 'monthly',
   0.00, NOW() - INTERVAL '300 days', NOW() - INTERVAL '295 days')
ON CONFLICT (id) DO NOTHING;

-- Pagos del préstamo 1 (saldo 3.000.000 → 2.500.000 → 2.000.000)
INSERT INTO payments (id, loan_id, amount_paid, interest_charged, capital_payment, remaining_balance, payment_date) VALUES
  ('cccc1111-0000-0000-0000-000000000001', 'bbbb1111-0000-0000-0000-000000000001',
   560000.00, 60000.00, 500000.00, 2500000.00, NOW() - INTERVAL '55 days'),
  ('cccc1111-0000-0000-0000-000000000002', 'bbbb1111-0000-0000-0000-000000000001',
   550000.00, 50000.00, 500000.00, 2000000.00, NOW() - INTERVAL '25 days'),
-- Pago final del préstamo 3 (histórico, quedó en 0)
  ('cccc1111-0000-0000-0000-000000000003', 'bbbb1111-0000-0000-0000-000000000003',
   1020000.00, 20000.00, 1000000.00, 0.00, NOW() - INTERVAL '200 days')
ON CONFLICT (id) DO NOTHING;
