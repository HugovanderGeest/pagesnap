import AsyncStorage from '@react-native-async-storage/async-storage';

export interface LocalBook {
    id: string;
    title: string;
    progress: number;
    wordIndex: number;
    totalWords: number;
    lastRead: number;
    words: string[];
}

export const BookStore = {
    async getAll(): Promise<LocalBook[]> {
        try {
            const keys = await AsyncStorage.getAllKeys();
            const bookKeys = keys.filter(k => k.startsWith('book_'));
            if (bookKeys.length === 0) return [];

            const pairs = await AsyncStorage.multiGet(bookKeys);
            return pairs
                .map(([_, val]) => {
                    if (!val) return null;
                    try {
                        return JSON.parse(val) as LocalBook;
                    } catch {
                        return null;
                    }
                })
                .filter((b): b is LocalBook => b !== null)
                .sort((a, b) => b.lastRead - a.lastRead); // Most recently read first
        } catch {
            return [];
        }
    },

    async getById(id: string): Promise<LocalBook | null> {
        try {
            const json = await AsyncStorage.getItem(`book_${id}`);
            if (!json) return null;
            return JSON.parse(json) as LocalBook;
        } catch {
            return null;
        }
    },

    async save(book: LocalBook): Promise<void> {
        try {
            await AsyncStorage.setItem(`book_${book.id}`, JSON.stringify(book));
        } catch (e) {
            console.error("Failed to save book locally", e);
        }
    },

    async updateProgress(id: string, wordIndex: number, totalWords: number): Promise<void> {
        try {
            const book = await this.getById(id);
            if (!book) return;

            book.wordIndex = wordIndex;
            book.progress = totalWords > 0 ? wordIndex / totalWords : 0;
            book.lastRead = Date.now();

            await this.save(book);
        } catch (e) {
            console.error("Failed to update progress", e);
        }
    },

    async delete(id: string): Promise<void> {
        try {
            await AsyncStorage.removeItem(`book_${id}`);
        } catch (e) {
            console.error("Failed to delete book", e);
        }
    }
};
