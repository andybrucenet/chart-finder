const API_BASE = process.env.EXPO_PUBLIC_API_BASE_URL ?? '';

export async function addAsync(x: number, y: number): Promise<number> {
  if (!API_BASE) {
    throw new Error('API base URL missing. Set EXPO_PUBLIC_API_BASE_URL before building.');
  }

  const url = `${API_BASE.replace(/\/+$/, '')}/calculator/v1/add/${x}/${y}`;
  const response = await fetch(url, { method: 'GET' });

  if (!response.ok) {
    const detail = await response.text();
    throw new Error(`Request failed: ${response.status} ${response.statusText}\n${detail}`);
  }

  const payload = await response.json();
  if (typeof payload?.result !== 'number') {
    throw new Error('Calculator payload missing numeric `result` field.');
  }

  return payload.result;
}
