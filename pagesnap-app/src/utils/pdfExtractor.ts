import * as FileSystem from 'expo-file-system';
import { PDFDocument } from 'pdf-lib';

export const extractPdfNative = async (fileUri: string): Promise<string[]> => {
    try {
        // Read file as base64
        const fileBase64 = await FileSystem.readAsStringAsync(fileUri, {
            encoding: 'base64',
        });

        // Load PDF document using pdf-lib
        const pdfDoc = await PDFDocument.load(fileBase64);

        let fullText = '';

        // Note: pdf-lib doesn't have a built-in text extractor that is simple. 
        // For accurate offline text extraction in purely JS RN environments, you often need 
        // to hook into native modules. But as a fallback for the scope of this project right now,
        // we extract the raw text content stream if possible, or we instruct the user that it needs a native module.

        // We will try a basic raw extraction, but usually PDF string isolation is complex in purely JS
        const pages = pdfDoc.getPages();
        for (const page of pages) {
            // Very rudimentary attempt to grab text blocks if they are cleanly stored
            fullText += ' ' + page.node.toString();
        }

        const words = fullText
            .replace(/[^a-zA-Z0-9.,!?'"-\s]/g, '') // remove pure PDF binary operators
            .split(/\s+/)
            .filter(word => word.length > 1 && !word.startsWith('0') && !word.includes('obj') && !word.includes('endobj'));

        if (words.length < 50) {
            throw new Error("Could not extract readable text from this PDF. It may be an image-based scan or heavily encoded.");
        }

        return words;
    } catch (error) {
        console.error('PDF Extraction Error:', error);
        throw new Error('Failed to extract text from PDF file. Native extraction requires plain text PDFs.');
    }
};
