"use client";

import React, { useState } from "react";
import { Moon, Menu, User, Lock, AlertTriangle, X, Shield, Zap } from "lucide-react";
import { motion, AnimatePresence } from "framer-motion";

export default function PremdigitalTunnelApp() {
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [billingTier, setBillingTier] = useState("free");
  
  const [isCreating, setIsCreating] = useState(false);
  const [creationStep, setCreationStep] = useState(0); 
  
  const handleCreate = (e: React.FormEvent) => {
    e.preventDefault();
    setIsCreating(true);
    setCreationStep(1);
    
    // Simulate process
    setTimeout(() => setCreationStep(2), 1500);
    setTimeout(() => setCreationStep(3), 3000);
    setTimeout(() => setCreationStep(4), 4500); 
  };
  
  const closeError = () => {
    setIsCreating(false);
    setCreationStep(0);
  };

  return (
    <div className="min-h-screen bg-[#0B0F19] text-slate-200 font-sans selection:bg-purple-500/30">
      {/* Navbar */}
      <nav className="flex items-center justify-between px-4 py-3 bg-[#111827] border-b border-slate-800/60 sticky top-0 z-10">
        <div className="flex items-center gap-2">
          <div className="w-8 h-8 rounded-lg bg-indigo-600 flex items-center justify-center shadow-lg shadow-indigo-500/20 overflow-hidden">
            <img src="/banner.jpg" alt="Logo" className="w-full h-full object-cover" onError={(e) => { e.currentTarget.style.display = 'none'; e.currentTarget.parentElement?.querySelector('svg')?.classList.remove('hidden'); }} />
            <Shield className="w-5 h-5 text-white hidden" />
          </div>
          <span className="text-lg font-bold text-white tracking-tight">PremDigital Tunnel</span>
        </div>
        <div className="flex items-center gap-3">
          <button className="p-2 rounded-full hover:bg-slate-800 text-slate-400 transition-colors">
            <Moon className="w-5 h-5" />
          </button>
          <button className="p-2 rounded-full hover:bg-slate-800 text-slate-400 transition-colors">
            <Menu className="w-5 h-5" />
          </button>
        </div>
      </nav>

      {/* Main Content */}
      <main className="max-w-md mx-auto p-4 pt-6 pb-24">
        <div className="mb-6 rounded-2xl overflow-hidden shadow-2xl shadow-indigo-500/10 border border-slate-800">
          <img src="/banner.jpg" alt="PremDigital Tunnel Banner" className="w-full h-auto object-cover aspect-[21/9]" />
        </div>

        <div className="mb-8">
          <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-indigo-500/10 text-indigo-400 text-sm font-medium mb-4 border border-indigo-500/20">
            <span className="w-2 h-2 rounded-full bg-indigo-500 animate-pulse"></span>
            Free Ssh Tunnel Server Singapore
          </div>
          <h1 className="text-2xl font-bold text-white mb-2 leading-tight">Create Ssh Tunnel Account Singapore SG1 SSH</h1>
          <p className="text-slate-400 text-sm">
            Get instant access to a secure and unrestricted internet experience with our high-performance Ssh Tunnel server located in Singapore.
          </p>
        </div>

        <form onSubmit={handleCreate} className="space-y-5">
          {/* Username */}
          <div className="space-y-1.5">
            <label className="text-sm font-medium text-slate-300 ml-1">Username</label>
            <div className="relative">
              <input
                type="text"
                required
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                placeholder="Enter letters and numbers (5-12 characters)"
                className="w-full bg-[#1A2234] border border-slate-700 rounded-xl py-3.5 pl-4 pr-10 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/50 focus:border-indigo-500 transition-all"
                minLength={5}
                maxLength={12}
              />
              <User className="absolute right-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-500" />
            </div>
          </div>

          {/* Password */}
          <div className="space-y-1.5">
            <label className="text-sm font-medium text-slate-300 ml-1">Password</label>
            <div className="relative">
              <input
                type="password"
                required
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Minimum 5 characters for security"
                className="w-full bg-[#1A2234] border border-slate-700 rounded-xl py-3.5 pl-4 pr-10 text-white placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-indigo-500/50 focus:border-indigo-500 transition-all"
                minLength={5}
              />
              <Lock className="absolute right-4 top-1/2 -translate-y-1/2 w-5 h-5 text-slate-500" />
            </div>
          </div>

          {/* Billing Tier */}
          <div className="space-y-2 pt-2">
            <label className="text-sm font-medium text-slate-300 ml-1">Billing Tier</label>
            
            <div className="space-y-2.5">
              {/* Free Tier */}
              <label className={`block relative border rounded-xl p-4 cursor-pointer transition-all duration-200 ${billingTier === 'free' ? 'bg-indigo-900/20 border-indigo-500' : 'bg-[#1A2234] border-slate-700 hover:border-slate-600'}`}>
                <input type="radio" name="tier" value="free" checked={billingTier === 'free'} onChange={() => setBillingTier('free')} className="sr-only" />
                <div className="flex justify-between items-center">
                  <div>
                    <div className="font-semibold text-white">Free</div>
                    <div className="text-xs text-slate-400 mt-0.5">Limited access</div>
                  </div>
                  <div className="font-medium text-white">Rp 0</div>
                </div>
              </label>

              {/* 3 Days Premium */}
              <label className={`block relative border rounded-xl p-4 cursor-pointer transition-all duration-200 ${billingTier === '3days' ? 'bg-indigo-900/20 border-indigo-500' : 'bg-[#1A2234] border-slate-700 hover:border-slate-600'}`}>
                <input type="radio" name="tier" value="3days" checked={billingTier === '3days'} onChange={() => setBillingTier('3days')} className="sr-only" />
                <div className="flex justify-between items-center">
                  <div>
                    <div className="font-semibold text-white">3 Days Premium</div>
                    <div className="text-xs text-slate-400 mt-0.5">Short term access</div>
                  </div>
                  <div className="text-right">
                    <div className="flex items-center gap-2 justify-end mb-0.5">
                      <span className="text-xs text-slate-500 line-through">Rp 1.500</span>
                      <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-emerald-500/20 text-emerald-400">-50%</span>
                    </div>
                    <div className="font-medium text-white">Rp 750</div>
                  </div>
                </div>
              </label>

              {/* 7 Days Premium */}
              <label className={`block relative border rounded-xl p-4 cursor-pointer transition-all duration-200 ${billingTier === '7days' ? 'bg-indigo-900/20 border-indigo-500' : 'bg-[#1A2234] border-slate-700 hover:border-slate-600'}`}>
                <input type="radio" name="tier" value="7days" checked={billingTier === '7days'} onChange={() => setBillingTier('7days')} className="sr-only" />
                <div className="flex justify-between items-center">
                  <div>
                    <div className="font-semibold text-white">7 Days Premium</div>
                    <div className="text-xs text-slate-400 mt-0.5">Best for weekly</div>
                  </div>
                  <div className="text-right">
                    <div className="flex items-center gap-2 justify-end mb-0.5">
                      <span className="text-xs text-slate-500 line-through">Rp 3.300</span>
                      <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-emerald-500/20 text-emerald-400">-50%</span>
                    </div>
                    <div className="font-medium text-white">Rp 1.650</div>
                  </div>
                </div>
              </label>

              {/* 30 Days Premium */}
              <label className={`block relative border rounded-xl p-4 cursor-pointer transition-all duration-200 ${billingTier === '30days' ? 'bg-indigo-900/20 border-indigo-500' : 'bg-[#1A2234] border-slate-700 hover:border-slate-600'}`}>
                <input type="radio" name="tier" value="30days" checked={billingTier === '30days'} onChange={() => setBillingTier('30days')} className="sr-only" />
                <div className="flex justify-between items-center">
                  <div>
                    <div className="font-semibold text-white">30 Days Premium</div>
                    <div className="text-xs text-slate-400 mt-0.5">Full month access</div>
                  </div>
                  <div className="text-right">
                    <div className="flex items-center gap-2 justify-end mb-0.5">
                      <span className="text-xs text-slate-500 line-through">Rp 12.500</span>
                      <span className="text-[10px] font-bold px-1.5 py-0.5 rounded bg-emerald-500/20 text-emerald-400">-50%</span>
                    </div>
                    <div className="font-medium text-white">Rp 6.250</div>
                  </div>
                </div>
              </label>
            </div>
          </div>

          <div className="pt-4 pb-8">
            <button
              type="submit"
              disabled={isCreating}
              className="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-3.5 rounded-xl transition-all shadow-lg shadow-indigo-600/20 disabled:opacity-70"
            >
              Create Ssh Tunnel Account
            </button>
          </div>
        </form>

        {/* Promo Section */}
        <div className="mt-8 border-t border-slate-800 pt-8">
          <div className="bg-gradient-to-br from-indigo-900/40 to-[#1A2234] border border-indigo-500/20 rounded-2xl p-6">
            <div className="w-10 h-10 rounded-full bg-indigo-500/20 flex items-center justify-center mb-4">
              <Zap className="w-5 h-5 text-indigo-400" />
            </div>
            <h3 className="text-lg font-bold text-white mb-2">Unlock Premium Features</h3>
            <p className="text-slate-400 text-sm leading-relaxed mb-4">
              Get the most out of your Ssh Tunnel experience with our premium subscription plans. <span className="text-indigo-400 font-medium cursor-pointer">Upgrade today</span> and enjoy unlimited access to all features.
            </p>
          </div>
        </div>
      </main>

      {/* Loading & Error Overlay */}
      <AnimatePresence>
        {isCreating && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            className="fixed inset-0 z-50 bg-[#0B0F19]/95 backdrop-blur-sm flex flex-col items-center justify-center p-6"
          >
            {creationStep < 4 ? (
              <div className="w-full max-w-sm flex flex-col items-center">
                <div className="relative w-20 h-20 mb-8">
                  <div className="absolute inset-0 rounded-full border-4 border-indigo-900/50"></div>
                  <motion.div
                    className="absolute inset-0 rounded-full border-4 border-indigo-500 border-t-transparent"
                    animate={{ rotate: 360 }}
                    transition={{ duration: 1.5, repeat: Infinity, ease: "linear" }}
                  />
                  <div className="absolute inset-0 flex items-center justify-center">
                    <div className="w-10 h-10 rounded-full bg-indigo-500/20 animate-pulse"></div>
                  </div>
                </div>
                
                <h2 className="text-2xl font-bold text-white mb-2 text-center">Creating Your Account</h2>
                <p className="text-slate-400 text-center text-sm mb-8">Please wait while we process your request...</p>
                
                <div className="w-full space-y-4 max-w-[250px]">
                  <div className="flex items-center gap-3">
                    <div className={`w-2.5 h-2.5 rounded-full ${creationStep >= 1 ? 'bg-emerald-500 shadow-[0_0_8px_rgba(16,185,129,0.5)]' : 'bg-slate-700'}`}></div>
                    <span className={`text-sm ${creationStep >= 1 ? 'text-white' : 'text-slate-500'}`}>Validating credentials</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className={`w-2.5 h-2.5 rounded-full ${creationStep >= 2 ? 'bg-amber-400 shadow-[0_0_8px_rgba(251,191,36,0.5)]' : 'bg-slate-700'}`}></div>
                    <span className={`text-sm ${creationStep >= 2 ? 'text-white' : 'text-slate-500'}`}>Creating account on server</span>
                  </div>
                  <div className="flex items-center gap-3">
                    <div className={`w-2.5 h-2.5 rounded-full ${creationStep >= 3 ? 'bg-indigo-400 shadow-[0_0_8px_rgba(99,102,241,0.5)]' : 'bg-slate-700'}`}></div>
                    <span className={`text-sm ${creationStep >= 3 ? 'text-white' : 'text-slate-500'}`}>Configuring connection</span>
                  </div>
                </div>
              </div>
            ) : (
              <motion.div 
                initial={{ scale: 0.9, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                className="w-full max-w-sm bg-[#1A2234] border border-rose-500/30 rounded-2xl overflow-hidden shadow-2xl"
              >
                <div className="bg-rose-500/10 p-6 flex flex-col items-center border-b border-rose-500/20">
                  <div className="w-16 h-16 rounded-full bg-rose-500/20 flex items-center justify-center mb-4">
                    <AlertTriangle className="w-8 h-8 text-rose-500" />
                  </div>
                  <h3 className="text-xl font-bold text-white mb-1">Error Details</h3>
                </div>
                <div className="p-6">
                  <p className="text-slate-300 text-sm text-center leading-relaxed">
                    Cannot connect to sg1.premdigitaltunnel.my.id:22.<br />
                    Connection timed out.
                  </p>
                  <button
                    onClick={closeError}
                    className="mt-6 w-full bg-[#0B0F19] hover:bg-slate-800 border border-slate-700 text-white font-medium py-3 rounded-xl transition-colors"
                  >
                    Close
                  </button>
                </div>
              </motion.div>
            )}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Toast Error Simulation */}
      <AnimatePresence>
        {creationStep === 4 && (
          <motion.div
            initial={{ y: 50, opacity: 0 }}
            animate={{ y: 0, opacity: 1 }}
            exit={{ y: 50, opacity: 0 }}
            className="fixed bottom-6 left-4 right-4 md:left-auto md:right-6 md:w-96 bg-rose-500 text-white rounded-xl shadow-xl shadow-rose-500/20 overflow-hidden z-[60]"
          >
            <div className="px-4 py-3 flex items-center gap-3">
              <AlertTriangle className="w-5 h-5 flex-shrink-0" />
              <div className="flex-1">
                <div className="font-bold text-sm">Error!</div>
                <div className="text-xs text-rose-100">Upps! Something wrong</div>
              </div>
              <button onClick={closeError} className="p-1 hover:bg-rose-600 rounded-lg transition-colors">
                <X className="w-4 h-4" />
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
