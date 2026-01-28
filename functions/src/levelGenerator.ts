/**
 * Level generator for daily challenges
 * Generates random hexagonal grid levels with obstacles
 */

export interface HexCell {
  q: number;
  r: number;
  isObstacle: boolean;
}

export interface Level {
  id: string;
  gridSize: number;
  difficulty: string;
  cells: HexCell[];
  startPosition: HexCell;
  endPosition: HexCell;
}

/**
 * Generates a random level for daily challenge
 * @param {string} date Date string to use as seed
 * @param {number} gridSize Size of the hexagonal grid
 * @return {Level} Generated level with obstacles
 */
export function generateLevel(date: string, gridSize = 8): Level {
  // Use date as seed for consistent daily generation
  const seed = hashCode(date);
  const random = seededRandom(seed);

  const cells: HexCell[] = [];

  // Generate hexagonal grid
  for (let q = 0; q < gridSize; q++) {
    for (let r = 0; r < gridSize; r++) {
      // Skip cells outside hexagonal shape
      if ((q + r) < gridSize || (q + r) >= gridSize * 2) {
        continue;
      }

      // Random 25% of cells are obstacles
      const isObstacle = random() < 0.25;

      cells.push({ q, r, isObstacle });
    }
  }

  // Define start and end positions (ensure not obstacles)
  const start: HexCell = { q: 0, r: gridSize - 1, isObstacle: false };
  const end: HexCell = { q: gridSize - 1, r: gridSize - 1, isObstacle: false };

  // Remove any existing cells at start/end positions
  const filteredCells = cells.filter(
    (c) => !((c.q === start.q && c.r === start.r) ||
             (c.q === end.q && c.r === end.r))
  );

  filteredCells.push(start, end);

  return {
    id: `daily-${date}`,
    gridSize,
    difficulty: "medium",
    cells: filteredCells,
    startPosition: start,
    endPosition: end,
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
