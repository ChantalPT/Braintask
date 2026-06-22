-- HU-11: Direct messaging between users
CREATE TABLE mensajes (
  id        BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  emisor_id   UUID    NOT NULL,
  receptor_id UUID    NOT NULL,
  contenido   TEXT    NOT NULL,
  leido       BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE mensajes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "usuarios pueden ver sus mensajes"
  ON mensajes FOR SELECT
  USING (auth.uid() = emisor_id OR auth.uid() = receptor_id);

CREATE POLICY "usuarios pueden enviar mensajes"
  ON mensajes FOR INSERT
  WITH CHECK (auth.uid() = emisor_id);

CREATE POLICY "receptores pueden marcar como leido"
  ON mensajes FOR UPDATE
  USING (auth.uid() = receptor_id);

ALTER PUBLICATION supabase_realtime ADD TABLE mensajes;
