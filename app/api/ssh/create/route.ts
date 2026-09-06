import { NextResponse } from 'next/server';
import { Client } from 'ssh2';

export async function POST(req: Request): Promise<NextResponse> {
  try {
    const { host, rootPassword, username, password, days } = await req.json();

    if (!host || !rootPassword || !username || !password || !days) {
      return NextResponse.json({ error: 'Harap lengkapi semua data!' }, { status: 400 });
    }

    return await new Promise<NextResponse>((resolve) => {
      const conn = new Client();
      
      conn.on('ready', () => {
        // Perintah untuk membuat user SSH/VPN dengan shell /bin/false dan set expired date
        const command = `useradd -e $(date -d "+${days} days" +"%Y-%m-%d") -s /bin/false -M ${username} && echo "${username}:${password}" | chpasswd`;

        conn.exec(command, (err, stream) => {
          if (err) {
            conn.end();
            resolve(NextResponse.json({ error: err.message }, { status: 500 }));
            return;
          }
          
          let output = '';
          let errorOutput = '';

          stream.on('close', (code: any) => {
            conn.end();
            if (code !== 0) {
              resolve(NextResponse.json({ 
                error: 'Gagal membuat akun. Mungkin username sudah ada.', 
                details: errorOutput 
              }, { status: 500 }));
            } else {
              resolve(NextResponse.json({ 
                success: true, 
                message: `Akun ${username} berhasil dibuat untuk ${days} hari!` 
              }));
            }
          }).on('data', (data: any) => {
            output += data;
          }).stderr.on('data', (data: any) => {
            errorOutput += data;
          });
        });
      }).on('error', (err) => {
        resolve(NextResponse.json({ 
          error: 'Gagal terhubung ke VPS (SSH Timeout/Auth Failed)', 
          details: err.message 
        }, { status: 500 }));
      }).connect({
        host: host,
        port: 22,
        username: 'root',
        password: rootPassword,
        readyTimeout: 10000 // 10 seconds timeout
      });
    });

  } catch (error: any) {
    return NextResponse.json({ error: 'Internal Server Error', details: error.message }, { status: 500 });
  }
}
