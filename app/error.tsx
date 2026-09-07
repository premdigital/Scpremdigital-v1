'use client';

import { useEffect } from 'react';

export default function Error({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  useEffect(() => {
    console.error(error);
  }, [error]);

  return (
    <div className="min-h-screen bg-slate-950 flex flex-col items-center justify-center text-white px-4">
      <h2 className="text-2xl font-bold mb-2">Terjadi Kesalahan</h2>
      <p className="text-slate-400 mb-6 text-sm">
        {error.message || 'Gagal memuat komponen aplikasi.'}
      </p>
      <button
        onClick={() => reset()}
        className="px-4 py-2 bg-cyan-600 hover:bg-cyan-500 rounded-lg text-sm font-medium transition"
      >
        Coba Lagi
      </button>
    </div>
  );
}
