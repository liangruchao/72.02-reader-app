/**
 * User entity
 */
export interface User {
  id: string;
  platformId?: string;
  email: string;
  username?: string;
  displayName?: string;
  avatarUrl?: string;
  bio?: string;
  isActive: boolean;
  roles?: Role[];
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Role entity
 */
export interface Role {
  id: string;
  platformId?: string;
  name: string;
  description?: string;
  permissions?: Permission[];
  isSystemRole: boolean;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Permission entity
 */
export interface Permission {
  id: string;
  name: string;
  resource: string;
  action: string;
  description?: string;
}

/**
 * Platform entity (B2B2C)
 */
export interface Platform {
  id: string;
  name: string;
  displayName: string;
  description?: string;
  logoUrl?: string;
  website?: string;
  isActive: boolean;
  licenseId?: string;
  userLimit?: number;
  userCount: number;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * License entity
 */
export interface License {
  id: string;
  platformId: string;
  key: string;
  type: LicenseType;
  tier: LicenseTier;
  maxUsers: number;
  maxArticles: number;
  maxStorage: number;
  features: string[];
  startDate: Date;
  endDate: Date;
  isActive: boolean;
  autoRenew: boolean;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * License type enum
 */
export enum LicenseType {
  TRIAL = 'TRIAL',
  SUBSCRIPTION = 'SUBSCRIPTION',
  LIFETIME = 'LIFETIME',
}

/**
 * License tier enum
 */
export enum LicenseTier {
  FREE = 'FREE',
  BASIC = 'BASIC',
  PRO = 'PRO',
  ENTERPRISE = 'ENTERPRISE',
}

/**
 * Subscription entity
 */
export interface Subscription {
  id: string;
  platformId: string;
  licenseId: string;
  status: SubscriptionStatus;
  amount: number;
  currency: string;
  billingCycle: BillingCycle;
  currentPeriodStart: Date;
  currentPeriodEnd: Date;
  nextBillingDate?: Date;
  cancelAtPeriodEnd: boolean;
  canceledAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

/**
 * Subscription status enum
 */
export enum SubscriptionStatus {
  ACTIVE = 'ACTIVE',
  PAST_DUE = 'PAST_DUE',
  CANCELED = 'CANCELED',
  INCOMPLETE = 'INCOMPLETE',
  TRIALING = 'TRIALING',
}

/**
 * Billing cycle enum
 */
export enum BillingCycle {
  MONTHLY = 'MONTHLY',
  QUARTERLY = 'QUARTERLY',
  YEARLY = 'YEARLY',
}
