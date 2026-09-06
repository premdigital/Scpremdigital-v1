'use client';

import { useState } from 'react';
import { Server, UserPlus, Lock, Key, Clock, ShieldCheck, CheckCircle2, XCircle, Loader2 } from 'lucide-react';

export default function Home() {
  const [formData, setFormData] = useState({
    host: '',
    apiKey: '',
    username: '',
    password: '',
    days: '30'
  });
  
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<{ success?: boolean; message?: string; error?: string } | null>(null);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setResult(null);

    try {
      const response = await fetch('/api/ssh/create', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData)
      });

      const data = await response.json();
      
      if (response.ok) {
        setResult({ success: true, message: data.message });
        // Reset form for user/pass
        setFormData(prev => ({ ...prev, username: '', password: '' }));
      } else {
        setResult({ success: false, error: data.error, message: data.details });
      }
    } catch (err: any) {
      setResult({ success: false, error: 'Koneksi ke server API gagal!' });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-200 py-12 px-4 sm:px-6 lg:px-8 font-sans selection:bg-cyan-500/30">
      <div className="max-w-2xl mx-auto">
        {/* Header Section */}
        <div className="text-center mb-10">
          <div className="inline-flex items-center justify-center p-3 bg-cyan-500/10 rounded-full mb-4 ring-1 ring-cyan-500/20">
            <ShieldCheck className="h-8 w-8 text-cyan-400" />
          </div>
          <h1 className="text-3xl font-bold tracking-tight text-white sm:text-4xl">
            PremDigital <span className="text-transparent bg-clip-text bg-gradient-to-r from-cyan-400 to-blue-500">VPN Panel</span>
          </h1>
          <p className="mt-3 text-slate-400">
            Create and manage premium SSH/VPN accounts directly from the web.
          </p>
        </div>

        {/* Main Card */}
        <div className="bg-slate-900 border border-slate-800 rounded-2xl shadow-xl overflow-hidden backdrop-blur-sm">
          <div className="px-6 py-8 sm:p-10">
            <form onSubmit={handleSubmit} className="space-y-6">
              
              {/* Server Config Section */}
              <div className="space-y-4">
                <h3 className="text-lg font-medium text-white flex items-center border-b border-slate-800 pb-2">
                  <Server className="h-5 w-5 mr-2 text-slate-400" />
                  Konfigurasi VPS (Admin)
                </h3>
                
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <div>
                    <label className="block text-sm font-medium text-slate-400 mb-1">IP Address VPS</label>
                    <div className="relative">
                      <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                        <Server className="h-4 w-4 text-slate-500" />
                      </div>
                      <input
                        type="text"
                        name="host"
                        required
                        value={formData.host}
                        onChange={handleChange}
                        placeholder="Contoh: 94.237.74.66"
                        className="block w-full pl-10 pr-3 py-2.5 bg-slate-950 border border-slate-800 rounded-lg text-slate-200 placeholder-slate-600 focus:ring-1 focus:ring-cyan-500 focus:border-cyan-500 transition-colors sm:text-sm"
                      />
                    </div>
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-slate-400 mb-1">API Secret (Key)</label>
                    <div className="relative">
                      <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                        <Key className="h-4 w-4 text-slate-500" />
                      </div>
                      <input
                        type="password"
                        name="apiKey"
                        required
                        value={formData.apiKey}
                        onChange={handleChange}
                        placeholder="PREMDIGITAL_RAHASIA_123"
                        className="block w-full pl-10 pr-3 py-2.5 bg-slate-950 border border-slate-800 rounded-lg text-slate-200 placeholder-slate-600 focus:ring-1 focus:ring-cyan-500 focus:border-cyan-500 transition-colors sm:text-sm"
                      />
                    </div>
                  </div>
                </div>
              </div>

              {/* Account Details Section */}
              <div className="space-y-4 pt-4">
                <h3 className="text-lg font-medium text-white flex items-center border-b border-slate-800 pb-2">
                  <UserPlus className="h-5 w-5 mr-2 text-slate-400" />
                  Detail Akun Klien
                </h3>
                
                <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  <div>
                    <label className="block text-sm font-medium text-slate-400 mb-1">Username Baru</label>
                    <div className="relative">
                      <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                        <UserPlus className="h-4 w-4 text-slate-500" />
                      </div>
                      <input
                        type="text"
                        name="username"
                        required
                        value={formData.username}
                        onChange={handleChange}
                        placeholder="vpn_client01"
                        className="block w-full pl-10 pr-3 py-2.5 bg-slate-950 border border-slate-800 rounded-lg text-slate-200 placeholder-slate-600 focus:ring-1 focus:ring-cyan-500 focus:border-cyan-500 transition-colors sm:text-sm"
                      />
                    </div>
                  </div>
                  
                  <div>
                    <label className="block text-sm font-medium text-slate-400 mb-1">Password Akun</label>
                    <div className="relative">
                      <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                        <Lock className="h-4 w-4 text-slate-500" />
                      </div>
                      <input
                        type="text"
                        name="password"
                        required
                        value={formData.password}
                        onChange={handleChange}
                        placeholder="rahasia123"
                        className="block w-full pl-10 pr-3 py-2.5 bg-slate-950 border border-slate-800 rounded-lg text-slate-200 placeholder-slate-600 focus:ring-1 focus:ring-cyan-500 focus:border-cyan-500 transition-colors sm:text-sm"
                      />
                    </div>
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-slate-400 mb-1">Masa Aktif (Expired)</label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                      <Clock className="h-4 w-4 text-slate-500" />
                    </div>
                    <select
                      name="days"
                      value={formData.days}
                      onChange={handleChange}
                      className="block w-full pl-10 pr-3 py-2.5 bg-slate-950 border border-slate-800 rounded-lg text-slate-200 focus:ring-1 focus:ring-cyan-500 focus:border-cyan-500 transition-colors sm:text-sm appearance-none"
                    >
                      <option value="1">1 Hari (Trial)</option>
                      <option value="3">3 Hari</option>
                      <option value="7">7 Hari (1 Minggu)</option>
                      <option value="30">30 Hari (1 Bulan)</option>
                      <option value="60">60 Hari (2 Bulan)</option>
                    </select>
                  </div>
                </div>
              </div>

              {/* Submit Button */}
              <div className="pt-6">
                <button
                  type="submit"
                  disabled={loading}
                  className="w-full flex justify-center items-center py-3 px-4 border border-transparent rounded-lg shadow-sm text-sm font-medium text-white bg-cyan-600 hover:bg-cyan-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-slate-900 focus:ring-cyan-500 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                >
                  {loading ? (
                    <>
                      <Loader2 className="animate-spin -ml-1 mr-2 h-5 w-5" />
                      Sedang Membuat Akun...
                    </>
                  ) : (
                    <>
                      <UserPlus className="-ml-1 mr-2 h-5 w-5" />
                      Create Premium Account
                    </>
                  )}
                </button>
              </div>
            </form>

            {/* Notification Area */}
            {result && (
              <div className={`mt-6 rounded-lg p-4 border ${result.success ? 'bg-emerald-950/50 border-emerald-900' : 'bg-rose-950/50 border-rose-900'}`}>
                <div className="flex">
                  <div className="flex-shrink-0">
                    {result.success ? (
                      <CheckCircle2 className="h-5 w-5 text-emerald-400" />
                    ) : (
                      <XCircle className="h-5 w-5 text-rose-400" />
                    )}
                  </div>
                  <div className="ml-3">
                    <h3 className={`text-sm font-medium ${result.success ? 'text-emerald-400' : 'text-rose-400'}`}>
                      {result.success ? 'Berhasil!' : 'Gagal Error!'}
                    </h3>
                    <div className={`mt-1 text-sm ${result.success ? 'text-emerald-300/80' : 'text-rose-300/80'}`}>
                      <p>{result.message || result.error}</p>
                      {result.success && formData.host && (
                        <div className="mt-3 p-3 bg-slate-950/50 rounded border border-emerald-900/50 text-xs font-mono text-emerald-200">
                          <p>Host/IP : {formData.host}</p>
                          <p>Port : 80, 109, 443</p>
                          <p>Payload WS : 80 / TLS: 443</p>
                        </div>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            )}

          </div>
        </div>
        
        <div className="mt-8 text-center text-xs text-slate-600">
          &copy; {new Date().getFullYear()} PremDigital Web Panel. All rights reserved.
        </div>
      </div>
    </div>
  );
}
