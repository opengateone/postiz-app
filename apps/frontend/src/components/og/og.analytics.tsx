'use client';
// OG fork: tabs of the Analytics page registered by the private OpenGate modules, after the social channels.
import { FC, ReactNode, useState } from 'react';
import clsx from 'clsx';
import { ogAnalyticsTabs } from '@og/registry.frontend';

export const OgAnalytics: FC<{ children: ReactNode }> = ({ children }) => {
  const [tab, setTab] = useState('');
  if (!ogAnalyticsTabs.length) {
    return <>{children}</>;
  }
  const Tab = ogAnalyticsTabs.find((t) => t.id === tab)?.component;
  return (
    <div className="flex flex-1 flex-col min-w-0 gap-[1px]">
      <div className="bg-newBgColorInner px-[20px] pt-[16px] pb-[12px] mobile:px-[12px]">
        <div className="inline-flex gap-[4px] bg-newBgColor rounded-full p-[4px] max-w-full overflow-x-auto">
          {[{ id: '', label: 'Mạng xã hội' }, ...ogAnalyticsTabs].map((t) => (
            <button
              key={t.id}
              type="button"
              onClick={() => setTab(t.id)}
              className={clsx(
                'px-[14px] py-[6px] rounded-full text-[13px] whitespace-nowrap',
                tab === t.id ? 'bg-btnPrimary text-white font-[600]' : 'text-textItemBlur hover:text-newTextColor'
              )}
            >
              {t.label}
            </button>
          ))}
        </div>
      </div>
      {Tab ? (
        <div className="bg-newBgColorInner flex-1 p-[20px] mobile:p-[12px] min-w-0">
          <Tab />
        </div>
      ) : (
        <div className="flex flex-1 min-w-0 gap-[1px] mobile:flex-col">{children}</div>
      )}
    </div>
  );
};
