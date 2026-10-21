'use client';
// Fallback when the private OpenGate modules (modules/og) are not checked out.
import { FC, ReactNode } from 'react';

export interface OgMenuItem {
  name: string;
  icon: ReactNode;
  path: string;
  role?: string[];
}

export const ogMenuItems: OgMenuItem[] = [];
export const ogPages: Record<string, FC> = {};
