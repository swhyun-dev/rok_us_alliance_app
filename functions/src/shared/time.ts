/// 일일 한도 검사용. KST(UTC+9) 자정 시각의 UTC 표현.
export function startOfTodayKst(): Date {
  const now = new Date();
  const utcMs = now.getTime();
  const kstOffsetMs = 9 * 60 * 60 * 1000;
  const kstNow = new Date(utcMs + kstOffsetMs);
  const kstMidnight = new Date(
    Date.UTC(
      kstNow.getUTCFullYear(),
      kstNow.getUTCMonth(),
      kstNow.getUTCDate(),
      0,
      0,
      0,
      0
    )
  );
  return new Date(kstMidnight.getTime() - kstOffsetMs);
}
