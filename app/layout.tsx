import type {Metadata} from 'next';
import './globals.css'; // Global styles

export const metadata: Metadata = {
  title: 'PremdigitalTunnel_bot',
  description: 'Free Ssh Tunnel Server Singapore - Get instant access to a secure and unrestricted internet experience.',
  openGraph: {
    title: 'PremdigitalTunnel_bot',
    description: 'Free Ssh Tunnel Server Singapore',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: 'PremdigitalTunnel_bot',
    description: 'Free Ssh Tunnel Server Singapore',
  },
};

export default function RootLayout({children}: {children: React.ReactNode}) {
  return (
    <html lang="en">
      <body suppressHydrationWarning>{children}</body>
    </html>
  );
}
