/**
 * Level generator for daily challenges
 * Generates hexagonal grid levels compatible with Flutter app format
 */

export interface HexCell {
  q: number;
  r: number;
  checkpoint?: number;
}

export interface HexEdge {
  cellQ1: number;
  cellR1: number;
  cellQ2: number;
  cellR2: number;
}

export interface Level {
  id: string;
  size: number;
  cells: HexCell[];
  walls: HexEdge[];
  checkpointCount: number;
}

/**
 * Generates a random level for daily challenge
 * @param {string} date Date string to use as seed
 * @param {number} size Size of the hexagonal grid
 * @return {Level} Generated level compatible with Flutter app
 */
export function generateLevel(date: string, size = 6): Level {
  // Use date as seed for consistent daily generation
  const seed = hashCode(date);
  const random = seededRandom(seed);

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

  // Generate random walls between cells (20% chance for each possible edge)
  for (let i = 0; i < cells.length; i++) {
    const cell = cells[i];

    // Check right neighbor
    if (cell.q < size - 1 && random() < 0.2) {
      walls.push({
        cellQ1: cell.q,
        cellR1: cell.r,
        cellQ2: cell.q + 1,
        cellR2: cell.r,
      });
    }

    // Check bottom-right neighbor
    if (cell.r < size - 1 && random() < 0.2) {
      walls.push({
        cellQ1: cell.q,
        cellR1: cell.r,
        cellQ2: cell.q,
        cellR2: cell.r + 1,
      });
    }
  }

  return {
    id: `daily-${date}`,
    size,
    cells,
    walls,
    checkpointCount: 2,
  };
}

/**
 * Simple hash function for string
 * @param {string} str String to hash
 * @return {number} Hash code
 */
function hashCode(str: string): number {
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
 * @param {number} seed Seed for random generation
 * @return {Function} Random function returning number 0-1
 */
function seededRandom(seed: number): () => number {
  let state = seed;
  return () => {
    state = (state * 1664525 + 1013904223) % 4294967296;
    return state / 4294967296;
  };
}
