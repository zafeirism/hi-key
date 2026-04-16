'use client';

import { useState, useRef, useEffect } from 'react';

// Generate session ID once per browser session
const getSessionId = () => {
  if (typeof window === 'undefined') return '';
  let sessionId = sessionStorage.getItem('demo_session_id');
  if (!sessionId) {
    sessionId = `session-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    sessionStorage.setItem('demo_session_id', sessionId);
  }
  return sessionId;
};

// Generate unique request ID per submission
const generateRequestId = () => {
  return `req-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
};

interface ImageLoadTime {
  index: number;
  seconds: number;
}

export default function Playground() {
  const [prompt, setPrompt] = useState('');
  const [loading, setLoading] = useState(false);
  const [imageUrls, setImageUrls] = useState<string[]>([]);
  const [error, setError] = useState('');
  const [loadTimes, setLoadTimes] = useState<ImageLoadTime[]>([]);
  const [selectedImageIndex, setSelectedImageIndex] = useState<number | null>(null); // Changed from selectedImage
  const generateStartTime = useRef<number>(0);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!prompt.trim()) return;

    setLoading(true);
    setError('');
    setImageUrls([]);
    setLoadTimes([]);
    generateStartTime.current = Date.now();

    try {
      const response = await fetch('/api/generate', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: 'Bearer ***REMOVED***',
        },
        body: JSON.stringify({
          prompt: prompt.trim(),
          session_id: getSessionId(),
          request_id: generateRequestId(),
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to generate images');
      }

      const data = await response.json();
      setImageUrls(data.signedUrls);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Something went wrong');
    } finally {
      setLoading(false);
    }
  };

  const handleImageLoad = (index: number) => {
    const elapsedSeconds = ((Date.now() - generateStartTime.current) / 1000).toFixed(1);
    setLoadTimes((prev) => [...prev, { index, seconds: parseFloat(elapsedSeconds) }]);
  };

  const sortedLoadTimes = [...loadTimes].sort((a, b) => a.seconds - b.seconds);

  return (
    <div className="min-h-screen bg-white dark:bg-black">
      <div className="max-w-3xl mx-auto px-4 py-12">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl font-semibold text-gray-900 dark:text-gray-100 mb-2">
            hi-key Playground
          </h1>
          <p className="text-gray-600 dark:text-gray-400">Create fun visuals in your chats 🎨</p>
        </div>

        {/* Input Form */}
        <div className="mb-8">
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="relative">
              <textarea
                value={prompt}
                onChange={(e) => setPrompt(e.target.value)}
                placeholder="A cozy coffee shop with warm lighting, autumn vibes, watercolor painting style"
                className="w-full h-32 px-4 py-3 border border-gray-300 dark:border-gray-700 rounded-lg focus:ring-2 focus:ring-gray-400 focus:border-transparent resize-none bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 placeholder-gray-400"
                disabled={loading}
              />
            </div>

            <button
              type="submit"
              disabled={loading || !prompt.trim()}
              className="w-full bg-black dark:bg-white text-white dark:text-black font-medium py-3 px-6 rounded-lg hover:bg-gray-800 dark:hover:bg-gray-200 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
            >
              {loading ? 'Generating...' : 'Generate'}
            </button>

            {error && <p className="text-red-600 dark:text-red-400 text-sm text-center">{error}</p>}
          </form>

          {/* Tips */}
          <div className="mt-8 text-sm text-gray-600 dark:text-gray-400 space-y-2">
            <p className="font-medium text-gray-900 dark:text-gray-100">Tips for better results:</p>
            <ul className="space-y-1 ml-4">
              <li>• Be specific about style and mood</li>
              <li>• Describe lighting and colors</li>
              <li>• Start with the main subject</li>
            </ul>
          </div>
        </div>

        {/* Image Results */}
        {imageUrls.length > 0 && (
          <div className="space-y-4">
            <div className="text-sm text-gray-600 dark:text-gray-400">
              {loadTimes.length === 0 && <p>Generating images...</p>}
              {loadTimes.length > 0 && loadTimes.length < 4 && (
                <p>
                  {loadTimes.length} of 4 ready:{' '}
                  {sortedLoadTimes.map((lt) => `${lt.seconds}s`).join(', ')}
                </p>
              )}
              {loadTimes.length === 4 && (
                <p className="text-gray-900 dark:text-gray-100 font-medium">
                  All ready: {sortedLoadTimes.map((lt) => `${lt.seconds}s`).join(', ')}
                </p>
              )}
            </div>
            <div className="grid grid-cols-2 gap-4">
              {imageUrls.map((url, idx) => (
                <ImageWithRetry
                  key={idx}
                  url={url}
                  index={idx}
                  onLoad={() => handleImageLoad(idx)}
                  onClick={() => setSelectedImageIndex(idx)} // Changed to set index instead of URL
                />
              ))}
            </div>
          </div>
        )}
      </div>

      {/* Lightbox */}
      {selectedImageIndex !== null && (
        <ImageLightbox
          images={imageUrls}
          currentIndex={selectedImageIndex}
          onClose={() => setSelectedImageIndex(null)}
          onNavigate={setSelectedImageIndex}
        />
      )}
    </div>
  );
}

// Simple component that retries loading on error
function ImageWithRetry({
  url,
  index,
  onLoad,
  onClick,
}: {
  url: string;
  index: number;
  onLoad: () => void;
  onClick: () => void;
}) {
  const [attemptKey, setAttemptKey] = useState(0);
  const [isLoading, setIsLoading] = useState(true);

  const handleError = () => {
    setTimeout(() => {
      setAttemptKey((k) => k + 1);
      setIsLoading(true);
    }, 300); // Fast polling for quick appearance
  };

  const handleLoad = () => {
    setIsLoading(false);
    onLoad();
  };

  return (
    <div
      className="relative aspect-square bg-gray-100 dark:bg-gray-800 rounded-lg overflow-hidden border border-gray-200 dark:border-gray-700 cursor-pointer hover:border-gray-400 dark:hover:border-gray-500 transition-colors"
      onClick={isLoading ? undefined : onClick}
    >
      {/* Loading State */}
      {isLoading && (
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="text-center">
            <div className="w-8 h-8 border-2 border-gray-300 border-t-gray-600 dark:border-gray-600 dark:border-t-gray-400 rounded-full animate-spin mx-auto mb-2"></div>
            <p className="text-xs text-gray-500 dark:text-gray-400">{'Generating...'}</p>
          </div>
        </div>
      )}

      {/* Image */}
      <img
        key={attemptKey}
        src={url}
        alt={`Generated image ${index + 1}`}
        className={`w-full h-full object-cover transition-opacity duration-300 ${
          isLoading ? 'opacity-0' : 'opacity-100'
        }`}
        onLoad={handleLoad}
        onError={handleError}
      />

      {/* Hover hint */}
      {!isLoading && (
        <div className="absolute inset-0 bg-black bg-opacity-0 hover:bg-opacity-10 transition-opacity flex items-center justify-center opacity-0 hover:opacity-50"></div>
      )}
    </div>
  );
}

// Lightbox for viewing full-size images with navigation
function ImageLightbox({
  images,
  currentIndex,
  onClose,
  onNavigate,
}: {
  images: string[];
  currentIndex: number;
  onClose: () => void;
  onNavigate: (index: number) => void;
}) {
  const handlePrevious = () => {
    if (currentIndex > 0) {
      onNavigate(currentIndex - 1);
    }
  };

  const handleNext = () => {
    if (currentIndex < images.length - 1) {
      onNavigate(currentIndex + 1);
    }
  };

  // Handle keyboard navigation
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') {
        onClose();
      } else if (e.key === 'ArrowLeft') {
        handlePrevious();
      } else if (e.key === 'ArrowRight') {
        handleNext();
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [currentIndex, images.length, onClose, onNavigate]); // Add dependencies

  const currentImageUrl = images[currentIndex];
  const hasPrevious = currentIndex > 0;
  const hasNext = currentIndex < images.length - 1;

  return (
    <div
      className="fixed inset-0 bg-black bg-opacity-90 z-50 flex items-center justify-center p-4"
      onClick={onClose}
    >
      {/* Close button */}
      <button
        onClick={onClose}
        className="absolute top-4 right-4 text-white hover:text-gray-300 text-4xl font-light leading-none z-10"
        aria-label="Close"
      >
        ×
      </button>

      {/* Previous arrow */}
      {hasPrevious && (
        <button
          onClick={(e) => {
            e.stopPropagation();
            handlePrevious();
          }}
          className="absolute left-4 top-1/2 -translate-y-1/2 text-white hover:text-gray-300 text-5xl font-light leading-none z-10 p-4"
          aria-label="Previous image"
        >
          ‹
        </button>
      )}

      {/* Next arrow */}
      {hasNext && (
        <button
          onClick={(e) => {
            e.stopPropagation();
            handleNext();
          }}
          className="absolute right-4 top-1/2 -translate-y-1/2 text-white hover:text-gray-300 text-5xl font-light leading-none z-10 p-4"
          aria-label="Next image"
        >
          ›
        </button>
      )}

      {/* Image counter */}
      <div className="absolute bottom-4 left-1/2 -translate-x-1/2 text-white text-sm z-10">
        {currentIndex + 1} / {images.length}
      </div>

      {/* Image */}
      <img
        src={currentImageUrl}
        alt={`Full size preview ${currentIndex + 1}`}
        className="max-w-full max-h-full object-contain"
        onClick={(e) => e.stopPropagation()}
      />
    </div>
  );
}
