import * as FileSystem from 'expo-file-system';
import JSZip from 'jszip';

/**
 * Clean HTML to perfectly stripped text
 */
function stripHtml(html: string): string {
    // 1. Convert block elements to line breaks to preserve paragraph separation
    let text = html.replace(/<\/(p|div|h[1-6]|li|tr|br)>/gi, '\n');
    text = text.replace(/<br\s*\/?>/gi, '\n');

    // 2. Strip all remaining tags
    text = text.replace(/<[^>]*>?/gm, '');

    // 3. Decode common HTML entities
    text = text
        .replace(/&nbsp;/g, ' ')
        .replace(/&amp;/g, '&')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/&quot;/g, '"')
        .replace(/&#39;/g, "'")
        .replace(/&apos;/g, "'")
        .replace(/&mdash;/g, '—')
        .replace(/&ndash;/g, '–');

    // 4. Clean up whitespace
    return text
        .replace(/\n\s*\n/g, '\n\n') // Collapse multiple newlines to double
        .trim();
}

/**
 * Extracts raw textual words from an EPUB file URI natively using JSZip.
 */
export async function extractEpubNative(fileUri: string): Promise<string[]> {
    try {
        const fileBase64 = await FileSystem.readAsStringAsync(fileUri, {
            encoding: 'base64',
        });

        // JSZip takes base64 in RN
        const zip = await JSZip.loadAsync(fileBase64, { base64: true });

        // 1. Find the OPF file (contains the spine/manifest)
        let opfPath = '';
        const containerXmlFile = zip.file('META-INF/container.xml');

        if (containerXmlFile) {
            const containerXml = await containerXmlFile.async('text');
            const opfMatch = containerXml.match(/full-path="([^"]+)"/);
            if (opfMatch && opfMatch[1]) {
                opfPath = opfMatch[1];
            }
        }

        // Fallback if container.xml is weird
        if (!opfPath) {
            const files = Object.keys(zip.files);
            const foundOpf = files.find(f => f.endsWith('.opf'));
            if (!foundOpf) throw new Error("Invalid EPUB format: No OPF file found.");
            opfPath = foundOpf;
        }

        const opfContent = await zip.file(opfPath)?.async('text');
        if (!opfContent) throw new Error("Could not read OPF file.");

        // 2. Parse the OPF for the 'spine' (reading order) and 'manifest' (file paths)
        // We are doing simple regex parsing as RN has no built-in DOMParser
        const itemRefs = [...opfContent.matchAll(/<itemref[^>]+idref="([^"]+)"/g)].map(m => m[1]);

        const basePath = opfPath.includes('/') ? opfPath.substring(0, opfPath.lastIndexOf('/') + 1) : '';

        const htmlFilesToRead: string[] = [];
        itemRefs.forEach(idref => {
            const itemMatch = opfContent.match(new RegExp(`<item[^>]+id="${idref}"[^>]+href="([^"]+)"`));
            if (itemMatch && itemMatch[1]) {
                // Handle URL encoded paths inside epub
                const href = decodeURIComponent(itemMatch[1]);
                htmlFilesToRead.push(basePath + href);
            }
        });

        let fullText = '';

        // 3. Extract text from each HTML chapter exactly in spine order
        for (const filePath of htmlFilesToRead) {
            const file = zip.file(filePath);
            if (file) {
                const html = await file.async('text');
                fullText += stripHtml(html) + '\n\n';
            }
        }

        if (!fullText.trim()) throw new Error("No readable text found in EPUB.");

        // 4. Tokenize using the same logic as the web version
        const words = fullText
            .split(/\s+/)
            .map(w => w.trim())
            .filter(w => w.length > 0);

        return words;
    } catch (error) {
        console.error("Native EPUB parsing error:", error);
        throw new Error('Failed to parse EPUB file.');
    }
}
