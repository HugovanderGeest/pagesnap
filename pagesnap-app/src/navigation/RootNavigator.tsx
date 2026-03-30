import React, { useEffect, useState } from 'react';
import { NavigationContainer, DarkTheme } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { BlurView } from 'expo-blur';
import { View, StyleSheet, Platform } from 'react-native';
import { Library, Settings, BookOpen } from 'lucide-react-native';
import { supabase } from '../lib/supabase';
import { THEME } from '../theme';

// Screens
import AuthScreen from '../screens/AuthScreen';
import LibraryScreen from '../screens/LibraryScreen';
import ReaderScreen from '../screens/ReaderScreen';

const Stack = createNativeStackNavigator();
const Tab = createBottomTabNavigator();

function TabNavigator() {
    return (
        <Tab.Navigator
            screenOptions={{
                headerShown: false,
                tabBarStyle: {
                    position: 'absolute',
                    borderTopWidth: 0,
                    elevation: 0,
                    backgroundColor: 'transparent',
                    height: Platform.OS === 'ios' ? 88 : 70,
                },
                tabBarBackground: () => (
                    <BlurView
                        tint="dark"
                        intensity={80}
                        style={StyleSheet.absoluteFill}
                    />
                ),
                tabBarActiveTintColor: THEME.colors.primary,
                tabBarInactiveTintColor: THEME.colors.textDim,
                tabBarShowLabel: false,
            }}
        >
            <Tab.Screen
                name="LibraryTab"
                component={LibraryScreen}
                options={{
                    tabBarIcon: ({ color, size }) => <Library color={color} size={24} />
                }}
            />
            {/* Real app would have a SettingsTab here */}
            <Tab.Screen
                name="SettingsTab"
                component={View}
                options={{
                    tabBarIcon: ({ color, size }) => <Settings color={color} size={24} />,
                }}
                listeners={{
                    tabPress: e => {
                        // Prevent default action for now since it's an empty view
                        e.preventDefault();
                        alert('Settings coming soon');
                    }
                }}
            />
        </Tab.Navigator>
    );
}

export default function RootNavigator() {
    const [session, setSession] = useState<any>(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        supabase.auth.getSession().then(({ data: { session } }) => {
            setSession(session);
            setLoading(false);
        });

        supabase.auth.onAuthStateChange((_event, session) => {
            setSession(session);
        });
    }, []);

    if (loading) {
        return <View style={{ flex: 1, backgroundColor: THEME.colors.background }} />;
    }

    return (
        <NavigationContainer theme={{
            ...DarkTheme,
            colors: {
                ...DarkTheme.colors,
                background: THEME.colors.background,
                text: THEME.colors.text,
            }
        }}>
            <Stack.Navigator screenOptions={{ headerShown: false, animation: 'fade' }}>
                {session ? (
                    <>
                        <Stack.Screen name="MainTabs" component={TabNavigator} />
                        <Stack.Screen
                            name="Reader"
                            component={ReaderScreen}
                            options={{ animation: 'slide_from_bottom', presentation: 'fullScreenModal' }}
                        />
                    </>
                ) : (
                    <Stack.Screen name="Auth" component={AuthScreen} />
                )}
            </Stack.Navigator>
        </NavigationContainer>
    );
}
