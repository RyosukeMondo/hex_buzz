/**
 * Input validation utilities for Cloud Functions
 * Validates request parameters and throws HttpsError for invalid inputs
 */

import { HttpsError } from "firebase-functions/v2/https";

export class Validator {
  static required(value: any, field: string): void {
    if (value === undefined || value === null || value === "") {
      throw new HttpsError("invalid-argument", `${field} is required`);
    }
  }

  static isString(value: any, field: string): void {
    if (typeof value !== "string") {
      throw new HttpsError("invalid-argument", `${field} must be a string`);
    }
  }

  static isNumber(value: any, field: string): void {
    if (typeof value !== "number" || isNaN(value)) {
      throw new HttpsError("invalid-argument", `${field} must be a number`);
    }
  }

  static isPositive(value: number, field: string): void {
    if (value <= 0) {
      throw new HttpsError("invalid-argument", `${field} must be positive`);
    }
  }

  static inRange(value: number, min: number, max: number, field: string): void {
    if (value < min || value > max) {
      throw new HttpsError(
        "invalid-argument",
        `${field} must be between ${min} and ${max}`
      );
    }
  }

  static isValidDate(date: string, field: string): void {
    const parsed = Date.parse(date);
    if (isNaN(parsed)) {
      throw new HttpsError("invalid-argument", `${field} must be a valid date`);
    }
  }
}
