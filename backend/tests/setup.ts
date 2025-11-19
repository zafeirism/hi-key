import { beforeAll } from 'vitest';
import { config } from 'dotenv';

// Load environment variables for tests
beforeAll(() => {
  config({ path: '.env.local' });
});
