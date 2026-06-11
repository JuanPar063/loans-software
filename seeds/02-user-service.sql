-- Seed: user-service (BD user-service-db, tabla profiles)
-- id_user referencia (lógicamente) a users.id_user de user-login.
-- monthly_income alimenta el chequeo de capacidad (loan-service) y el
-- análisis crediticio (admin-service). El teléfono debe ser +57XXXXXXXXXX y único.

INSERT INTO profiles (id_profile, id_user, first_name, last_name, document_type, document_number, phone, address, monthly_income) VALUES
  ('aaaa1111-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222',
   'Carlos', 'Gomez',  'CC', '1000000001', '+573010000001', 'Calle 10 # 5-21, Bogota', 5000000.00),
  ('aaaa1111-0000-0000-0000-000000000002', '33333333-3333-3333-3333-333333333333',
   'Maria',  'Lopez',  'CC', '1000000002', '+573010000002', 'Carrera 7 # 45-12, Medellin', 2500000.00),
  ('aaaa1111-0000-0000-0000-000000000003', '11111111-1111-1111-1111-111111111111',
   'Admin',  'Sistema','CC', '1000000099', '+573010000099', 'Oficina principal', 10000000.00)
ON CONFLICT (id_profile) DO NOTHING;
