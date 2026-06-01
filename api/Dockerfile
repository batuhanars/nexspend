# syntax=docker/dockerfile:1

# =============================================================
# Stage 1 — Builder: bağımlılık kurulumu + Prisma client + build
# =============================================================
FROM node:24-bookworm-slim AS builder
WORKDIR /app

# bcrypt gibi native modüller kaynaktan derlenebilsin diye build araçları.
# openssl: Prisma şema motorunun ihtiyacı.
RUN apt-get update \
  && apt-get install -y --no-install-recommends python3 make g++ openssl ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Önce sadece bağımlılık manifestleri + Prisma şeması kopyalanır.
# Böylece kaynak kod değişince bu katman cache'ten gelir, npm ci yeniden çalışmaz.
COPY package*.json ./
COPY prisma.config.ts ./
COPY prisma ./prisma
RUN npm ci

# Prisma client üret (nest build'in tip kontrolü buna bağlı).
RUN npx prisma generate

# Kaynak kodun tamamı + production build (dist/ üretilir).
COPY . .
RUN npm run build

# =============================================================
# Stage 2 — Runner: yalın çalışma imajı (build araçları yok)
# =============================================================
FROM node:24-bookworm-slim AS runner
WORKDIR /app

ENV NODE_ENV=production
# PORT sabitlenmez: Railway gibi platformlar dinamik PORT enjekte eder; sabit 3000
# onu ezerse healthcheck/routing 502 verir. Lokal'de docker-compose PORT=3000 verir,
# yoksa uygulama app.config'te 3000'e düşer.

# Prisma şema motoru için runtime openssl.
RUN apt-get update \
  && apt-get install -y --no-install-recommends openssl ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Builder'da derlenmiş node_modules (native bcrypt + Prisma engine dahil) ve build çıktısı.
# migrate deploy için Prisma CLI node_modules içinde geldiğinden ayrıca kurulmaz.
COPY --from=builder --chown=node:node /app/node_modules ./node_modules
COPY --from=builder --chown=node:node /app/dist ./dist
COPY --from=builder --chown=node:node /app/prisma ./prisma
COPY --from=builder --chown=node:node /app/prisma.config.ts ./prisma.config.ts
COPY --from=builder --chown=node:node /app/package*.json ./

# Avatar/fiş görselleri buraya yazılıyor (compose'ta volume ile kalıcılaştırılır).
RUN mkdir -p /app/uploads && chown -R node:node /app/uploads

USER node
EXPOSE 3000

# Konteyner ayağa kalkınca: önce bekleyen migration'ları uygula, sonra uygulamayı başlat.
# db servisi healthcheck ile hazır beklendiği için bağlantı garanti.
# Not: kökteki prisma.config.ts + scripts/ de derlendiği için nest çıktısı dist/src/ altında.
CMD ["sh", "-c", "npx prisma migrate deploy && node dist/src/main"]
