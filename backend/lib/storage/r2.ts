import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';

// Initialize S3 client configured for Cloudflare R2
const r2Client = new S3Client({
  region: 'auto', // R2 uses 'auto' for automatic region selection
  endpoint: process.env.R2_ENDPOINT,
  credentials: {
    accessKeyId: process.env.R2_ACCESS_KEY_ID!,
    secretAccessKey: process.env.R2_SECRET_ACCESS_KEY!,
  },
});

const BUCKET_NAME = process.env.R2_BUCKET_NAME!;

/**
 * Uploads an image buffer to R2
 * @param buffer - Image data as Buffer
 * @param userId - User ID for path organization
 * @param generationId - Generation ID for unique filename
 * @param fileExtension - File extension (e.g., 'png', 'jpg', 'webp')
 * @returns Object with key and signed URL
 */
export async function uploadImage(
  buffer: Buffer,
  userId: string,
  generationId: string,
  fileExtension: string
): Promise<{ key: string; url: string }> {
  const key = getKey(userId, generationId, fileExtension);

  // Determine content type based on extension
  const contentType = getContentType(fileExtension);

  // Upload to R2
  const command = new PutObjectCommand({
    Bucket: BUCKET_NAME,
    Key: key,
    Body: buffer,
    ContentType: contentType,
  });

  await r2Client.send(command);

  // Generate a signed URL (valid for 7 days)
  const signedUrl = await getSignedUrl(
    r2Client,
    new GetObjectCommand({
      Bucket: BUCKET_NAME,
      Key: key,
    }),
    { expiresIn: 604800 } // 7 days in seconds
  );

  return { key, url: signedUrl };
}

/**
 * Generates a signed URL for an existing R2 object
 * @param key - R2 object key
 * @param expiresIn - URL expiration time in seconds (default: 7 days)
 * @returns Signed URL string
 */
export async function getSignedImageUrl(key: string, expiresIn: number = 604800): Promise<string> {
  const command = new GetObjectCommand({
    Bucket: BUCKET_NAME,
    Key: key,
  });

  return await getSignedUrl(r2Client, command, { expiresIn });
}

/**
 * Deletes an image from R2
 * @param key - R2 object key to delete
 */
export async function deleteImage(key: string): Promise<void> {
  const command = new DeleteObjectCommand({
    Bucket: BUCKET_NAME,
    Key: key,
  });

  await r2Client.send(command);
}

/**
 * Helper function to construct the R2 object key
 */
export function getKey(userId: string, generationId: string, fileExtension: string): string {
  return `users/${userId}/images/${generationId}.${fileExtension}`;
}

/**
 * Helper function to determine content type from file extension
 */
function getContentType(extension: string): string {
  const ext = extension.toLowerCase();
  const contentTypes: Record<string, string> = {
    png: 'image/png',
    jpg: 'image/jpeg',
    jpeg: 'image/jpeg',
    webp: 'image/webp',
    gif: 'image/gif',
  };

  return contentTypes[ext] || 'application/octet-stream';
}

/**
 * Uploads multiple images in parallel
 * @param images - Array of { buffer, generationId, fileExtension, userId }
 * @returns Array of uploaded image data with keys and URLs
 */
export async function uploadMultipleImages(
  images: Array<{ buffer: Buffer; generationId: string; fileExtension: string; userId: string }>
): Promise<Array<{ key: string; url: string }>> {
  const uploadPromises = images.map(async ({ buffer, generationId, fileExtension, userId }) => {
    return await uploadImage(buffer, userId, generationId, fileExtension);
  });

  return Promise.all(uploadPromises);
}
