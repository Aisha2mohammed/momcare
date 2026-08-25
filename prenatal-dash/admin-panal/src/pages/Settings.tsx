import { useState } from 'react';
import { Save, Bell, Lock, Globe, Shield, Palette } from 'lucide-react';
import { Card } from '../components/ui/Card';
import { Button } from '../components/ui/Button';
import { Input, Select } from '../components/ui/Input';

export default function Settings() {
    const [adminName, setAdminName] = useState('Admin User');
    const [email, setEmail] = useState('admin@pregnancy-app.et');
    const [language, setLanguage] = useState('en');
    const [notifications, setNotifications] = useState(true);
    const [saved, setSaved] = useState(false);

    function handleSave() {
        setSaved(true);
        setTimeout(() => setSaved(false), 2500);
    }

    return (
        <div className="space-y-6 max-w-3xl">
            <div>
                <h2 className="text-2xl font-bold text-[#61183e]">Settings</h2>
                <p className="text-gray-500 text-sm mt-0.5">Configure your admin panel preferences</p>
            </div>

            {saved && (
                <div className="flex items-center gap-3 p-4 bg-green-50 border border-green-200 rounded-xl text-green-700 text-sm font-medium">
                    ✓ Settings saved successfully!
                </div>
            )}

            <Card>
                <div className="flex items-center gap-3 mb-5">
                    <div className="p-2 rounded-lg bg-[#fdf2f8]"><Shield className="w-5 h-5 text-[#61183e]" /></div>
                    <h3 className="font-semibold text-gray-900">Admin Account</h3>
                </div>
                <div className="space-y-4">
                    <Input label="Admin Name" value={adminName} onChange={e => setAdminName(e.target.value)} />
                    <Input label="Email Address" type="email" value={email} onChange={e => setEmail(e.target.value)} />
                    <Input label="New Password" type="password" placeholder="Leave blank to keep current" />
                    <Input label="Confirm New Password" type="password" placeholder="Repeat new password" />
                </div>
            </Card>

            <Card>
                <div className="flex items-center gap-3 mb-5">
                    <div className="p-2 rounded-lg bg-blue-50"><Globe className="w-5 h-5 text-blue-600" /></div>
                    <h3 className="font-semibold text-gray-900">Localization</h3>
                </div>
                <Select
                    label="Admin Panel Language"
                    value={language}
                    onChange={e => setLanguage(e.target.value)}
                    options={[{ value: 'en', label: 'English' }, { value: 'am', label: 'Amharic (አማርኛ)' }, { value: 'or', label: 'Afan Oromo' }]}
                />
            </Card>

            <Card>
                <div className="flex items-center gap-3 mb-5">
                    <div className="p-2 rounded-lg bg-amber-50"><Bell className="w-5 h-5 text-amber-600" /></div>
                    <h3 className="font-semibold text-gray-900">Notifications</h3>
                </div>
                <div className="space-y-4">
                    {[
                        { label: 'Email Notifications', desc: 'Receive email alerts for new user signups' },
                        { label: 'Push Notification Alerts', desc: 'Get alerted when notifications fail to deliver' },
                        { label: 'Weekly Analytics Report', desc: 'Receive weekly summary of app usage' },
                    ].map((item, i) => (
                        <div key={i} className="flex items-center justify-between p-4 bg-gray-50 rounded-xl">
                            <div>
                                <p className="font-medium text-gray-800 text-sm">{item.label}</p>
                                <p className="text-xs text-gray-500 mt-0.5">{item.desc}</p>
                            </div>
                            <div
                                onClick={() => setNotifications(p => !p)}
                                className={`w-11 h-6 rounded-full transition-colors relative cursor-pointer ${notifications ? 'bg-[#61183e]' : 'bg-gray-300'}`}
                            >
                                <div className={`absolute top-1 w-4 h-4 rounded-full bg-white transition-all ${notifications ? 'left-6' : 'left-1'}`} />
                            </div>
                        </div>
                    ))}
                </div>
            </Card>

            <Card>
                <div className="flex items-center gap-3 mb-5">
                    <div className="p-2 rounded-lg bg-purple-50"><Palette className="w-5 h-5 text-purple-600" /></div>
                    <h3 className="font-semibold text-gray-900">Appearance</h3>
                </div>
                <div className="flex gap-4">
                    {['Light', 'System'].map(mode => (
                        <button key={mode} className={`px-6 py-3 rounded-xl border-2 text-sm font-medium transition-colors ${mode === 'Light' ? 'border-[#61183e] bg-[#fdf2f8] text-[#61183e]' : 'border-gray-200 text-gray-600 hover:border-gray-300'}`}>
                            {mode}
                        </button>
                    ))}
                </div>
            </Card>

            <div className="flex justify-end">
                <Button size="lg" icon={<Save className="w-5 h-5" />} onClick={handleSave}>Save All Settings</Button>
            </div>
        </div>
    );
}
