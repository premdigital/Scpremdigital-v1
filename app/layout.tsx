import type {Metadata} from 'next';
import './globals.css'; // Global styles

export const metadata: Metadata = {
  title: 'TypeScript Tunneling Service',
  description: 'A structured, scalable tunneling service written in TypeScript.',
  openGraph: {
    title: 'TypeScript Tunneling Service',
    description: 'A structured, scalable tunneling service written in TypeScript.',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'TypeScript Tunneling Service',
    description: 'A structured, scalable tunneling service written in TypeScript.',
  },
};

export default function RootLayout({children}: {children: React.ReactNode}) {
  return (
    <html lang="en">
      <body suppressHydrationWarning>{children}</body>
    </html>
  );
}
