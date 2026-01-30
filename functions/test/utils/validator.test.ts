import { Validator } from '../../src/utils/validator';

describe('Validator', () => {
  describe('required', () => {
    it('should throw for undefined', () => {
      expect(() => Validator.required(undefined, 'field'))
        .toThrow('field is required');
    });

    it('should throw for null', () => {
      expect(() => Validator.required(null, 'field'))
        .toThrow('field is required');
    });

    it('should throw for empty string', () => {
      expect(() => Validator.required('', 'field'))
        .toThrow('field is required');
    });

    it('should not throw for valid value', () => {
      expect(() => Validator.required('value', 'field')).not.toThrow();
      expect(() => Validator.required(0, 'field')).not.toThrow();
      expect(() => Validator.required(false, 'field')).not.toThrow();
    });
  });

  describe('isString', () => {
    it('should throw for number', () => {
      expect(() => Validator.isString(123, 'field'))
        .toThrow('field must be a string');
    });

    it('should throw for object', () => {
      expect(() => Validator.isString({}, 'field'))
        .toThrow('field must be a string');
    });

    it('should not throw for string', () => {
      expect(() => Validator.isString('test', 'field')).not.toThrow();
    });
  });

  describe('isNumber', () => {
    it('should throw for string', () => {
      expect(() => Validator.isNumber('123', 'field'))
        .toThrow('field must be a number');
    });

    it('should throw for NaN', () => {
      expect(() => Validator.isNumber(NaN, 'field'))
        .toThrow('field must be a number');
    });

    it('should not throw for number', () => {
      expect(() => Validator.isNumber(123, 'field')).not.toThrow();
      expect(() => Validator.isNumber(0, 'field')).not.toThrow();
      expect(() => Validator.isNumber(-123, 'field')).not.toThrow();
    });
  });

  describe('isPositive', () => {
    it('should throw for zero', () => {
      expect(() => Validator.isPositive(0, 'field'))
        .toThrow('field must be positive');
    });

    it('should throw for negative', () => {
      expect(() => Validator.isPositive(-1, 'field'))
        .toThrow('field must be positive');
    });

    it('should not throw for positive number', () => {
      expect(() => Validator.isPositive(1, 'field')).not.toThrow();
      expect(() => Validator.isPositive(100, 'field')).not.toThrow();
    });
  });

  describe('inRange', () => {
    it('should throw for value below min', () => {
      expect(() => Validator.inRange(5, 10, 20, 'field'))
        .toThrow('field must be between 10 and 20');
    });

    it('should throw for value above max', () => {
      expect(() => Validator.inRange(25, 10, 20, 'field'))
        .toThrow('field must be between 10 and 20');
    });

    it('should not throw for value in range', () => {
      expect(() => Validator.inRange(15, 10, 20, 'field')).not.toThrow();
      expect(() => Validator.inRange(10, 10, 20, 'field')).not.toThrow();
      expect(() => Validator.inRange(20, 10, 20, 'field')).not.toThrow();
    });
  });

  describe('isValidDate', () => {
    it('should throw for invalid date string', () => {
      expect(() => Validator.isValidDate('not-a-date', 'field'))
        .toThrow('field must be a valid date');
    });

    it('should not throw for valid date string', () => {
      expect(() => Validator.isValidDate('2025-01-30', 'field')).not.toThrow();
      expect(() => Validator.isValidDate('2025-01-30T10:00:00Z', 'field')).not.toThrow();
    });
  });
});
