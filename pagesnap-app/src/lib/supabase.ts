import 'react-native-url-polyfill/auto';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { createClient } from '@supabase/supabase-js';

// Actual project credentials from Supabase Dashboard
const supabaseUrl = 'https://mzfunjkzvszwtiqyorsk.supabase.co';
const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im16ZnVuamt6dnN6d3RpcXlvcnNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzIxMTc5NTMsImV4cCI6MjA4NzY5Mzk1M30.e4deWQ5W3s0Nwa-t8fhL-UGANSVG70IGqN81JBERk7o';

export const supabase = createClient(supabaseUrl, supabaseAnonKey, {
    auth: {
        storage: AsyncStorage,
        autoRefreshToken: true,
        persistSession: true,
        detectSessionInUrl: false,
    },
});
