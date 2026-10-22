'use client';
// Fallback when the private OpenGate modules (modules/og) are not checked out.
import { FC, ReactNode } from 'react';

export interface OgMenuItem {
  name: string;
  icon: ReactNode;
  path: string;
  role?: string[];
}

export interface OgMediaCategory {
  id: string;
  label: string;
  path: string;
}

export interface OgAnalyticsTab {
  id: string;
  label: string;
  component: FC;
}

export const ogMenuItems: OgMenuItem[] = [];
export const ogPages: Record<string, FC> = {};
export const ogMediaCategories: OgMediaCategory[] = [];
export const ogAnalyticsTabs: OgAnalyticsTab[] = [];
