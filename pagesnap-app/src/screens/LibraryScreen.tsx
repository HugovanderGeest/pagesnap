import React, { useState, useEffect } from 'react';
import { View, Text, StyleSheet, TouchableOpacity, FlatList, Alert, ActivityIndicator } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Plus } from 'lucide-react-native';
import * as DocumentPicker from 'expo-document-picker';
import { THEME } from '../theme';
import { BookStore, LocalBook } from '../utils/BookStore';
import { extractEpubNative } from '../utils/epubExtractor';

export default function LibraryScreen({ navigation }: any) {
    const insets = useSafeAreaInsets();
    const [books, setBooks] = useState<LocalBook[]>([]);
    const [loading, setLoading] = useState(false);

    useEffect(() => {
        loadBooks();
    }, []);

    const loadBooks = async () => {
        const saved = await BookStore.getAll();
        setBooks(saved);
    };

    const handleImport = async () => {
        try {
            const result = await DocumentPicker.getDocumentAsync({
                type: ['application/epub+zip', 'application/pdf', 'text/plain'],
                copyToCacheDirectory: true,
            });

            if (result.canceled) return;
            const file = result.assets[0];

            setLoading(true);

            let words: string[] = [];
            if (file.name.endsWith('.epub')) {
                words = await extractEpubNative(file.uri);
            } else if (file.name.endsWith('.pdf')) {
                const { extractPdfNative } = await import('../utils/pdfExtractor');
                words = await extractPdfNative(file.uri);
            } else {
                Alert.alert('Unsupported', 'Only EPUBs and PDFs are supported natively at the moment.');
                setLoading(false);
                return;
            }

            if (words.length > 0) {
                const newBook: LocalBook = {
                    id: Date.now().toString(),
                    title: file.name.replace('.epub', ''),
                    progress: 0,
                    wordIndex: 0,
                    totalWords: words.length,
                    lastRead: Date.now(),
                    words
                };

                await BookStore.save(newBook);
                await loadBooks();
            }
        } catch (error: any) {
            Alert.alert('Import Error', error.message || 'Failed to extract book text');
        } finally {
            setLoading(false);
        }
    };

    const openBook = (id: string) => {
        navigation.navigate('Reader', { bookId: id });
    };

    const renderBook = ({ item }: { item: LocalBook }) => (
        <TouchableOpacity
            style={styles.bookCard}
            onPress={() => openBook(item.id)}
            activeOpacity={0.8}
        >
            <View style={styles.bookCover}>
                <Text style={styles.bookTitle} numberOfLines={3}>{item.title}</Text>
            </View>
            <View style={styles.progressTrack}>
                <View style={[styles.progressFill, { width: `${item.progress * 100}%` }]} />
            </View>
        </TouchableOpacity>
    );

    return (
        <View style={styles.container}>
            <View style={[styles.header, { paddingTop: insets.top + THEME.spacing.md }]}>
                <Text style={styles.headline}>Library</Text>
                <TouchableOpacity style={styles.importBtn} onPress={handleImport}>
                    <Plus size={20} color={THEME.colors.primary} />
                    <Text style={styles.importText}>IMPORT</Text>
                </TouchableOpacity>
            </View>

            {loading && (
                <View style={styles.loadingOverlay}>
                    <ActivityIndicator color={THEME.colors.primary} size="large" />
                    <Text style={styles.loadingText}>Extracting Signal...</Text>
                </View>
            )}

            {books.length === 0 && !loading && (
                <View style={styles.emptyState}>
                    <Text style={styles.emptyTitle}>NO FRAGMENTS</Text>
                    <Text style={styles.emptySub}>Import an EPUB to begin protocol.</Text>
                </View>
            )}

            <FlatList
                data={books}
                keyExtractor={item => item.id}
                renderItem={renderBook}
                contentContainerStyle={[styles.listContent, { paddingBottom: insets.bottom + 100 }]} // 100px for blur tab bar
                numColumns={2}
                columnWrapperStyle={styles.row}
            />
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: THEME.colors.background,
    },
    header: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: THEME.spacing.lg,
        paddingBottom: THEME.spacing.lg,
    },
    headline: {
        fontSize: 32,
        fontWeight: '900',
        color: THEME.colors.text,
        letterSpacing: -1,
    },
    importBtn: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: THEME.colors.surface,
        paddingHorizontal: 16,
        paddingVertical: 10,
        borderRadius: THEME.border.radius,
        gap: 8,
        borderWidth: 1,
        borderColor: THEME.colors.border,
    },
    importText: {
        color: THEME.colors.text,
        fontFamily: 'Courier',
        fontWeight: 'bold',
        fontSize: 12,
        letterSpacing: 2,
    },
    listContent: {
        paddingHorizontal: THEME.spacing.lg,
        gap: THEME.spacing.lg,
    },
    row: {
        gap: THEME.spacing.lg,
    },
    bookCard: {
        flex: 1,
        aspectRatio: 0.65,
        backgroundColor: THEME.colors.surface,
        borderRadius: THEME.border.radius,
        overflow: 'hidden',
        borderWidth: 1,
        borderColor: THEME.colors.border,
    },
    bookCover: {
        flex: 1,
        padding: THEME.spacing.md,
        justifyContent: 'center',
    },
    bookTitle: {
        color: THEME.colors.text,
        fontSize: 18,
        fontWeight: 'bold',
        textAlign: 'center',
    },
    progressTrack: {
        height: 4,
        backgroundColor: 'rgba(255,255,255,0.05)',
    },
    progressFill: {
        height: '100%',
        backgroundColor: THEME.colors.primary,
    },
    loadingOverlay: {
        ...StyleSheet.absoluteFillObject,
        backgroundColor: 'rgba(4,4,4,0.8)',
        justifyContent: 'center',
        alignItems: 'center',
        zIndex: 10,
    },
    loadingText: {
        marginTop: 16,
        color: THEME.colors.primary,
        fontFamily: 'Courier',
        fontWeight: 'bold',
        letterSpacing: 2,
    },
    emptyState: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        paddingBottom: 100,
    },
    emptyTitle: {
        color: THEME.colors.textDim,
        fontSize: 24,
        fontWeight: '900',
        letterSpacing: 2,
    },
    emptySub: {
        color: THEME.colors.textDim,
        fontFamily: 'Courier',
        marginTop: 12,
    }
});
