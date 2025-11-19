import { describe, it, expect, beforeAll, afterAll } from 'vitest';
import { uploadImage, getSignedImageUrl, deleteImage } from '../r2';

// Skip these tests in CI or when R2 credentials aren't available
const shouldRunIntegrationTests = process.env.R2_ACCESS_KEY_ID && process.env.R2_SECRET_ACCESS_KEY;

describe.skipIf(!shouldRunIntegrationTests)('R2 Integration Tests', () => {
  const testUserId = 'test-user-123';
  const testGenerationId = `test-gen-${Date.now()}`; // Unique ID to avoid conflicts
  let uploadedKey: string;

  // Create a simple test image (1x1 red pixel PNG)
  const createTestImage = (): Buffer => {
    // This is a valid 1x1 red pixel PNG in base64
    const base64PNG =
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8DwHwAFBQIAX8jx0gAAAABJRU5ErkJggg==';
    return Buffer.from(base64PNG, 'base64');
  };

  beforeAll(() => {
    console.log('Running R2 integration tests...');
    console.log('Test generation ID:', testGenerationId);
  });

  it('should upload an image to R2 and return a signed URL', async () => {
    const testBuffer = createTestImage();

    const result = await uploadImage(testBuffer, testUserId, testGenerationId, 'png');

    // Store key for cleanup
    uploadedKey = result.key;

    // Verify the result structure
    expect(result).toHaveProperty('key');
    expect(result).toHaveProperty('url');
    expect(result.key).toBe(`users/${testUserId}/images/${testGenerationId}.png`);
    expect(result.url).toContain(testGenerationId);
    expect(result.url).toContain('X-Amz-Signature'); // Signed URL indicator

    console.log('✓ Image uploaded successfully');
    console.log('  Key:', result.key);
    console.log('  URL:', result.url.substring(0, 100) + '...');
  }, 30000); // 30 second timeout for upload

  it('should generate a signed URL for an existing image', async () => {
    expect(uploadedKey).toBeDefined();

    const signedUrl = await getSignedImageUrl(uploadedKey, 3600); // 1 hour expiry

    expect(signedUrl).toBeTruthy();
    expect(signedUrl).toContain(uploadedKey.split('/').pop()); // Should contain filename
    expect(signedUrl).toContain('X-Amz-Signature');

    console.log('✓ Signed URL generated successfully');
  }, 10000);

  it('should fetch the uploaded image via signed URL', async () => {
    const signedUrl = await getSignedImageUrl(uploadedKey);

    // Try to fetch the image
    const response = await fetch(signedUrl);

    expect(response.ok).toBe(true);
    expect(response.status).toBe(200);
    expect(response.headers.get('content-type')).toBe('image/png');

    const buffer = await response.arrayBuffer();
    expect(buffer.byteLength).toBeGreaterThan(0);

    console.log('✓ Image successfully fetched from R2');
    console.log('  Content-Type:', response.headers.get('content-type'));
    console.log('  Size:', buffer.byteLength, 'bytes');
  }, 15000);

  // Cleanup: delete test image after all tests
  afterAll(async () => {
    if (uploadedKey) {
      try {
        await deleteImage(uploadedKey);
        console.log('✓ Test image cleaned up:', uploadedKey);
      } catch (error) {
        console.error('Failed to cleanup test image:', error);
      }
    }
  });
});
