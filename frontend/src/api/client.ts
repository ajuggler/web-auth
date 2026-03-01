const API_BASE_URL = import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:3000';

export type HttpMethod = 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';

export type Auth = {
  email: string;
  password: string;
};

type RegisterErrorTag = 'EmailTaken';
type LoginErrorTag = 'EmailNotVerified' | 'InvalidAuth';
type VerifyEmailErrorTag = 'InvalidCode';
type SessionErrorTag = 'AuthRequired';

type DomainErrorTag = RegisterErrorTag | LoginErrorTag | VerifyEmailErrorTag | SessionErrorTag;

type DomainErrorBody =
  | { tag: RegisterErrorTag }
  | { tag: LoginErrorTag }
  | { tag: VerifyEmailErrorTag }
  | SessionErrorTag;

const DOMAIN_ERROR_MESSAGE: Record<DomainErrorTag, string> = {
  EmailTaken: 'Email has been taken',
  EmailNotVerified: 'Email has not been verified',
  InvalidAuth: 'Email/password is incorrect',
  InvalidCode: 'The verification code is invalid',
  AuthRequired: 'You need to login first',
};

export class ApiError extends Error {
  status: number;
  body: unknown;
  uiMessage: string;
  tag?: DomainErrorTag;

  constructor(message: string, status: number, body: unknown, uiMessage = 'Something went wrong', tag?: DomainErrorTag) {
    super(message);
    this.status = status;
    this.body = body;
    this.uiMessage = uiMessage;
    this.tag = tag;
  }
}

function isJsonResponse(response: Response): boolean {
  const contentType = response.headers.get('content-type');
  return contentType?.includes('application/json') ?? false;
}

function extractDomainErrorTag(body: unknown): DomainErrorTag | undefined {
  if (typeof body === 'string') {
    return body === 'AuthRequired' ? body : undefined;
  }

  if (body && typeof body === 'object' && 'tag' in body) {
    const tag = (body as { tag?: unknown }).tag;
    if (typeof tag === 'string' && tag in DOMAIN_ERROR_MESSAGE) {
      return tag as DomainErrorTag;
    }
  }

  return undefined;
}

export function isUnauthenticatedError(error: unknown): boolean {
  return error instanceof ApiError && error.tag === 'AuthRequired';
}

async function apiRequest<TResponse>(
  path: string,
  method: HttpMethod = 'GET',
  body?: unknown,
): Promise<TResponse> {
  const response = await fetch(`${API_BASE_URL}/api${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
    },
    body: body !== undefined ? JSON.stringify(body) : undefined,
    credentials: 'include',
  });

  const hasBody = response.status !== 204;
  const parsedBody = hasBody && isJsonResponse(response) ? ((await response.json()) as DomainErrorBody | TResponse) : null;

  if (!response.ok) {
    const tag = extractDomainErrorTag(parsedBody);
    const uiMessage = tag ? DOMAIN_ERROR_MESSAGE[tag] : 'Something went wrong';
    throw new ApiError(`API request failed: ${response.status}`, response.status, parsedBody, uiMessage, tag);
  }

  return parsedBody as TResponse;
}

export async function register(auth: Auth): Promise<void> {
  await apiRequest<null>('/auth/register', 'POST', auth);
}

export async function verifyEmail(code: string): Promise<void> {
  await apiRequest<null>('/auth/verifyEmail', 'POST', code);
}

export async function login(auth: Auth): Promise<void> {
  await apiRequest<null>('/auth/login', 'POST', auth);
}

export async function getUser(): Promise<string> {
  return apiRequest<string>('/users');
}