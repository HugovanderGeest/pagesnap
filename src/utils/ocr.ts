import Tesseract from 'tesseract.js';

export const extractTextFromImage = async (file: File): Promise<string> => {
    try {
        const result = await Tesseract.recognize(
            file,
            'eng',
            {
                logger: m => console.log(m) // Optional: for debugging
            }
        );
        return result.data.text;
    } catch (error) {
        console.error('OCR Error:', error);
        throw new Error('Failed to extract text from image');
    }
};

export const extractTextFromMultipleImages = async (files: File[]): Promise<string[]> => {
    const texts = await Promise.all(files.map(file => extractTextFromImage(file)));
    // Join all texts
    const fullText = texts.join(' ');
    // Split into words, removing empty strings and whitespace
    return fullText.split(/\s+/).filter(word => word.length > 0);
};
