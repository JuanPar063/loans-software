-- Seed: user-login (BD user-login-db, tabla users)
-- Contraseña de TODOS los usuarios seed: Password123!
-- (hash bcrypt cost 12 generado con el propio bcrypt del servicio)
-- UUIDs fijos para que coincidan con profiles/loans/metrics en las otras BD.

INSERT INTO users (id_user, username, password, email, role) VALUES
  ('11111111-1111-1111-1111-111111111111', 'seed.admin',
   '$2b$12$1KagA0wXx.EczXh0NGWB1elPWSb8xxdId8OTDjGoG8M88MCxG.ku6',
   'seed.admin@prestamos.test',  'admin'),
  ('22222222-2222-2222-2222-222222222222', 'seed.client1',
   '$2b$12$1KagA0wXx.EczXh0NGWB1elPWSb8xxdId8OTDjGoG8M88MCxG.ku6',
   'seed.client1@prestamos.test', 'client'),
  ('33333333-3333-3333-3333-333333333333', 'seed.client2',
   '$2b$12$1KagA0wXx.EczXh0NGWB1elPWSb8xxdId8OTDjGoG8M88MCxG.ku6',
   'seed.client2@prestamos.test', 'client'),
  ('44444444-4444-4444-4444-444444444444', 'seed.teller',
   '$2b$12$1KagA0wXx.EczXh0NGWB1elPWSb8xxdId8OTDjGoG8M88MCxG.ku6',
   'seed.teller@prestamos.test', 'teller')
ON CONFLICT (id_user) DO NOTHING;
