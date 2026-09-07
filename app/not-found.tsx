import Link from 'next/link';

export default function NotFound() {
  return (
    <div className="min-h-screen bg-slate-950 flex flex-col items-center justify-center text-white px-4">
      <h1 className="text-4xl font-bold mb-2">404</h1>
      <p className="text-slate-400 mb-6">Halaman tidak ditemukan</p>
      <Link
        href="/"
        className="px-4 py-2 bg-cyan-600 hover:bg-cyan-500 rounded-lg text-sm font-medium transition"
      >
        Kembali ke Beranda
      </Link>
    </div>
  );
}
