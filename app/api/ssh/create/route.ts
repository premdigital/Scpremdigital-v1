import { NextResponse } from 'next/server';

export async function POST(req: Request): Promise<NextResponse> {
  try {
    const { host, apiKey, username, password, days } = await req.json();

    if (!host || !apiKey || !username || !password || !days) {
      return NextResponse.json({ error: 'Harap lengkapi semua data!' }, { status: 400 });
    }

    const apiUrl = `http://${host}:5000/api/create`;

    const response = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        api_key: apiKey,
        username,
        password,
        days
      })
    });

    const data = await response.json().catch(() => null);

    if (!response.ok) {
      if (response.status === 401) {
        return NextResponse.json({ error: 'Unauthorized: API Key salah!' }, { status: 401 });
      }
      return NextResponse.json({ 
        error: data?.error || 'Gagal terhubung ke API VPS (Port 5000)' 
      }, { status: response.status });
    }

    return NextResponse.json({ 
      success: true, 
      message: data?.message || `Akun ${username} berhasil dibuat untuk ${days} hari!` 
    });

  } catch (error: any) {
    return NextResponse.json({ error: 'Internal Server Error atau API VPS Mati', details: error.message }, { status: 500 });
  }
}
