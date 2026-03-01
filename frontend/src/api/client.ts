const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? '/api';

export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';

export class ApiError extends Error {
  status: number;
  body: unknown;

  constructor(message: string, status: number, body: unknown) {
    super(message);
    this.status = status;
    this.body = body;
  }
}

function isJsonResponse(response: Response): boolean {
  const contentType = response.headers.get('content-type');
  return contentType?.includes('application/json') ?? false;
}

export async function apiRequest<TResponse>(
  path: string,
  method: HttpMethod = 'GET',
  body?: unknown,
): Promise<TResponse> {
  const response = await fetch(`${API_BASE_URL}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
    credentials: 'include',
  });

  const hasBody = response.status !== 204;
  const parsedBody = hasBody && isJsonResponse(response) ? await response.json() : null;

  if (!response.ok) {
    throw new ApiError(`API request failed: ${response.status}`, response.status, parsedBody);
  }

  return parsedBody as TResponse;
}