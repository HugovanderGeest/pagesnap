'use client';

import { useState, useRef } from 'react';
import { Camera, Upload, Image as ImageIcon, Loader2, BookOpen } from 'lucide-react';
import { RSVPDisplay } from '@/components/RSVPDisplay';
import { extractTextFromMultipleImages } from '@/utils/ocr';

export default function Home() {
  const [files, setFiles] = useState<File[]>([]);
  const [words, setWords] = useState<string[]>([]);
  const [status, setStatus] = useState<'idle' | 'processing' | 'ready' | 'reading'>('idle');
  const [wpm, setWpm] = useState(300);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentIndex, setCurrentIndex] = useState(0);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      setFiles(Array.from(e.target.files));
    }
  };

  const handleProcess = async () => {
    if (files.length === 0) return;
    setStatus('processing');
    try {
      const extractedWords = await extractTextFromMultipleImages(files);
      setWords(extractedWords);
      setStatus('ready');
    } catch (error) {
      console.error(error);
      alert('Failed to process images. Please try again.');
      setStatus('idle');
    }
  };

  const togglePlay = () => {
    setIsPlaying(!isPlaying);
  };

  const handleRestart = () => {
    setIsPlaying(false);
    setCurrentIndex(0);
  };

  const handleIndexChange = (newIndex: number) => {
    setCurrentIndex(newIndex);
  };

  const handleSpeedChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setWpm(parseInt(e.target.value));
  };

  return (
    <main className="page-container">
      {/* Header */}
      <header className="header">
        <div className="brand">
          <div className="brand-icon">
            <BookOpen size={24} color="white" />
          </div>
          <h1 className="brand-name">PageSnap</h1>
        </div>
        <div className="beta-tag">beta v1.0</div>
      </header>

      {/* Content Area */}
      <div className="content-wrapper">

        {status === 'idle' && (
          <div className="glass-panel">
            <div style={{ marginBottom: '2rem' }}>
              <h2 className="hero-title">Speed Read Your Books</h2>
              <p className="hero-subtitle">Upload photos of book pages and read them at up to 1000 words per minute.</p>
            </div>

            <div className="upload-grid">
              <button
                onClick={() => fileInputRef.current?.click()}
                className="upload-card"
              >
                <div className="icon-box">
                  <Upload size={32} />
                </div>
                <span>Upload Photos</span>
                <input
                  type="file"
                  ref={fileInputRef}
                  onChange={handleFileChange}
                  multiple
                  accept="image/*"
                  className="hidden"
                />
              </button>

              <button
                onClick={() => fileInputRef.current?.click()} // On mobile this triggers camera
                className="upload-card camera"
              >
                <div className="icon-box">
                  <Camera size={32} />
                </div>
                <span>Take Photos</span>
              </button>
            </div>

            {files.length > 0 && (
              <div className="status-bar animate-fade-in">
                <div className="file-count">
                  <ImageIcon size={20} className="text-indigo-400" />
                  <span>{files.length} pages selected</span>
                </div>
                <button
                  onClick={handleProcess}
                  className="btn btn-primary"
                >
                  Reading Mode
                </button>
              </div>
            )}
          </div>
        )}

        {status === 'processing' && (
          <div className="loading-container glass-panel">
            <div className="spinner"></div>
            <h2 className="hero-title" style={{ fontSize: '1.5rem' }}>Processing Pages...</h2>
            <p className="hero-subtitle">Extracting text from your images using OCR</p>
          </div>
        )}

        {(status === 'ready' || status === 'reading') && (
          <RSVPDisplay
            words={words}
            wpm={wpm}
            isPlaying={isPlaying}
            onPause={() => setIsPlaying(false)}
            onComplete={() => {
              setIsPlaying(false);
              setStatus('ready');
            }}
            currentIndex={currentIndex}
            onIndexChange={handleIndexChange}
            onRestart={handleRestart}
            onTogglePlay={togglePlay}
            onSpeedChange={handleSpeedChange}
          />
        )}

      </div>
    </main>
  );
}
