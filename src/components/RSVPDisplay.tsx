'use client';

import React, { useEffect, useMemo, useRef } from 'react';
import { Play, Pause, RotateCcw } from 'lucide-react';

interface RSVPDisplayProps {
    words: string[];
    wpm: number;
    isPlaying: boolean;
    onPause: () => void;
    onComplete: () => void;
    currentIndex: number;
    onIndexChange: (index: number) => void;
    onRestart: () => void;
    onTogglePlay: () => void;
    onSpeedChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
}

export const RSVPDisplay: React.FC<RSVPDisplayProps> = ({
    words,
    wpm,
    isPlaying,
    onPause,
    onComplete,
    currentIndex,
    onIndexChange,
    onRestart,
    onTogglePlay,
    onSpeedChange
}) => {
    const timerRef = useRef<NodeJS.Timeout | null>(null);

    // Derive current word directly from props
    const currentWord = useMemo(() => {
        if (words.length > 0 && currentIndex < words.length) {
            return words[currentIndex];
        }
        return '';
    }, [words, currentIndex]);

    // Handle completion
    useEffect(() => {
        if (words.length > 0 && currentIndex >= words.length) {
            setTimeout(() => {
                onComplete();
            }, 0);
        }
    }, [currentIndex, words.length, onComplete]);

    useEffect(() => {
        if (isPlaying && currentIndex < words.length) {
            const interval = 60000 / wpm; // ms per word
            timerRef.current = setInterval(() => {
                onIndexChange(currentIndex + 1);
            }, interval);
        } else {
            if (timerRef.current) clearInterval(timerRef.current);
        }

        return () => {
            if (timerRef.current) clearInterval(timerRef.current);
        };
    }, [isPlaying, wpm, currentIndex, words.length, onIndexChange]);

    // Logic to split the word
    const getWordParts = (word: string) => {
        if (!word) return { start: '', pivot: '', end: '' };
        const middleIndex = Math.ceil(word.length / 2) - 1;
        const start = word.slice(0, middleIndex);
        const pivot = word[middleIndex];
        const end = word.slice(middleIndex + 1);
        return { start, pivot, end };
    };

    const { start, pivot, end } = getWordParts(currentWord);

    return (
        <div className="rsvp-wrapper animate-fade-in">
            {/* Reader Container */}
            <div className="reader-box">
                {/* Guides */}
                <div className="guide-line-v"></div>
                <div className="guide-line-h"></div>

                {/* Word Display */}
                <div className="word-display">
                    <div className="word-start">{start}</div>
                    <div className="word-pivot">{pivot}</div>
                    <div className="word-end">{end}</div>
                </div>
            </div>

            {/* Helper Text */}
            <div style={{ color: 'var(--text-secondary)', fontSize: '0.875rem', marginBottom: '1rem' }}>
                reading {currentIndex + 1} of {words.length}
            </div>

            {/* Controls Bar */}
            <div className="controls-panel">

                {/* Playback Controls */}
                <div className="main-controls">
                    <button
                        onClick={onRestart}
                        className="btn-icon-circle"
                        title="Restart"
                    >
                        <RotateCcw size={24} />
                    </button>

                    <button
                        onClick={onTogglePlay}
                        className="btn-play-large"
                    >
                        {isPlaying ? <Pause size={32} fill="currentColor" /> : <Play size={32} fill="currentColor" style={{ marginLeft: '4px' }} />}
                    </button>

                    <div style={{ width: '3rem' }}></div> {/* Spacer */}
                </div>

                {/* Speed Control */}
                <div className="setting-row">
                    <div className="setting-label">
                        <span>Speed</span>
                        <span style={{ color: 'white' }}>{wpm} WPM</span>
                    </div>
                    <input
                        type="range"
                        min="150"
                        max="1000"
                        step="50"
                        value={wpm}
                        onChange={onSpeedChange}
                        className="input-range"
                    />
                    <div className="setting-label">
                        <span>Slow</span>
                        <span>Fast</span>
                    </div>
                </div>

                {/* Progress */}
                <div className="setting-row">
                    <div className="setting-label">
                        <span>Progress</span>
                        <span>{Math.round((currentIndex / words.length) * 100)}%</span>
                    </div>
                    <div className="progress-bar">
                        <div
                            className="progress-fill"
                            style={{ width: `${(currentIndex / words.length) * 100}%` }}
                        ></div>
                    </div>
                </div>

            </div>
        </div>
    );
};
