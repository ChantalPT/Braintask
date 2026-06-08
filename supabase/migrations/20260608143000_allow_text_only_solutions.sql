-- Permite subir soluciones solo con explicacion escrita, sin archivo adjunto.

alter table public.soluciones
alter column archivo_url drop not null;
