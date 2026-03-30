import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, ActivityIndicator } from 'react-native';
import { THEME } from '../theme';
import RSVPEngine from '../components/RSVPEngine';
import { BookStore, LocalBook } from '../utils/BookStore';

export default function ReaderScreen({ route, navigation }: any) {
    const { bookId } = route.params || {};
    const [book, setBook] = useState<LocalBook | null>(null);

    useEffect(() => {
        if (bookId) {
            BookStore.getById(bookId).then(b => setBook(b));
        }
    }, [bookId]);

    const handleProgress = (index: number) => {
        if (book && index % 10 === 0) { // Save every 10 words to avoid hammering storage
            BookStore.updateProgress(book.id, index, book.words.length);
        }
    };

    const handleClose = () => {
        // Force a final save on close if the engine has advanced
        navigation.goBack();
    };

    if (!book) {
        return (
            <View style={[styles.container, { justifyContent: 'center', alignItems: 'center' }]}>
                <ActivityIndicator color={THEME.colors.primary} size="large" />
            </View>
        );
    }

    return (
        <View style={styles.container}>
            <TouchableOpacity
                style={styles.backButton}
                onPress={handleClose}
            >
                <Text style={styles.backText}>Close Viewer</Text>
            </TouchableOpacity>

            <RSVPEngine
                words={book.words}
                initialSpeed={300}
                initialIndex={book.wordIndex || 0}
                onProgress={handleProgress}
                onCompletion={handleClose}
            />
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#000000', // Pure black for immersive reader
    },
    backButton: {
        position: 'absolute',
        top: 60,
        left: 20,
        zIndex: 10,
        padding: 10,
        backgroundColor: THEME.colors.surface,
        borderRadius: 20,
    },
    backText: {
        color: THEME.colors.text,
        fontFamily: 'Courier',
        fontWeight: 'bold',
    },
});
