import React, { useState, useEffect, useRef, useCallback } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, Dimensions } from 'react-native';
import { Play, Pause, RotateCcw, Settings } from 'lucide-react-native';
import { Gesture, GestureDetector } from 'react-native-gesture-handler';
import Animated, { useSharedValue, useAnimatedStyle, withTiming, runOnJS } from 'react-native-reanimated';
import { THEME } from '../theme';

const { width } = Dimensions.get('window');

interface RSVPEngineProps {
    words: string[];
    initialSpeed?: number;
    initialIndex?: number;
    onCompletion?: () => void;
    onProgress?: (index: number) => void;
}

export default function RSVPEngine({ words, initialSpeed = 300, initialIndex = 0, onCompletion, onProgress }: RSVPEngineProps) {
    const [isPlaying, setIsPlaying] = useState(false);
    const [currentIndex, setCurrentIndex] = useState(initialIndex);
    const [wpm, setWpm] = useState(initialSpeed);
    const [pivotColor, setPivotColor] = useState(THEME.colors.primary);

    const timerRef = useRef<NodeJS.Timeout | null>(null);
    const isPlayingRef = useRef(isPlaying);
    const currentIndexRef = useRef(initialIndex);

    // Reanimated values for the scrub bar
    const scrubProgress = useSharedValue(0);

    useEffect(() => {
        isPlayingRef.current = isPlaying;
        currentIndexRef.current = currentIndex;
        scrubProgress.value = withTiming(currentIndex / Math.max(1, words.length - 1));
    }, [isPlaying, currentIndex, words.length]);

    const togglePlay = () => setIsPlaying(prev => !prev);
    const restart = () => {
        setCurrentIndex(0);
        setIsPlaying(true);
    };

    const computeOptimalPivot = (word: string) => {
        const len = word.length;
        if (len <= 1) return 0;
        if (len <= 5) return 1;
        if (len <= 9) return 2;
        if (len <= 13) return 3;
        return 4;
    };

    const getDelayForWord = (word: string, baseDelayMs: number) => {
        let delay = baseDelayMs;
        const lastChar = word[word.length - 1];
        if (lastChar === ',' || lastChar === ';') delay *= 1.5;
        if (lastChar === '.' || lastChar === '!' || lastChar === '?') delay *= 2.0;
        if (word.length > 8) delay *= 1.2;
        return delay;
    };

    useEffect(() => {
        const tick = () => {
            if (!isPlayingRef.current || words.length === 0) return;
            if (currentIndexRef.current >= words.length - 1) {
                setIsPlaying(false);
                onCompletion?.();
                return;
            }

            const nextIndex = currentIndexRef.current + 1;
            setCurrentIndex(nextIndex);
            onProgress?.(nextIndex);

            const delay = getDelayForWord(words[nextIndex], 60000 / wpm);
            timerRef.current = setTimeout(tick, delay);
        };

        if (isPlaying) {
            const delay = getDelayForWord(words[currentIndex], 60000 / wpm);
            timerRef.current = setTimeout(tick, delay);
        } else if (timerRef.current) {
            clearTimeout(timerRef.current);
        }

        return () => {
            if (timerRef.current) clearTimeout(timerRef.current);
        };
    }, [isPlaying, wpm, words]);

    const currentWord = words[currentIndex] || '';
    const pivotIndex = computeOptimalPivot(currentWord);

    const leftPart = currentWord.slice(0, pivotIndex);
    const pivotChar = currentWord.charAt(pivotIndex);
    const rightPart = currentWord.slice(pivotIndex + 1);

    // Gesture handler for Scrub Bar
    const panGesture = Gesture.Pan()
        .onBegin((e) => {
            runOnJS(setIsPlaying)(false);
        })
        .onUpdate((e) => {
            const clampedX = Math.max(0, Math.min(e.x, width));
            const newProgress = clampedX / width;
            scrubProgress.value = newProgress;
            const newIdx = Math.floor(newProgress * (words.length - 1));
            runOnJS(setCurrentIndex)(newIdx);
        });

    const animatedScrubStyle = useAnimatedStyle(() => ({
        width: `${scrubProgress.value * 100}%`,
        backgroundColor: pivotColor,
    }));

    if (words.length === 0) {
        return <View style={styles.container} />;
    }

    return (
        <View style={styles.container}>
            {/* Top Stats */}
            <View style={styles.topHud}>
                <Text style={styles.hudText}>{currentIndex + 1} / {words.length}</Text>
                <Text style={[styles.hudText, { color: pivotColor, fontWeight: 'bold' }]}>
                    {Math.round((currentIndex / Math.max(1, words.length - 1)) * 100)}%
                </Text>
            </View>

            {/* Reader Core */}
            <TouchableOpacity
                style={styles.readerArea}
                activeOpacity={1}
                onPress={togglePlay}
            >
                <View style={styles.wordBox}>
                    {/* Guide lines */}
                    <View style={styles.vLine} />
                    <View style={styles.hLine} />

                    <View style={styles.wordRow}>
                        <Text style={styles.textLeft} numberOfLines={1}>{leftPart}</Text>
                        <View style={styles.pivotContainer}>
                            <Text style={[styles.textPivot, { color: pivotColor, textShadowColor: pivotColor + '80' }]}>{pivotChar}</Text>
                        </View>
                        <Text style={styles.textRight} numberOfLines={1}>{rightPart}</Text>
                    </View>
                </View>
            </TouchableOpacity>

            {/* Invisible Scrub Area for better touch targets */}
            <GestureDetector gesture={panGesture}>
                <View style={styles.scrubberArea}>
                    <View style={styles.scrubberTrack}>
                        <Animated.View style={[styles.scrubberFill, animatedScrubStyle]} />
                    </View>
                </View>
            </GestureDetector>

            {/* Bottom Controls */}
            <View style={styles.controlsBar}>
                <TouchableOpacity style={styles.iconButton} onPress={restart}>
                    <RotateCcw color={THEME.colors.textDim} size={20} />
                </TouchableOpacity>

                <TouchableOpacity
                    style={[styles.playButton, { backgroundColor: pivotColor, shadowColor: pivotColor }]}
                    onPress={togglePlay}
                >
                    {isPlaying ? <Pause color="#fff" size={28} fill="#fff" /> : <Play color="#fff" size={28} fill="#fff" style={{ transform: [{ translateX: 2 }] }} />}
                </TouchableOpacity>

                <TouchableOpacity style={styles.iconButton} onPress={() => alert('Settings menu coming soon')}>
                    <Settings color={THEME.colors.textDim} size={20} />
                </TouchableOpacity>
            </View>
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#000000',
    },
    topHud: {
        position: 'absolute',
        top: 60,
        left: 20,
        right: 20,
        flexDirection: 'row',
        justifyContent: 'space-between',
        zIndex: 10,
    },
    hudText: {
        fontFamily: 'Courier',
        color: THEME.colors.textDim,
        fontSize: 12,
        letterSpacing: 2,
    },
    readerArea: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
    },
    wordBox: {
        width: '100%',
        height: 120,
        justifyContent: 'center',
        alignItems: 'center',
        position: 'relative',
    },
    vLine: {
        position: 'absolute',
        left: '50%',
        top: 10,
        bottom: 10,
        width: 1,
        backgroundColor: 'rgba(255,255,255,0.1)',
    },
    hLine: {
        position: 'absolute',
        top: '50%',
        left: 20,
        right: 20,
        height: 1,
        backgroundColor: 'rgba(255,255,255,0.1)',
    },
    wordRow: {
        flexDirection: 'row',
        alignItems: 'center',
        width: '100%',
        marginTop: -8, // optical alignment
    },
    textLeft: {
        flex: 1,
        textAlign: 'right',
        color: 'rgba(255,255,255,0.8)',
        fontSize: 48,
        fontFamily: 'Courier',
        fontWeight: 'bold',
    },
    pivotContainer: {
        width: 32, // Roughly 1 character width at size 48
        alignItems: 'center',
    },
    textPivot: {
        fontSize: 56, // Slightly larger than surrounding text
        fontFamily: 'Courier',
        fontWeight: 'bold',
        textShadowOffset: { width: 0, height: 0 },
        textShadowRadius: 10,
    },
    textRight: {
        flex: 1,
        textAlign: 'left',
        color: 'rgba(255,255,255,0.8)',
        fontSize: 48,
        fontFamily: 'Courier',
        fontWeight: 'bold',
    },
    scrubberArea: {
        height: 40,
        justifyContent: 'flex-end',
        zIndex: 20,
    },
    scrubberTrack: {
        width: '100%',
        height: 4,
        backgroundColor: 'rgba(255,255,255,0.1)',
    },
    scrubberFill: {
        height: '100%',
    },
    controlsBar: {
        paddingBottom: 40, // Avoid safe area bottom
        paddingTop: 20,
        flexDirection: 'row',
        justifyContent: 'center',
        alignItems: 'center',
        gap: 32,
        backgroundColor: THEME.colors.surface,
        borderTopWidth: 1,
        borderColor: THEME.colors.border,
    },
    iconButton: {
        width: 48,
        height: 48,
        borderRadius: 24,
        backgroundColor: THEME.colors.background,
        justifyContent: 'center',
        alignItems: 'center',
        borderWidth: 1,
        borderColor: THEME.colors.border,
    },
    playButton: {
        width: 72,
        height: 72,
        borderRadius: 36,
        justifyContent: 'center',
        alignItems: 'center',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.3,
        shadowRadius: 15,
    }
});
