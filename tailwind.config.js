/** @type {import('tailwindcss').Config} */
module.exports = {
    content: [
        './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
        './src/components/**/*.{js,ts,jsx,tsx,mdx}',
        './src/app/**/*.{js,ts,jsx,tsx,mdx}',
    ],
    theme: {
        extend: {
            colors: {
                background: '#F8FAFC',
                foreground: '#0F172A',
                primary: '#F8FAFC',
                accent: '#F59E0B',
                azure: '#3B82F6',
                surface: '#FFFFFF',
                dark: '#0F172A'
            },
            fontFamily: {
                heading: ['"Space Grotesk"', 'sans-serif'],
                drama: ['"DM Serif Display"', 'serif'],
                mono: ['"Space Mono"', 'monospace'],
            },
        },
    },
    plugins: [],
}
