/**
 * Level generator service
 * Generates hexagonal grid levels for daily challenges
 */

import { Logger } from "../utils/logger";
import { Level, HexCell, HexEdge, LevelGenerationOptions } from "../types/challenge";

export class LevelGeneratorService {
  /**
   * Generates a level based on options
   */
  async generateChallenge(options: LevelGenerationOptions = {}): Promise<Level> {
    const difficulty = options.difficulty || "medium";
    const size = options.size || this.getSizeForDifficulty(difficulty);
    const wallDensity = options.wallDensity || this.getWallDensityForDifficulty(difficulty);

    Logger.info("generating_level", { difficulty, size, wallDensity });

    const level = this.generateLevel(new Date().toISOString(), size, wallDensity);

    Logger.info("level_generated", {
      levelId: level.id,
      cellCount: level.cells.length,
      wallCount: level.walls.length,
    });

    return level;
  }

  /**
   * Generates a level with specific parameters
   */
  generateLevel(seed: string, size = 6, wallDensity = 0.2): Level {
    const random = this.seededRandom(this.hashCode(seed));

    const cells: HexCell[] = [];
    const walls: HexEdge[] = [];

    // Generate hexagonal grid cells
    for (let q = 0; q < size; q++) {
      for (let r = 0; r < size; r++) {
        cells.push({ q, r });
      }
    }

    // Set checkpoints: first cell as checkpoint 1, last as checkpoint 2
    cells[0].checkpoint = 1; // Start
    cells[cells.length - 1].checkpoint = 2; // End

    // Generate random walls between cells
    for (let i = 0; i < cells.length; i++) {
      const cell = cells[i];

      // Check right neighbor
      if (cell.q < size - 1 && random() < wallDensity) {
        walls.push({
          q1: cell.q,
          r1: cell.r,
          q2: cell.q + 1,
          r2: cell.r,
        });
      }

      // Check bottom-right neighbor
      if (cell.r < size - 1 && random() < wallDensity) {
        walls.push({
          q1: cell.q,
          r1: cell.r,
          q2: cell.q,
          r2: cell.r + 1,
        });
      }
    }

    return {
      id: `daily-${seed}`,
      size,
      cells,
      walls,
      checkpointCount: 2,
    };
  }

  /**
   * Get grid size based on difficulty
   */
  private getSizeForDifficulty(difficulty: string): number {
    switch (difficulty) {
    case "easy":
      return 5;
    case "hard":
      return 7;
    default:
      return 6;
    }
  }

  /**
   * Get wall density based on difficulty
   */
  private getWallDensityForDifficulty(difficulty: string): number {
    switch (difficulty) {
    case "easy":
      return 0.1;
    case "hard":
      return 0.3;
    default:
      return 0.2;
    }
  }

  /**
   * Simple hash function for string
   */
  private hashCode(str: string): number {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32bit integer
    }
    return Math.abs(hash);
  }

  /**
   * Seeded random number generator
   */
  private seededRandom(seed: number): () => number {
    let state = seed;
    return () => {
      state = (state * 1664525 + 1013904223) % 4294967296;
      return state / 4294967296;
    };
  }
}
