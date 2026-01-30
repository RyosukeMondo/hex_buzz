import { LevelGeneratorService } from '../../src/services/levelGenerator';

describe('LevelGeneratorService', () => {
  let service: LevelGeneratorService;

  beforeEach(() => {
    service = new LevelGeneratorService();
  });

  describe('generateLevel', () => {
    it('should generate level with correct size', () => {
      const level = service.generateLevel('2025-01-30', 6);

      expect(level.size).toBe(6);
      expect(level.cells).toHaveLength(36); // 6x6 grid
      expect(level.checkpointCount).toBe(2);
    });

    it('should set start and end checkpoints', () => {
      const level = service.generateLevel('2025-01-30', 6);

      expect(level.cells[0].checkpoint).toBe(1);
      expect(level.cells[level.cells.length - 1].checkpoint).toBe(2);
    });

    it('should generate walls', () => {
      const level = service.generateLevel('2025-01-30', 6);

      expect(level.walls.length).toBeGreaterThan(0);
      expect(level.walls[0]).toHaveProperty('q1');
      expect(level.walls[0]).toHaveProperty('r1');
      expect(level.walls[0]).toHaveProperty('q2');
      expect(level.walls[0]).toHaveProperty('r2');
    });

    it('should generate consistent levels for same seed', () => {
      const level1 = service.generateLevel('2025-01-30', 6);
      const level2 = service.generateLevel('2025-01-30', 6);

      expect(level1.walls.length).toBe(level2.walls.length);
      expect(level1.cells.length).toBe(level2.cells.length);
    });

    it('should generate different levels for different seeds', () => {
      const level1 = service.generateLevel('2025-01-30', 6);
      const level2 = service.generateLevel('2025-01-31', 6);

      // With high probability, walls will be different
      expect(level1.walls.length !== level2.walls.length ||
             level1.walls[0].q1 !== level2.walls[0].q1).toBeTruthy();
    });
  });

  describe('generateChallenge', () => {
    it('should generate challenge with default options', async () => {
      const level = await service.generateChallenge();

      expect(level.size).toBe(6); // Medium difficulty default
      expect(level.cells.length).toBeGreaterThan(0);
      expect(level.walls.length).toBeGreaterThan(0);
    });

    it('should generate easy level', async () => {
      const level = await service.generateChallenge({ difficulty: 'easy' });

      expect(level.size).toBe(5); // Easy is smaller
    });

    it('should generate hard level', async () => {
      const level = await service.generateChallenge({ difficulty: 'hard' });

      expect(level.size).toBe(7); // Hard is larger
    });

    it('should respect custom size', async () => {
      const level = await service.generateChallenge({ size: 8 });

      expect(level.size).toBe(8);
      expect(level.cells).toHaveLength(64); // 8x8
    });
  });
});
