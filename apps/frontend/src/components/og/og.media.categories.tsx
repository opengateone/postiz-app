'use client';
// OG fork: filters of the media library registered by the private OpenGate modules (images, videos, AI videos).
import { FC } from 'react';
import clsx from 'clsx';
import { ogMediaCategories } from '@og/registry.frontend';

/** List URL of the media library for a category ('' = the Postiz GET /media). */
export const ogMediaPath = (category: string, params: URLSearchParams) => {
  const path = ogMediaCategories.find((c) => c.id === category)?.path;
  return path ? `${path}${path.includes('?') ? '&' : '?'}${params.toString()}` : `/media?${params.toString()}`;
};

export const OgMediaCategories: FC<{ value: string; onChange: (id: string) => void }> = ({ value, onChange }) => {
  if (!ogMediaCategories.length) {
    return null;
  }
  return (
    <div className="flex gap-[4px] bg-newBgColor rounded-[8px] p-[4px] mobile:basis-full mobile:overflow-x-auto">
      {[{ id: '', label: 'Tất cả' }, ...ogMediaCategories].map((c) => (
        <button
          key={c.id}
          type="button"
          onClick={() => onChange(c.id)}
          className={clsx(
            'h-[36px] px-[14px] rounded-[6px] text-[14px] whitespace-nowrap',
            value === c.id ? 'bg-[#612BD3] text-white font-[600]' : 'text-textItemBlur hover:text-newTextColor'
          )}
        >
          {c.label}
        </button>
      ))}
    </div>
  );
};
