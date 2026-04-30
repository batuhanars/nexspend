export default () => ({
  port: parseInt(process.env.PORT ?? '3000', 10),
  database: {
    url: process.env.DATABASE_URL,
  },
  jwt: {
    secret: process.env.JWT_SECRET,
    accessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN ?? '15m',
    refreshSecret: process.env.JWT_REFRESH_SECRET,
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN ?? '7d',
  },
  google: {
    clientId: process.env.GOOGLE_CLIENT_ID,
    clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    callbackUrl: process.env.GOOGLE_CALLBACK_URL,
  },
  mail: {
    host: process.env.MAIL_HOST,
    port: parseInt(process.env.MAIL_PORT ?? '587', 10),
    user: process.env.MAIL_USER,
    pass: process.env.MAIL_PASS,
    from: process.env.MAIL_FROM ?? 'noreply@stitch-wallet.app',
  },
  frontend: {
    url: process.env.FRONTEND_URL ?? 'http://localhost:3001',
  },
  storage: {
    uploadDir: process.env.UPLOAD_DIR ?? './uploads',
  },
  evds: {
    apiKey: process.env.EVDS_API_KEY,
    baseUrl:
      process.env.EVDS_BASE_URL ?? 'https://evds2.tcmb.gov.tr/service/evds/',
  },
  fcm: {
    serverKey: process.env.FCM_SERVER_KEY,
  },
});
