import React, { useState } from 'react';
import { View, Text, TextInput, TouchableOpacity, StyleSheet, ActivityIndicator, Alert } from 'react-native';
import { supabase } from '../lib/supabase';
import { THEME } from '../theme';
import { LinearGradient } from 'expo-linear-gradient';

export default function AuthScreen() {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [loading, setLoading] = useState(false);

    async function signInWithEmail() {
        setLoading(true);
        const { error } = await supabase.auth.signInWithPassword({ email, password });
        if (error) Alert.alert('Error', error.message);
        setLoading(false);
    }

    async function signUpWithEmail() {
        setLoading(true);
        const { data, error } = await supabase.auth.signUp({ email, password });
        if (error) Alert.alert('Error', error.message);
        else if (data?.user) Alert.alert('Success', 'Check your email for the login link!');
        setLoading(false);
    }

    return (
        <View style={styles.container}>
            <LinearGradient
                colors={[THEME.colors.background, 'transparent']}
                style={StyleSheet.absoluteFill}
            />

            <View style={styles.content}>
                <Text style={styles.title}>PAGESNAP</Text>
                <Text style={styles.subtitle}>Read at the speed of thought.</Text>

                <View style={styles.inputContainer}>
                    <TextInput
                        style={styles.input}
                        placeholder="Email"
                        placeholderTextColor={THEME.colors.textDim}
                        onChangeText={setEmail}
                        value={email}
                        autoCapitalize="none"
                        keyboardType="email-address"
                    />
                    <TextInput
                        style={styles.input}
                        placeholder="Password"
                        placeholderTextColor={THEME.colors.textDim}
                        onChangeText={setPassword}
                        value={password}
                        secureTextEntry
                    />
                </View>

                <View style={styles.buttonContainer}>
                    <TouchableOpacity
                        style={[styles.button, styles.primaryButton]}
                        onPress={signInWithEmail}
                        disabled={loading}
                    >
                        {loading ? <ActivityIndicator color="#fff" /> : <Text style={styles.buttonText}>Sign In</Text>}
                    </TouchableOpacity>

                    <TouchableOpacity
                        style={[styles.button, styles.secondaryButton]}
                        onPress={signUpWithEmail}
                        disabled={loading}
                    >
                        <Text style={styles.buttonTextSecondary}>Create Account</Text>
                    </TouchableOpacity>
                </View>
            </View>
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: THEME.colors.background,
    },
    content: {
        flex: 1,
        justifyContent: 'center',
        padding: THEME.spacing.xl,
        paddingTop: THEME.spacing.xxl,
    },
    title: {
        color: THEME.colors.text,
        fontSize: 48,
        fontWeight: '900',
        letterSpacing: -2,
        textAlign: 'center',
        marginBottom: THEME.spacing.xs,
    },
    subtitle: {
        color: THEME.colors.textDim,
        fontSize: 16,
        letterSpacing: 2,
        textAlign: 'center',
        textTransform: 'uppercase',
        marginBottom: THEME.spacing.xxl,
    },
    inputContainer: {
        gap: THEME.spacing.md,
        marginBottom: THEME.spacing.xl,
    },
    input: {
        backgroundColor: THEME.colors.surface,
        color: THEME.colors.text,
        borderRadius: THEME.border.radius,
        padding: 20,
        fontSize: 16,
        borderWidth: 1,
        borderColor: THEME.colors.border,
    },
    buttonContainer: {
        gap: THEME.spacing.md,
    },
    button: {
        padding: 20,
        borderRadius: THEME.border.radius,
        alignItems: 'center',
        justifyContent: 'center',
    },
    primaryButton: {
        backgroundColor: THEME.colors.primary,
    },
    secondaryButton: {
        backgroundColor: 'transparent',
        borderWidth: 1,
        borderColor: THEME.colors.border,
    },
    buttonText: {
        color: THEME.colors.text,
        fontSize: 16,
        fontWeight: 'bold',
        letterSpacing: 1,
        textTransform: 'uppercase',
    },
    buttonTextSecondary: {
        color: THEME.colors.text,
        fontSize: 16,
        fontWeight: 'bold',
        letterSpacing: 1,
        textTransform: 'uppercase',
    }
});
