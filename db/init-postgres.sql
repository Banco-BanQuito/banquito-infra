-- ══════════════════════════════════════════════════════════════════════════════
-- BanQuito V2 — Script de inicialización de PostgreSQL
-- Se ejecuta AUTOMÁTICAMENTE cuando el contenedor arranca por primera vez.
-- accountdb ya fue creada por la variable POSTGRES_DB del docker-compose.
-- ══════════════════════════════════════════════════════════════════════════════

-- Bryan — accounting-service
CREATE DATABASE accountingdb;

-- Santiago — party-service
CREATE DATABASE partydb;

-- Alan — file-reception-service
CREATE DATABASE filedb;

-- Johan — tariff-service
CREATE DATABASE tariffdb;
