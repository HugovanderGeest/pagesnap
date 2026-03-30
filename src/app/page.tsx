'use client';

import React, { useEffect, useRef, useState } from 'react';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/dist/ScrollTrigger';
import { Upload, Camera, Loader2, Play, Pause, RotateCcw, Maximize2, Minimize2, Settings } from 'lucide-react';
import { processFiles } from '@/utils/extract';

if (typeof window !== 'undefined') {
  gsap.registerPlugin(ScrollTrigger);
}


// Words streamed in the hero background RSVP animation
const HERO_WORDS = 'The human brain processes language at extraordinary speed up to one thousand words per minute yet traditional reading forces your eyes through an exhausting physical obstacle course of saccades line sweeps and constant repositioning Peruse eliminates this friction entirely One word One anchor Pure signal'.split(' ');
const IOS_DOWNLOAD_URL = '#';
const ANDROID_DOWNLOAD_URL = '#';
const APP_STORE_BADGE_SRC = 'https://toolbox.marketingtools.apple.com/api/assets/featured-content/apps/badges/badge-1/en-us.svg';
const GOOGLE_PLAY_BADGE_SRC = 'https://play.google.com/intl/en_us/badges/images/generic/en_badge_web_generic.png';

function HeroRSVP() {
  const [idx, setIdx] = useState(0);
  useEffect(() => {
    const t = setInterval(() => setIdx(i => (i + 1) % HERO_WORDS.length), 260);
    return () => clearInterval(t);
  }, []);
  const w = HERO_WORDS[idx] ?? '';
  const m = Math.ceil(w.length / 2) - 1;
  const pre = w.slice(0, m);
  const piv = w[m];
  const post = w.slice(m + 1);
  return (
    <div className="absolute inset-0 flex items-center justify-center overflow-hidden pointer-events-none select-none"
      style={{ fontFamily: 'var(--font-lexend), sans-serif' }}>
      {/* ghost word cloud */}
      <div className="absolute inset-0 flex flex-wrap content-center justify-center gap-x-8 gap-y-4 opacity-[0.05] px-20">
        {HERO_WORDS.map((word, i) => (
          <span key={i} className="text-white font-bold text-2xl tracking-wider">{word}</span>
        ))}
      </div>
      {/* live centred word */}
      <div className="relative z-10 flex items-baseline font-black leading-none" style={{ fontSize: 'clamp(4rem,10vw,9rem)', opacity: 0.15 }}>
        <span className="text-white">{pre}</span>
        <span style={{ color: '#F59E0B', filter: 'drop-shadow(0 0 50px #F59E0BCC)' }}>{piv}</span>
        <span className="text-white">{post}</span>
      </div>
      {/* radial vignette */}
      <div className="absolute inset-0" style={{ background: 'radial-gradient(ellipse at center, transparent 15%, #0F172A 75%)' }} />
    </div>
  );
}

// Live RSVP inside the hero phone mockup
const PHONE_TEXT = 'She opened the letter slowly. The words blurred together as usual but something felt different today. One. Word. At. A. Time. Her eyes locked on the red pivot letter and for the first time in years reading felt effortless. Her mind flew forward chasing each word like a song.'.split(' ');

function HeroPhoneDemo() {
  const [idx, setIdx] = useState(0);
  const [playing, setPlaying] = useState(true);
  const pivotColor = '#F59E0B';
  const glow = `drop-shadow(0 0 18px ${pivotColor}bb) drop-shadow(0 0 6px ${pivotColor}66)`;

  useEffect(() => {
    if (!playing) return;
    const t = setInterval(() => setIdx(i => {
      if (i + 1 >= PHONE_TEXT.length) { return 0; }
      return i + 1;
    }), 400);
    return () => clearInterval(t);
  }, [playing]);

  const w = PHONE_TEXT[idx] ?? '';
  const m = Math.ceil(w.length / 2) - 1;
  const pre = w.slice(0, m), piv = w[m], post = w.slice(m + 1);
  const progress = Math.round((idx / (PHONE_TEXT.length - 1)) * 100);

  return (
    <div className="absolute inset-0 flex flex-col" style={{ fontFamily: 'var(--font-lexend), sans-serif' }}>
      <div className="flex items-center justify-between px-5 pt-10 pb-2">
        <span className="text-[8px] text-white/20 font-mono uppercase tracking-widest">{idx + 1} / {PHONE_TEXT.length}</span>
        <span className="text-[8px] font-bold font-mono" style={{ color: pivotColor }}>{progress}%</span>
      </div>
      <div className="flex-1 flex items-center justify-center px-4">
        <div style={{ fontWeight: 900, fontSize: '2.4rem', lineHeight: 1, display: 'flex', alignItems: 'baseline' }}>
          <span style={{ color: 'rgba(255,255,255,.55)' }}>{pre}</span>
          <span style={{ color: pivotColor, filter: glow }}>{piv}</span>
          <span style={{ color: 'rgba(255,255,255,.55)' }}>{post}</span>
        </div>
      </div>
      <div className="px-5 pb-8 flex flex-col gap-3">
        <div className="w-full h-[3px] bg-white/10 rounded-full">
          <div className="h-full rounded-full" style={{ width: progress + '%', background: pivotColor }} />
        </div>
        <button
          onClick={() => { if (!playing) { setIdx(0); setPlaying(true); } else setPlaying(p => !p); }}
          className="self-center w-10 h-10 rounded-full flex items-center justify-center text-white text-sm"
          style={{ background: pivotColor, boxShadow: `0 4px 20px ${pivotColor}55` }}
        >
          {playing ? <Pause size={16} fill="currentColor" /> : <Play size={16} fill="currentColor" className="translate-x-[2px]" />}
        </button>
      </div>
    </div>
  );
}

// RSVP Reader — phone shell, fullscreen, auto-hide, dynamic glow, context toggle
function ReaderEngine({ words, wpm, isPlaying, onComplete, currentIndex, onIndexChange, onTogglePlay, onRestart, onSpeedChange }: {
  words: string[]; wpm: number; isPlaying: boolean; onComplete: () => void;
  currentIndex: number; onIndexChange: (i: number) => void; onTogglePlay: () => void;
  onRestart: () => void; onSpeedChange: (e: React.ChangeEvent<HTMLInputElement>) => void;
}) {
  const timerRef = useRef<NodeJS.Timeout | null>(null);
  const containerRef = useRef<HTMLDivElement>(null);
  const hideRef = useRef<NodeJS.Timeout | null>(null);
  const progressBarRef = useRef<HTMLDivElement>(null);
  const isDragging = useRef(false);
  const [pivotColor, setPivotColor] = useState('#F59E0B');
  const [showContext, setShowContext] = useState(true);
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [ctrlVisible, setCtrlVisible] = useState(true);
  const [showSettings, setShowSettings] = useState(false);
  const [fontSize, setFontSize] = useState(64);
  const [readerFont, setReaderFont] = useState<string>('var(--font-lexend), sans-serif');

  const FONTS = [
    { label: 'Lexend', value: 'var(--font-lexend), sans-serif', badge: '★ Best' },
    { label: 'Atkinson', value: 'var(--font-atkinson), sans-serif', badge: 'Braille Inst.' },
    { label: 'OpenDyslexic', value: 'OpenDyslexic, sans-serif', badge: 'ORP Weighted' },
    { label: 'Arial', value: 'Arial, sans-serif', badge: 'Classic' },
  ];

  const glow = "drop-shadow(0 0 22px " + pivotColor + "bb) drop-shadow(0 0 8px " + pivotColor + "66)";

  const bumpControls = () => {
    setCtrlVisible(true);
    if (hideRef.current) clearTimeout(hideRef.current);
    hideRef.current = setTimeout(() => setCtrlVisible(false), 3000);
  };
  useEffect(() => { bumpControls(); return () => { if (hideRef.current) clearTimeout(hideRef.current); }; }, []); // eslint-disable-line

  useEffect(() => {
    const h = () => { if (!document.fullscreenElement) setIsFullscreen(false); };
    document.addEventListener('fullscreenchange', h);
    return () => document.removeEventListener('fullscreenchange', h);
  }, []);

  const toggleFullscreen = async () => {
    if (!isFullscreen) { await containerRef.current?.requestFullscreen?.(); setIsFullscreen(true); }
    else { await document.exitFullscreen?.(); setIsFullscreen(false); }
    bumpControls();
  };

  useEffect(() => {
    if (words.length > 0 && currentIndex >= words.length) setTimeout(() => onComplete(), 0);
  }, [currentIndex, words.length, onComplete]);

  useEffect(() => {
    if (isPlaying && currentIndex < words.length) {
      timerRef.current = setInterval(() => onIndexChange(currentIndex + 1), 60000 / wpm);
    } else { if (timerRef.current) clearInterval(timerRef.current); }
    return () => { if (timerRef.current) clearInterval(timerRef.current); };
  }, [isPlaying, wpm, currentIndex, words.length, onIndexChange]);

  const split = (w: string) => {
    if (!w) return { pre: '', pivot: '', post: '' };
    const m = Math.ceil(w.length / 2) - 1;
    return { pre: w.slice(0, m), pivot: w[m], post: w.slice(m + 1) };
  };

  const currentWord = words[currentIndex] ?? '';
  const prevWord = words[currentIndex - 1] ?? '';
  const nextWord = words[currentIndex + 1] ?? '';
  const { pre, pivot, post } = split(currentWord);
  const progress = words.length > 0 ? Math.round((currentIndex / words.length) * 100) : 0;
  const wordSize = isFullscreen ? 'clamp(3rem,9vw,8rem)' : `${fontSize}px`;

  // Scrub helper — converts a pointer x position to a word index
  const scrubToX = (clientX: number) => {
    const bar = progressBarRef.current;
    if (!bar || words.length === 0) return;
    const { left, width } = bar.getBoundingClientRect();
    const ratio = Math.min(1, Math.max(0, (clientX - left) / width));
    const newIndex = Math.round(ratio * (words.length - 1));
    onIndexChange(newIndex);
  };

  const onPointerDown = (e: React.PointerEvent<HTMLDivElement>) => {
    e.currentTarget.setPointerCapture(e.pointerId);
    isDragging.current = true;
    scrubToX(e.clientX);
  };
  const onPointerMove = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!isDragging.current) return;
    scrubToX(e.clientX);
  };
  const onPointerUp = () => { isDragging.current = false; };

  // Set the correct mobile status bar theme color dependent on fullscreen mode
  useEffect(() => {
    let metaThemeColor = document.querySelector("meta[name=theme-color]") as HTMLMetaElement;
    if (!metaThemeColor) {
      metaThemeColor = document.createElement("meta");
      metaThemeColor.name = "theme-color";
      document.head.appendChild(metaThemeColor);
    }
    metaThemeColor.content = isFullscreen ? "#000000" : "#ffffff";
  }, [isFullscreen]);

  return (
    <div className="w-full flex flex-col">

      {/* ── READER FRAME ── */}
      <div
        ref={containerRef}
        onMouseMove={bumpControls}
        onTouchStart={bumpControls}
        onClick={bumpControls}
        className="relative overflow-hidden select-none w-full"
        style={isFullscreen
          ? { position: 'fixed', inset: 0, zIndex: 9999, backgroundColor: '#000000' }
          : { backgroundColor: '#0F172A', borderRadius: '2rem 2rem 0 0', border: '1px solid #1E293B', borderBottom: 'none', boxShadow: '0 -4px 40px rgba(0,0,0,.4)', height: '400px' }
        }
      >
        {/* guide lines */}
        <div className="absolute inset-y-0 left-1/2 w-px bg-white/[.03] pointer-events-none" />
        <div className="absolute inset-x-0 top-1/2 h-px bg-white/[.03] pointer-events-none" />

        {/* PREV word — offset by fontSize so it never overlaps */}
        {showContext && prevWord && (
          <div className="absolute left-0 right-0 flex justify-center pointer-events-none"
            style={{ top: `calc(50% - ${Math.round(fontSize * 0.9)}px - 28px)` }}>
            <span className="font-bold tracking-wider transition-colors duration-300"
              style={{ color: pivotColor + '30', fontSize: Math.max(14, Math.round(fontSize * 0.32)) + 'px', fontFamily: readerFont }}>
              {prevWord}
            </span>
          </div>
        )}

        {/* CURRENT WORD */}
        <div className="absolute inset-0 flex items-center justify-center px-8 z-10">
          <div style={{ fontWeight: 900, lineHeight: 1, fontSize: isFullscreen ? 'clamp(3rem,9vw,8rem)' : `${fontSize}px`, fontFamily: readerFont, display: 'flex', alignItems: 'baseline' }}>
            <span style={{ color: 'rgba(255,255,255,.6)' }}>{pre}</span>
            <span style={{ color: pivotColor, filter: glow, transition: 'color .2s, filter .2s', minWidth: '.5ch', textAlign: 'center' }}>{pivot}</span>
            <span style={{ color: 'rgba(255,255,255,.6)' }}>{post}</span>
          </div>
        </div>

        {/* NEXT word */}
        {showContext && nextWord && (
          <div className="absolute left-0 right-0 flex justify-center pointer-events-none"
            style={{ top: `calc(50% + ${Math.round(fontSize * 0.55)}px + 10px)` }}>
            <span className="font-bold tracking-wider transition-colors duration-300"
              style={{ color: pivotColor + '30', fontSize: Math.max(14, Math.round(fontSize * 0.32)) + 'px', fontFamily: readerFont }}>
              {nextWord}
            </span>
          </div>
        )}

        {/* DRAGGABLE SCRUB BAR — bottom of reader */}
        <div
          ref={progressBarRef}
          onPointerDown={onPointerDown}
          onPointerMove={onPointerMove}
          onPointerUp={onPointerUp}
          onPointerCancel={onPointerUp}
          className="absolute bottom-0 left-0 right-0 h-8 flex items-end cursor-pointer group z-10"
          title="Drag to seek"
        >
          {/* visible track */}
          <div className="w-full bg-white/5 group-hover:bg-white/10 transition-colors" style={{ height: '4px' }}>
            <div className="h-full rounded-r-full transition-none relative"
              style={{ width: progress + '%', background: pivotColor }}>
              {/* thumb dot */}
              <div className="absolute right-0 top-1/2 -translate-y-1/2 w-3 h-3 rounded-full bg-white opacity-0 group-hover:opacity-100 transition-opacity shadow-md"
                style={{ boxShadow: '0 0 8px ' + pivotColor }} />
            </div>
          </div>
        </div>

        {/* TOP HUD — stats only */}
        <div className="absolute top-4 left-5 right-5 flex items-center justify-between z-20">
          <span className="text-[10px] text-white/20 uppercase tracking-widest font-mono">{currentIndex + 1} / {words.length}</span>
          <span className="text-[10px] font-bold uppercase tracking-widest" style={{ color: pivotColor }}>{progress}%</span>
        </div>

        {/* Auto-hide play controls (fullscreen only — outside they are always visible) */}
        {isFullscreen && (
          <div className="absolute bottom-6 left-0 right-0 flex justify-center z-30 transition-all duration-500"
            style={{ opacity: ctrlVisible ? 1 : 0, pointerEvents: ctrlVisible ? 'auto' : 'none' }}>
            <div className="flex items-center gap-5 bg-black/70 backdrop-blur-lg px-6 py-3 rounded-2xl border border-white/10">
              <button onClick={onRestart} className="w-10 h-10 rounded-full flex items-center justify-center text-white/40 hover:text-white/80 hover:bg-white/10 transition-all" title="Restart">
                <RotateCcw size={16} />
              </button>
              <button onClick={onTogglePlay}
                className="w-14 h-14 rounded-full flex items-center justify-center text-white hover:scale-105 transition-transform"
                style={{ background: pivotColor, boxShadow: '0 4px 28px ' + pivotColor + '55' }}>
                {isPlaying ? <Pause size={22} fill="currentColor" /> : <Play size={22} fill="currentColor" className="translate-x-[2px]" />}
              </button>
              <button onClick={toggleFullscreen}
                className="w-10 h-10 rounded-full flex items-center justify-center text-white/40 hover:text-white/80 hover:bg-white/10 transition-all"
                title="Exit fullscreen">
                <Minimize2 size={16} />
              </button>
              <button onClick={(e) => { e.stopPropagation(); setShowSettings(v => !v); }}
                className="w-10 h-10 rounded-full flex items-center justify-center text-white/40 hover:text-white/80 hover:bg-white/10 transition-all"
                title="Settings">
                <Settings size={16} />
              </button>
            </div>
          </div>
        )}
      </div>

      {/* ── CONTROLS PANEL (below reader, always visible on non-fullscreen) ── */}
      {!isFullscreen && (
        <div className="w-full bg-[#0F172A] border border-[#1E293B] border-t-0 rounded-b-2xl">

          {/* Playback bar — fullscreen · play · settings */}
          <div className="flex items-center justify-between px-6 py-4 border-b border-white/5">
            <button onClick={toggleFullscreen}
              className="w-10 h-10 rounded-full flex items-center justify-center transition-all border"
              style={{ borderColor: 'rgba(255,255,255,.1)', color: 'rgba(255,255,255,.3)' }}
              title={isFullscreen ? 'Exit fullscreen' : 'Fullscreen'}>
              {isFullscreen ? <Minimize2 size={16} /> : <Maximize2 size={16} />}
            </button>
            <button onClick={onTogglePlay}
              className="w-14 h-14 rounded-full flex items-center justify-center text-white hover:scale-105 transition-transform shadow-xl"
              style={{ background: pivotColor, boxShadow: '0 4px 28px ' + pivotColor + '55' }}>
              {isPlaying ? <Pause size={24} fill="currentColor" /> : <Play size={24} fill="currentColor" className="translate-x-[2px]" />}
            </button>
            <button onClick={(e) => { e.stopPropagation(); setShowSettings(v => !v); }}
              className="w-10 h-10 rounded-full flex items-center justify-center transition-all border"
              style={{ borderColor: showSettings ? pivotColor : 'rgba(255,255,255,.1)', color: showSettings ? pivotColor : 'rgba(255,255,255,.3)', background: showSettings ? pivotColor + '15' : 'transparent' }}
              title="Settings">
              <Settings size={18} />
            </button>
          </div>

          {/* Speed slider — always visible */}
          <div className="px-6 py-4 border-b border-white/5">
            <div className="flex items-center justify-between mb-2">
              <span className="text-[10px] text-white/40 uppercase tracking-widest font-mono">Reading Speed</span>
              <span className="text-[10px] font-bold text-white/60 font-mono">{wpm} WPM</span>
            </div>
            <input type="range" min="10" max="1000" step="10" value={wpm} onChange={onSpeedChange}
              className="w-full h-1 rounded-full appearance-none cursor-pointer" style={{ accentColor: pivotColor }} />
          </div>

          {/* Expandable settings */}
          {showSettings && (
            <div className="px-6 py-5 flex flex-col gap-5">

              {/* Font size */}
              <div>
                <div className="flex items-center justify-between mb-2">
                  <span className="text-[10px] text-white/40 uppercase tracking-widest font-mono">Font Size</span>
                  <span className="text-[10px] font-bold text-white/60 font-mono">{fontSize}px</span>
                </div>
                <input type="range" min="24" max="140" step="4" value={fontSize}
                  onChange={e => setFontSize(Number(e.target.value))}
                  className="w-full h-1 rounded-full appearance-none cursor-pointer" style={{ accentColor: pivotColor }} />
              </div>

              {/* Pivot colour */}
              <div>
                <span className="text-[10px] text-white/40 uppercase tracking-widest font-mono block mb-3">Pivot Colour</span>
                <div className="flex items-center gap-3">
                  {['#F59E0B', '#3B82F6', '#10B981', '#E6D53B', '#B03BE6', '#FFFFFF'].map(c => (
                    <button key={c} onClick={() => setPivotColor(c)}
                      className="w-7 h-7 rounded-full border-2 transition-all hover:scale-110 shrink-0"
                      style={{ background: c, borderColor: pivotColor === c ? '#fff' : 'transparent', boxShadow: pivotColor === c ? '0 0 12px ' + c : 'none' }} />
                  ))}
                  <input type="color" value={pivotColor} onChange={e => setPivotColor(e.target.value)}
                    className="w-7 h-7 rounded-full border-0 cursor-pointer bg-transparent shrink-0" title="Custom" />
                </div>
              </div>

              {/* Dyslexia font */}
              <div>
                <span className="text-[10px] text-white/40 uppercase tracking-widest font-mono block mb-3">Dyslexia Font</span>
                <div className="grid grid-cols-2 gap-2">
                  {FONTS.map(f => (
                    <button key={f.value} onClick={() => setReaderFont(f.value)}
                      className="flex flex-col items-start px-3 py-2 rounded-xl border transition-all text-left"
                      style={{ borderColor: readerFont === f.value ? pivotColor : 'rgba(255,255,255,.08)', background: readerFont === f.value ? pivotColor + '18' : 'rgba(255,255,255,.03)', fontFamily: f.value }}>
                      <span className="text-xs font-bold" style={{ color: readerFont === f.value ? pivotColor : 'rgba(255,255,255,.8)' }}>{f.label}</span>
                      <span className="text-[9px] text-white/30 mt-0.5">{f.badge}</span>
                    </button>
                  ))}
                </div>
              </div>

              {/* Context words toggle */}
              <div className="flex items-center justify-between">
                <div>
                  <span className="text-[10px] text-white/40 uppercase tracking-widest font-mono block">Context Words</span>
                  <span className="text-[9px] text-white/20">Show previous &amp; next word</span>
                </div>
                <button onClick={() => setShowContext(v => !v)}
                  className="relative w-11 h-6 rounded-full transition-colors shrink-0"
                  style={{ background: showContext ? pivotColor : '#333' }}>
                  <span className="absolute top-1 w-4 h-4 rounded-full bg-white shadow transition-all"
                    style={{ left: showContext ? '24px' : '4px' }} />
                </button>
              </div>

            </div>
          )}
        </div>
      )}
    </div>
  );
}


export default function Home() {
  const mainRef = useRef<HTMLDivElement>(null);

  // App State
  const [files, setFiles] = useState<File[]>([]);
  const [words, setWords] = useState<string[]>([]);
  const [status, setStatus] = useState<'idle' | 'processing' | 'ready' | 'reading'>('idle');
  const [wpm, setWpm] = useState(300);
  const [isPlaying, setIsPlaying] = useState(false);
  const [currentIndex, setCurrentIndex] = useState(0);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Animations
  useEffect(() => {
    const ctx = gsap.context(() => {
      // Navbar logic
      ScrollTrigger.create({
        trigger: 'body',
        start: 'top -100px',
        end: 'bottom',
        onUpdate: (self) => {
          if (self.direction === 1) {
            gsap.to('.nav-glass', { backgroundColor: 'rgba(232, 228, 221, 0.8)', borderColor: 'rgba(17, 17, 17, 0.1)', backdropFilter: 'blur(16px)', duration: 0.3 });
            gsap.to('.nav-text', { color: '#111111', duration: 0.3 });
          } else if (self.progress === 0 || self.direction === -1 && window.scrollY < 100) {
            gsap.to('.nav-glass', { backgroundColor: 'transparent', borderColor: 'transparent', backdropFilter: 'blur(0px)', duration: 0.3 });
            gsap.to('.nav-text', { color: '#ffffff', duration: 0.3 });
          }
        }
      });

      // Hero animations
      gsap.from('.hero-part', {
        y: 60,
        opacity: 0,
        stagger: 0.1,
        duration: 1.2,
        ease: 'power3.out',
        delay: 0.2
      });

    }, mainRef);

    return () => ctx.revert();
  }, []);

  // Handlers for actual App func
  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files && e.target.files.length > 0) {
      const selectedFiles = Array.from(e.target.files);
      setFiles(selectedFiles);

      setTimeout(() => {
        const getStartedSection = document.getElementById('get-started');
        getStartedSection?.scrollIntoView({ behavior: 'smooth' });
      }, 100);

      setStatus('processing');
      try {
        const extractedWords = await processFiles(selectedFiles);
        setWords(extractedWords);
        setStatus('ready');
      } catch (error) {
        console.error(error);
        alert(error instanceof Error ? error.message : 'Failed to process file. Please try again.');
        setStatus('idle');
      }
    }
  };

  const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  return (
    <main ref={mainRef} className="bg-background text-foreground overflow-x-hidden selection:bg-accent selection:text-white">

      {/* NAVBAR */}
      <nav className="fixed top-6 left-1/2 -translate-x-1/2 z-50 flex items-center justify-between gap-4 px-4 py-3 w-[94%] max-w-6xl rounded-full nav-glass nav-text text-white transition-all duration-300">
        <div className="font-bold text-xl uppercase tracking-tighter">Peruse</div>
        <div className="flex items-center gap-2 sm:gap-3">
          <a
            href={IOS_DOWNLOAD_URL}
            aria-label="Download on the App Store"
            className="transition-transform hover:scale-[1.02]"
          >
            <img src={APP_STORE_BADGE_SRC} alt="Download on the App Store" className="h-11 w-auto" />
          </a>
          <a
            href={ANDROID_DOWNLOAD_URL}
            aria-label="Get it on Google Play"
            className="transition-transform hover:scale-[1.02]"
          >
            <img src={GOOGLE_PLAY_BADGE_SRC} alt="Get it on Google Play" className="h-11 w-auto" />
          </a>
          <button
            onClick={() => document.getElementById('get-started')?.scrollIntoView({ behavior: 'smooth' })}
            className="hidden lg:inline-flex bg-accent text-white px-6 py-2 rounded-full uppercase text-xs font-bold tracking-widest btn-magnetic"
          >
            <span>Try Demo</span>
          </button>
        </div>
      </nav>

      {/* HERO SECTION — split layout */}
      <section id="top" className="relative w-full min-h-[100dvh] flex items-center bg-dark overflow-hidden">

        {/* ── SIMPLE GRADIENT BACKGROUND ── */}
        <div className="absolute inset-x-0 bottom-0 h-1/2 bg-gradient-to-t from-accent/10 to-transparent pointer-events-none" />

        <div className="relative z-10 w-full max-w-7xl mx-auto px-6 py-24 flex flex-col lg:flex-row items-center gap-16">

          {/* LEFT — headline + CTA */}
          <div className="flex-1 flex flex-col gap-8">
            <h1 className="flex flex-col text-white">
              <span className="hero-part font-heading font-bold text-3xl md:text-4xl uppercase tracking-tighter mb-2 text-white/60">Read at the speed of</span>
              <span className="hero-part text-drama text-[5rem] md:text-[8rem] leading-[0.85] text-white">Thought.</span>
            </h1>
            <p className="hero-part font-mono text-white/50 max-w-md uppercase tracking-widest text-sm leading-relaxed">
              Designed for dyslexic readers. One word. One anchor. Zero friction.
            </p>
            <div className="hero-part flex flex-col sm:flex-row gap-4 items-start">
              <button
                onClick={() => document.getElementById('get-started')?.scrollIntoView({ behavior: 'smooth' })}
                className="bg-accent text-white px-10 py-5 rounded-full uppercase font-bold tracking-[0.2em] text-sm btn-magnetic inline-flex items-center gap-4"
              >
                <span>Try It Yourself</span>
                <span className="block w-2 h-2 rounded-full bg-white animate-pulse"></span>
              </button>
              <button
                onClick={() => document.getElementById('get-started')?.scrollIntoView({ behavior: 'smooth' })}
                className="border border-white/20 text-white/60 hover:text-white hover:border-white/50 px-8 py-5 rounded-full uppercase text-xs font-bold tracking-[0.2em] transition-all"
              >
                Jump To Demo
              </button>
            </div>
          </div>

          {/* RIGHT — live phone-sized RSVP demo */}
          <div className="hero-part flex-shrink-0 flex flex-col items-center gap-4">
            <div
              className="relative bg-[#0F172A] overflow-hidden select-none"
              style={{ width: '280px', height: '520px', borderRadius: '2.5rem', border: '1px solid rgba(255,255,255,0.12)', boxShadow: '0 40px 80px rgba(0,0,0,0.8), inset 0 0 0 1px rgba(255,255,255,0.05)' }}
            >
              {/* status bar */}
              <div className="absolute top-4 left-0 right-0 flex justify-center">
                <div className="w-20 h-1 rounded-full bg-white/10" />
              </div>
              {/* notch */}
              <div className="absolute top-0 left-1/2 -translate-x-1/2 w-24 h-7 bg-[#0F172A] rounded-b-2xl z-20" />
              {/* HeroRSVP miniature */}
              <HeroPhoneDemo />
              {/* bottom bar */}
              <div className="absolute bottom-3 left-0 right-0 flex justify-center">
                <div className="w-24 h-1 rounded-full bg-white/20" />
              </div>
            </div>
            <button
              onClick={() => document.getElementById('get-started')?.scrollIntoView({ behavior: 'smooth' })}
              className="text-white/50 hover:text-white text-xs font-mono uppercase tracking-widest flex items-center gap-2 transition-colors"
            >
              <span>↓ Try it with your own book</span>
            </button>
          </div>

        </div>
      </section>

      {/* DEMO */}
      <section id="get-started" className="py-40 px-6 w-full max-w-5xl mx-auto flex flex-col items-center">
        <div className="text-center mb-16">
          <h2 className="font-heading text-5xl font-bold uppercase tracking-tighter mb-6 text-dark drop-shadow-md">Try The Demo</h2>
          <p className="font-mono text-dark/60 max-w-lg mx-auto uppercase tracking-widest text-sm leading-relaxed">
            Upload text documents or photos of book pages and test the Peruse reading demo directly in the browser.
          </p>
        </div>

        {status === 'idle' && (
          <div className="w-full max-w-2xl bg-surface border border-black/10 rounded-[3rem] p-12 shadow-2xl animate-fade-in relative overflow-hidden">
            <div className="absolute top-0 right-0 w-64 h-64 bg-accent/5 rounded-full blur-3xl translate-x-1/2 -translate-y-1/2"></div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-6 relative z-10">
              <button
                onClick={() => fileInputRef.current?.click()}
                className="group h-[180px] rounded-[2rem] border-2 border-dashed border-dark/20 hover:border-accent bg-background hover:bg-white flex flex-col items-center justify-center gap-4 transition-all duration-300"
              >
                <div className="w-16 h-16 rounded-full bg-dark/5 group-hover:bg-accent/10 flex items-center justify-center transition-colors">
                  <Upload size={28} className="text-dark group-hover:text-accent transition-colors" />
                </div>
                <span className="font-heading font-bold uppercase tracking-widest text-sm text-dark">Upload Data</span>
                <input
                  type="file"
                  ref={fileInputRef}
                  onChange={handleFileChange}
                  multiple
                  accept="image/*,application/pdf,application/epub+zip,.epub,.txt,text/plain"
                  className="hidden"
                />
              </button>

              <button
                onClick={() => fileInputRef.current?.click()}
                className="group h-[180px] rounded-[2rem] border-2 border-transparent bg-dark hover:bg-black flex flex-col items-center justify-center gap-4 transition-all duration-300 shadow-xl"
              >
                <div className="w-16 h-16 rounded-full bg-white/10 group-hover:bg-accent/20 flex items-center justify-center transition-colors">
                  <Camera size={28} className="text-white group-hover:text-accent transition-colors" />
                </div>
                <span className="font-heading font-bold uppercase tracking-widest text-sm text-white">Capture Data</span>
              </button>
            </div>
          </div>
        )}

        {status === 'processing' && (
          <div className="w-full max-w-2xl bg-surface border border-black/10 rounded-[3rem] p-20 shadow-2xl flex flex-col items-center text-center">
            <Loader2 size={64} className="text-accent animate-spin mb-8" />
            <h3 className="font-heading text-3xl font-bold uppercase tracking-tighter mb-4">Extracting Signal...</h3>
            <p className="font-mono text-dark/50 text-sm uppercase tracking-widest">Running Optical Character Recognition Protocol</p>
          </div>
        )}
        {(status === 'ready' || status === 'reading') && (
          <div className="w-full mt-4">
            <h3 className="text-center font-heading text-3xl mb-8 font-bold uppercase tracking-tighter text-dark">Engine Active</h3>
            <div className="w-full rounded-[2rem] bg-[#0d0d0d] p-6 shadow-2xl border border-white/5">
              <ReaderEngine
                words={words} wpm={wpm} isPlaying={isPlaying} currentIndex={currentIndex}
                onComplete={() => { setIsPlaying(false); setStatus('ready'); }}
                onIndexChange={setCurrentIndex} onRestart={() => { setIsPlaying(false); setCurrentIndex(0); }}
                onTogglePlay={() => setIsPlaying(!isPlaying)} onSpeedChange={(e: React.ChangeEvent<HTMLInputElement>) => setWpm(parseInt(e.target.value))}
              />
            </div>
          </div>
        )}
      </section>

      {/* FOOTER */}
      <footer className="w-full bg-dark text-white rounded-t-[4rem] px-8 py-20 mt-20 relative overflow-hidden">
        <div className="absolute inset-x-0 bottom-0 h-1/2 bg-gradient-to-t from-accent/10 to-transparent pointer-events-none"></div>
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row justify-between items-start gap-16 relative z-10">
          <div className="flex flex-col gap-6 max-w-sm">
            <div className="font-bold text-3xl uppercase tracking-tighter text-white">Peruse</div>
            <p className="font-mono text-sm uppercase tracking-widest text-accent">Copyright &copy; 2026 Peruse. All rights reserved.</p>
            <p className="font-mono text-white/50 text-xs uppercase tracking-widest leading-loose">
              Biological data processed at maximum velocity. The ultimate dyslexia-optimized reading protocol.
            </p>
          </div>
          <div className="flex flex-col gap-4 font-mono text-xs uppercase tracking-widest text-white/50 text-right">
            <div className="flex items-center justify-end gap-3 mb-6">
              <span className="animate-pulse w-3 h-3 rounded-full bg-green-500 shadow-[0_0_12px_rgba(34,197,94,0.8)]"></span>
              <span className="text-white">System Operational</span>
            </div>
            <a href="#" className="hover:text-accent transition-colors">Privacy Policy</a>
            <a href="#" className="hover:text-accent transition-colors">Terms of Service</a>
            <a href="#" className="hover:text-accent transition-colors">Support Array</a>
          </div>
        </div>
      </footer>
    </main>
  );
}
