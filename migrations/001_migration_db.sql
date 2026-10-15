CREATE TABLE IF NOT EXISTS users (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  name          TEXT NOT NULL,
  email         TEXT NOT NULL UNIQUE COLLATE NOCASE,
  username      TEXT UNIQUE COLLATE NOCASE,
  phone         TEXT,
  password_hash TEXT NOT NULL,
  created_at    TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS cities (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  code         TEXT NOT NULL UNIQUE,          -- SBY, MLG, ...
  name         TEXT NOT NULL,                 -- Surabaya
  pickup_point TEXT NOT NULL                  -- Pool Pusat / Drop Point
);

CREATE TABLE IF NOT EXISTS vehicles (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  name       TEXT NOT NULL UNIQUE,            -- HiAce Premio (CS)
  subtitle   TEXT,                            -- Toyota HiAce Premio
  image_path TEXT,                            -- assets/images/hiace_premio.png
  seat_count INTEGER NOT NULL CHECK (seat_count > 0)
);

-- Jadwal tetap (template). Trip untuk tanggal tertentu dibuat otomatis saat dicari.
CREATE TABLE IF NOT EXISTS schedules (
  id                  INTEGER PRIMARY KEY AUTOINCREMENT,
  origin_city_id      INTEGER NOT NULL REFERENCES cities(id),
  destination_city_id INTEGER NOT NULL REFERENCES cities(id),
  vehicle_id          INTEGER NOT NULL REFERENCES vehicles(id),
  departure_time      TEXT NOT NULL,          -- 'HH:MM'
  arrival_time        TEXT NOT NULL,          -- 'HH:MM'
  price_per_pax       INTEGER NOT NULL CHECK (price_per_pax >= 0),
  is_active           INTEGER NOT NULL DEFAULT 1,
  CHECK (origin_city_id <> destination_city_id),
  UNIQUE (origin_city_id, destination_city_id, vehicle_id, departure_time)
);

CREATE TABLE IF NOT EXISTS trips (
  id          INTEGER PRIMARY KEY AUTOINCREMENT,
  schedule_id INTEGER NOT NULL REFERENCES schedules(id),
  travel_date TEXT NOT NULL,                  -- 'YYYY-MM-DD'
  UNIQUE (schedule_id, travel_date)
);

CREATE TABLE IF NOT EXISTS bookings (
  id             INTEGER PRIMARY KEY AUTOINCREMENT,
  booking_code   TEXT NOT NULL UNIQUE,        -- ST7K2M9Q
  invoice_number TEXT NOT NULL UNIQUE,        -- INV-20261006-0001
  user_id        INTEGER NOT NULL REFERENCES users(id),
  trip_id        INTEGER NOT NULL REFERENCES trips(id),
  status         TEXT NOT NULL DEFAULT 'pending'
                 CHECK (status IN ('pending','paid','cancelled','expired')),
  price_per_pax  INTEGER NOT NULL,
  seat_count     INTEGER NOT NULL CHECK (seat_count > 0),
  ticket_price   INTEGER NOT NULL,            -- price_per_pax * seat_count
  additional_fee INTEGER NOT NULL DEFAULT 0,
  total_payment  INTEGER NOT NULL,
  payment_method TEXT CHECK (payment_method IN ('qris','ovo','bank')),
  expires_at     TEXT NOT NULL,
  paid_at        TEXT,
  created_at     TEXT NOT NULL DEFAULT (datetime('now'))
);
CREATE INDEX IF NOT EXISTS idx_bookings_user ON bookings(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_bookings_status_exp ON bookings(status, expires_at);

-- Baris hanya ada selama kursi benar-benar terpakai (pending/paid).
-- UNIQUE(trip_id, seat_label) menjamin satu kursi tidak bisa dipesan dua kali.
CREATE TABLE IF NOT EXISTS booking_seats (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  booking_id INTEGER NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
  trip_id    INTEGER NOT NULL REFERENCES trips(id),
  seat_label TEXT NOT NULL,
  UNIQUE (trip_id, seat_label)
);

CREATE TABLE IF NOT EXISTS payments (
  id         INTEGER PRIMARY KEY AUTOINCREMENT,
  booking_id INTEGER NOT NULL REFERENCES bookings(id),
  method     TEXT NOT NULL CHECK (method IN ('qris','ovo','bank')),
  amount     INTEGER NOT NULL,
  status     TEXT NOT NULL CHECK (status IN ('success','failed')),
  reference  TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);
