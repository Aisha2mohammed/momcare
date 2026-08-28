import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Eye, EyeOff, KeyRound, Mail, Shield } from 'lucide-react';

export default function Login() {
    const { login } = useAuth();
    const navigate = useNavigate();

    const [email, setEmail] = useState('admin@momcare.et');
    const [password, setPassword] = useState('');
    const [twofa, setTwofa] = useState('');
    const [showPassword, setShowPassword] = useState(false);
    const [show2FA, setShow2FA] = useState(false);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [showForgot, setShowForgot] = useState(false);
    const [forgotEmail, setForgotEmail] = useState('');
    const [forgotSent, setForgotSent] = useState(false);

    const handleSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        const result = await login(email, password, twofa || undefined);
        setLoading(false);
        if (result.success) {
            navigate('/');
        } else {
            setError(result.error ?? 'Login failed');
        }
    };

    const handleForgotSubmit = async (e: React.FormEvent) => {
        e.preventDefault();
        await new Promise(r => setTimeout(r, 800));
        setForgotSent(true);
        console.log(`[EMAIL STUB] Password reset link sent to ${forgotEmail}`);
    };

    return (
        <div className="min-h-screen bg-gradient-to-br from-[#fdf2f8] via-white to-blue-50 flex">
            {/* Left panel — branding */}
            <div className="hidden lg:flex lg:w-1/2 bg-gradient-to-br from-[#61183e] to-[#8b2563] flex-col items-center justify-center p-16 text-white relative overflow-hidden">
                {/* Decorative circles */}
                <div className="absolute top-0 right-0 w-64 h-64 rounded-full bg-white/5 -translate-y-1/2 translate-x-1/2" />
                <div className="absolute bottom-0 left-0 w-48 h-48 rounded-full bg-white/5 translate-y-1/2 -translate-x-1/2" />

                <div className="relative z-10 text-center max-w-md">
                    <div className="flex items-center justify-center mb-4 mx-auto">
                        <img src="/pregnancy-logo.png" alt="Mom Care" className="w-80 h-80  p-2" />
                    </div>
                    <p className="text-white/80 text-lg leading-relaxed mb-4">
                        Maternal Health Management Platform for Ethiopia — empowering mothers, doctors, and health providers.
                    </p>
                    <div className="grid grid-cols-3 gap-4 text-center">
                        {[
                            { label: 'Registered Mothers', val: '1,284' },
                            { label: 'Licensed Doctors', val: '12' },
                            { label: 'Health Providers', val: '4' },
                        ].map(s => (
                            <div key={s.label} className="bg-white/10 rounded-xl p-4 backdrop-blur-sm">
                                <p className="text-2xl font-bold">{s.val}</p>
                                <p className="text-xs text-white/70 mt-1">{s.label}</p>
                            </div>
                        ))}
                    </div>
                </div>
            </div>

            {/* Right panel — form */}
            <div className="flex-1 flex items-center justify-center p-8">
                <div className="w-full max-w-md">
                    {/* Mobile logo */}
                    <div className="flex items-center gap-3 mb-10 lg:hidden">
                        <img src="/pregnancy-logo.png" alt="Mom Care" className="w-12 h-12 object-contain" />
                        <h1 className="text-xl font-bold text-[#61183e]">Mom Care Admin</h1>
                    </div>

                    <div className="mb-8">
                        <h2 className="text-2xl font-bold text-gray-900">Welcome back</h2>
                        <p className="text-gray-500 mt-1">Sign in to the admin dashboard</p>
                    </div>

                    {/* Forgot password modal */}
                    {showForgot ? (
                        <div className="bg-blue-50 border border-blue-200 rounded-2xl p-6">
                            <h3 className="font-semibold text-gray-900 mb-1">Reset Password</h3>
                            {forgotSent ? (
                                <div>
                                    <p className="text-sm text-green-700 bg-green-50 border border-green-200 rounded-lg p-3 mb-4">
                                        ✓ Password reset link sent to <strong>{forgotEmail}</strong>. Check your email.
                                    </p>
                                    <button onClick={() => { setShowForgot(false); setForgotSent(false); }} className="text-sm text-[#61183e] font-medium hover:underline">
                                        ← Back to login
                                    </button>
                                </div>
                            ) : (
                                <form onSubmit={handleForgotSubmit} className="space-y-4">
                                    <p className="text-sm text-gray-600 mb-4">Enter your admin email to receive a password reset link.</p>
                                    <div className="relative">
                                        <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                                        <input
                                            type="email"
                                            required
                                            value={forgotEmail}
                                            onChange={e => setForgotEmail(e.target.value)}
                                            placeholder="admin@momcare.et"
                                            className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl text-sm focus:outline-none focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20"
                                        />
                                    </div>
                                    <div className="flex gap-3">
                                        <button type="submit" className="flex-1 py-3 bg-[#61183e] text-white rounded-xl text-sm font-semibold hover:bg-[#7a2050] transition-colors">Send Reset Link</button>
                                        <button type="button" onClick={() => setShowForgot(false)} className="flex-1 py-3 border border-gray-200 rounded-xl text-sm font-medium text-gray-600 hover:bg-gray-50 transition-colors">Cancel</button>
                                    </div>
                                </form>
                            )}
                        </div>
                    ) : (
                        <form onSubmit={handleSubmit} className="space-y-5" autoComplete="off">
                            {/* Email */}
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1.5">Email Address</label>
                                <div className="relative">
                                    <Mail className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                                    <input
                                        type="email"
                                        required
                                        value={email}
                                        onChange={e => setEmail(e.target.value)}
                                        placeholder="admin@momcare.et"
                                        className="w-full pl-10 pr-4 py-3 border border-gray-200 rounded-xl text-sm focus:outline-none focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20 bg-white"
                                    />
                                </div>
                            </div>

                            {/* Password */}
                            <div>
                                <label className="block text-sm font-medium text-gray-700 mb-1.5">Password</label>
                                <div className="relative">
                                    <KeyRound className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400" />
                                    <input
                                        type={showPassword ? 'text' : 'password'}
                                        required
                                        value={password}
                                        onChange={e => setPassword(e.target.value)}
                                        placeholder="Enter your password"
                                        className="w-full pl-10 pr-12 py-3 border border-gray-200 rounded-xl text-sm focus:outline-none focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20 bg-white"
                                    />
                                    <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600">
                                        {showPassword ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                                    </button>
                                </div>
                            </div>

                            {/* 2FA toggle + field */}
                            <div>
                                <button type="button" onClick={() => setShow2FA(!show2FA)} className="flex items-center gap-2 text-sm text-[#61183e] font-medium hover:underline">
                                    <Shield className="w-3.5 h-3.5" />
                                    {show2FA ? 'Hide 2FA Code' : 'I have a 2FA code'}
                                </button>
                                {show2FA && (
                                    <div className="mt-2">
                                        <input
                                            type="text"
                                            value={twofa}
                                            onChange={e => setTwofa(e.target.value)}
                                            placeholder="Enter 6-digit 2FA code"
                                            maxLength={6}
                                            className="w-full px-4 py-3 border border-gray-200 rounded-xl text-sm font-mono focus:outline-none focus:border-[#61183e] focus:ring-2 focus:ring-[#61183e]/20 bg-white tracking-[0.3em]"
                                        />
                                    </div>
                                )}
                            </div>

                            {/* Forgot password */}
                            <div className="flex justify-end">
                                <button type="button" onClick={() => setShowForgot(true)} className="text-sm text-[#61183e] hover:underline font-medium">
                                    Forgot password?
                                </button>
                            </div>

                            {/* Error */}
                            {error && (
                                <p className="text-sm text-red-600 bg-red-50 border border-red-200 rounded-lg px-4 py-3">
                                    ⚠ {error}
                                </p>
                            )}

                            {/* Submit */}
                            <button
                                type="submit"
                                disabled={loading}
                                className="w-full py-3.5 bg-[#61183e] text-white rounded-xl font-semibold text-sm hover:bg-[#7a2050] transition-colors disabled:opacity-60 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                            >
                                {loading ? (
                                    <>
                                        <span className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                                        Signing in...
                                    </>
                                ) : 'Sign In'}
                            </button>

                            {/* Demo hint */}
                            <p className="text-center text-xs text-gray-400">
                                Demo: <span className="font-mono">admin@momcare.et</span> / <span className="font-mono">Admin123!</span>
                            </p>
                        </form>
                    )}
                </div>
            </div>
        </div>
    );
}
