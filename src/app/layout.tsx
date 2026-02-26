import type { Metadata } from 'next'
import { Space_Grotesk, DM_Serif_Display, Space_Mono, Lexend, Atkinson_Hyperlegible } from 'next/font/google'
import './globals.css'

const spaceGrotesk = Space_Grotesk({ subsets: ['latin'], variable: '--font-heading' })
const dmSerif = DM_Serif_Display({ weight: '400', subsets: ['latin'], style: ['italic', 'normal'], variable: '--font-drama' })
const spaceMono = Space_Mono({ weight: ['400', '700'], subsets: ['latin'], variable: '--font-mono' })

// Dyslexia-optimised fonts — loaded eagerly so the reader can swap instantly
const lexend = Lexend({ subsets: ['latin'], variable: '--font-lexend', weight: ['400', '500', '600', '700'] })
const atkinson = Atkinson_Hyperlegible({ subsets: ['latin'], variable: '--font-atkinson', weight: ['400', '700'] })

export const metadata: Metadata = {
  title: 'PageSnap | Digital Reading Engine',
  description: 'Upload books digitally and read faster than ever before.',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <head>
        {/* OpenDyslexic — not on Google Fonts, loaded via CDN */}
        <link
          rel="stylesheet"
          href="https://cdn.jsdelivr.net/npm/opendyslexic@0.91.12/opendyslexic.css"
        />
      </head>
      <body className={`${spaceGrotesk.variable} ${dmSerif.variable} ${spaceMono.variable} ${lexend.variable} ${atkinson.variable} font-heading bg-background text-foreground antialiased relative`}>
        <div
          className="pointer-events-none fixed inset-0 z-50 h-full w-full opacity-[0.05]"
          style={{ backgroundImage: 'url("data:image/svg+xml,%3Csvg viewBox=\'0 0 200 200\' xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cfilter id=\'noiseFilter\'%3E%3CfeTurbulence type=\'fractalNoise\' baseFrequency=\'0.65\' numOctaves=\'3\' stitchTiles=\'stitch\'/%3E%3C/filter%3E%3Crect width=\'100%25\' height=\'100%25\' filter=\'url(%23noiseFilter)\'/%3E%3C/svg%3E")' }}
        />
        {children}
      </body>
    </html>
  )
}
