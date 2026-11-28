// Сервис аутентификации и сессий (F02, UC-01, REQ-FUNC-001, REQ-SEC-003).
import { createHmac, randomBytes, scryptSync, timingSafeEqual } from 'node:crypto';
import type { User } from '../../domain/models.ts';
import { applyLoginAttempt, can, sessionExpired, SESSION_TTL_MS } from './authPolicy.ts';
import type { Role } from './authPolicy.ts';

export interface PasswordHasher {
  hash(password: string): string;
  verify(password: string, storedHash: string): boolean;
}

export class ScryptPasswordHasher implements PasswordHasher {
  hash(password: string): string {
    const salt = randomBytes(16).toString('hex');
    const derived = scryptSync(password, salt, 32).toString('hex');
    return `scrypt:${salt}:${derived}`;
  }

  verify(password: string, storedHash: string): boolean {
    const parts = storedHash.split(':');
    if (parts.length !== 3 || parts[0] !== 'scrypt') return false;
    const [, salt, hex] = parts;
    if (!/^[0-9a-f]{64}$/i.test(hex)) return false;
    const expected = Buffer.from(hex, 'hex');
    const actual = scryptSync(password, salt, 32);
    return timingSafeEqual(actual, expected);
  }
}

export type SessionClaims = {
  sub: string;
  login: string;
  role: Role;
  iat: number;
  exp: number;
};

export interface UserRepository {
  findByLogin(login: string): Promise<User | null>;
  saveLoginState(userId: string, failedAttempts: number, lockedUntil: number | null): Promise<void>;
}

export class TokenService {
  private readonly secret: string;
  constructor(secret: string) {
    this.secret = secret;
  }

  issue(user: User, now: number): string {
    const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url');
    const claims: SessionClaims = {
      sub: user.getId(),
      login: user.getLogin(),
      role: user.getRole(),
      iat: now,
      exp: now + SESSION_TTL_MS,
    };
    const payload = Buffer.from(JSON.stringify(claims)).toString('base64url');
    const sig = createHmac('sha256', this.secret).update(`${header}.${payload}`).digest('base64url');
    return `${header}.${payload}.${sig}`;
  }

  verify(token: string, now: number): SessionClaims | null {
    const parts = token.split('.');
    if (parts.length !== 3) return null;
    const [header, payload, sig] = parts;
    const expected = createHmac('sha256', this.secret).update(`${header}.${payload}`).digest();
    let actual: Buffer;
    try {
      actual = Buffer.from(sig, 'base64url');
    } catch {
      return null;
    }
    if (actual.length !== expected.length || !timingSafeEqual(actual, expected)) return null;
    try {
      const claims = JSON.parse(Buffer.from(payload, 'base64url').toString('utf8')) as SessionClaims;
      if (sessionExpired(claims.iat, now)) return null;
      return claims;
    } catch {
      return null;
    }
  }
}

export type LoginResult =
  | { status: 200; token: string; role: Role; expiresAt: number }
  | { status: 401; code: 'BAD_CREDENTIALS' }
  | { status: 423; code: 'LOCKED'; lockedUntil: number };

export class AuthService {
  private readonly users: UserRepository;
  private readonly hasher: PasswordHasher;
  private readonly tokens: TokenService;

  constructor(users: UserRepository, hasher: PasswordHasher, tokens: TokenService) {
    this.users = users;
    this.hasher = hasher;
    this.tokens = tokens;
  }

  async login(login: string, password: string, now: number): Promise<LoginResult> {
    const user = await this.users.findByLogin(login);
    if (!user) return { status: 401, code: 'BAD_CREDENTIALS' };

    const ok = this.hasher.verify(password, user.getPasswordHash());
    const { state, result } = applyLoginAttempt(user.getLoginState(), ok, now);
    await this.users.saveLoginState(user.getId(), state.failedAttempts, state.lockedUntil);

    if (result === 'LOCKED') {
      return { status: 423, code: 'LOCKED', lockedUntil: state.lockedUntil! };
    }
    if (result === 'BAD_CREDENTIALS') {
      return { status: 401, code: 'BAD_CREDENTIALS' };
    }
    const token = this.tokens.issue(user, now);
    return { status: 200, token, role: user.getRole(), expiresAt: now + SESSION_TTL_MS };
  }

  authorize(token: string | undefined, permission: string, now: number): { ok: true; claims: SessionClaims } | { ok: false; status: 401 | 403; code: string } {
    if (!token) return { ok: false, status: 401, code: 'UNAUTHORIZED' };
    const claims = this.tokens.verify(token, now);
    if (!claims) return { ok: false, status: 401, code: 'INVALID_SESSION' };
    if (!can(claims.role, permission)) return { ok: false, status: 403, code: 'FORBIDDEN' };
    return { ok: true, claims };
  }
}
