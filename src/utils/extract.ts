import Tesseract from 'tesseract.js';

export const extractTextFromImage = async (file: File): Promise<string> => {
    try {
        const result = await Tesseract.recognize(file, 'eng');
        return result.data.text;
    } catch (error) {
        console.error('OCR Error:', error);
        throw error;
    }
};

export const extractTextFromPDF = async (file: File): Promise<string> => {
    const arrayBuffer = await file.arrayBuffer();

    // Dynamically import pdfjs-dist (avoids SSR DOMMatrix crash)
    const pdfjsLib = await import('pdfjs-dist');

    // Use the local worker (copied to /public during build) — no CDN dependency
    pdfjsLib.GlobalWorkerOptions.workerSrc = '/pdf.worker.min.mjs';

    const loadingTask = pdfjsLib.getDocument({ data: arrayBuffer });
    const pdf = await loadingTask.promise;
    let fullText = '';
    for (let i = 1; i <= pdf.numPages; i++) {
        const page = await pdf.getPage(i);
        const content = await page.getTextContent();
        const strings = content.items.map(
            (item: unknown) => (item as { str: string }).str
        );
        fullText += strings.join(' ') + '\n';
    }
    return fullText;
};

export const extractTextFromEPUB = async (file: File): Promise<string> => {
    const arrayBuffer = await file.arrayBuffer();
    const epubjsLib = await import('epubjs');
    const ePub = epubjsLib.default;
    const book = ePub(arrayBuffer);
    await book.ready;
    let fullText = '';
    const spine = book.spine as unknown as {
        length: number;
        get: (index: number) => { load: (fn: unknown) => Promise<{ textContent: string }> };
    };
    for (let i = 0; i < spine.length; i++) {
        const item = spine.get(i);
        const doc = await item.load(book.load.bind(book));
        fullText += doc.textContent + '\n';
    }
    return fullText;
};

export const processFiles = async (files: File[]): Promise<string[]> => {
    let combinedText = '';

    for (const file of files) {
        try {
            if (file.type.startsWith('image/')) {
                combinedText += (await extractTextFromImage(file)) + ' ';
            } else if (file.type === 'application/pdf' || file.name.endsWith('.pdf')) {
                combinedText += (await extractTextFromPDF(file)) + ' ';
            } else if (file.type === 'application/epub+zip' || file.name.endsWith('.epub')) {
                combinedText += (await extractTextFromEPUB(file)) + ' ';
            } else if (file.type === 'text/plain' || file.name.endsWith('.txt')) {
                combinedText += (await file.text()) + ' ';
            } else {
                console.warn(`Unsupported file type: ${file.type}`);
            }
        } catch (err) {
            console.error(`Error processing ${file.name}:`, err);
            throw new Error(`Failed to process ${file.name}: ${err instanceof Error ? err.message : String(err)}`);
        }
    }

    return combinedText.split(/\s+/).filter(word => word.length > 0);
};
