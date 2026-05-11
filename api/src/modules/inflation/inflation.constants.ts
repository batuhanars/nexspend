export const EVDS_SERIES_MAP = {
  genel: 'TP.FG.J0',
  gida: 'TP.FG.J01',
  alkol_tutun: 'TP.FG.J02',
  giyim: 'TP.FG.J03',
  konut: 'TP.FG.J04',
  mobilya: 'TP.FG.J05',
  saglik: 'TP.FG.J06',
  ulasim: 'TP.FG.J07',
  haberlesme: 'TP.FG.J08',
  eglence: 'TP.FG.J09',
  egitim: 'TP.FG.J10',
  lokanta: 'TP.FG.J11',
  diger: 'TP.FG.J12',
} as const;

export type InflationCategoryKey = keyof typeof EVDS_SERIES_MAP;
