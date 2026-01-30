/**
 * Date utility functions
 * Centralized date handling for consistency across functions
 */

export class DateUtils {
  /**
   * Formats a Date as YYYY-MM-DD
   */
  static formatDate(date: Date): string {
    const year = date.getUTCFullYear().toString().padStart(4, "0");
    const month = (date.getUTCMonth() + 1).toString().padStart(2, "0");
    const day = date.getUTCDate().toString().padStart(2, "0");
    return `${year}-${month}-${day}`;
  }

  /**
   * Gets today's date as YYYY-MM-DD
   */
  static getToday(): string {
    return this.formatDate(new Date());
  }

  /**
   * Parses YYYY-MM-DD string to Date
   */
  static parseDate(dateStr: string): Date {
    const parsed = Date.parse(dateStr);
    if (isNaN(parsed)) {
      throw new Error(`Invalid date format: ${dateStr}`);
    }
    return new Date(parsed);
  }
}
