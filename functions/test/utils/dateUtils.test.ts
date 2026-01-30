import { DateUtils } from '../../src/utils/dateUtils';

describe('DateUtils', () => {
  describe('formatDate', () => {
    it('should format date as YYYY-MM-DD', () => {
      const date = new Date('2025-01-30T12:00:00Z');
      expect(DateUtils.formatDate(date)).toBe('2025-01-30');
    });

    it('should pad single digit month and day', () => {
      const date = new Date('2025-01-05T12:00:00Z');
      expect(DateUtils.formatDate(date)).toBe('2025-01-05');
    });
  });

  describe('getToday', () => {
    it('should return today as YYYY-MM-DD', () => {
      const result = DateUtils.getToday();
      expect(result).toMatch(/^\d{4}-\d{2}-\d{2}$/);
    });
  });

  describe('parseDate', () => {
    it('should parse valid date string', () => {
      const result = DateUtils.parseDate('2025-01-30');
      expect(result).toBeInstanceOf(Date);
      expect(result.getTime()).toBeGreaterThan(0);
    });

    it('should throw for invalid date string', () => {
      expect(() => DateUtils.parseDate('invalid'))
        .toThrow('Invalid date format: invalid');
    });
  });
});
