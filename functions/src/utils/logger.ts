/**
 * Structured logger for Cloud Functions
 * Provides consistent logging across all functions with JSON formatting
 */

import * as functions from "firebase-functions";

export enum LogLevel {
  DEBUG = "debug",
  INFO = "info",
  WARNING = "warning",
  ERROR = "error",
}

export class Logger {
  static log(
    level: LogLevel,
    event: string,
    data?: Record<string, any>,
    error?: Error
  ): void {
    const logData = {
      timestamp: new Date().toISOString(),
      event,
      ...data,
    };

    switch (level) {
    case LogLevel.DEBUG:
      console.log("[DEBUG]", logData);
      break;
    case LogLevel.INFO:
      functions.logger.info(event, logData);
      break;
    case LogLevel.WARNING:
      functions.logger.warn(event, logData);
      break;
    case LogLevel.ERROR:
      functions.logger.error(event, {
        ...logData,
        error: error?.message,
        stack: error?.stack,
      });
      break;
    }
  }

  static info(event: string, data?: Record<string, any>): void {
    this.log(LogLevel.INFO, event, data);
  }

  static error(event: string, error: Error, data?: Record<string, any>): void {
    this.log(LogLevel.ERROR, event, data, error);
  }

  static warn(event: string, data?: Record<string, any>): void {
    this.log(LogLevel.WARNING, event, data);
  }

  static debug(event: string, data?: Record<string, any>): void {
    this.log(LogLevel.DEBUG, event, data);
  }
}
