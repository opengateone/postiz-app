'use client';
// OG fork: renders a page registered by the private OpenGate modules.
import { FC, Suspense } from 'react';
import { ogPages } from '@og/registry.frontend';

export const OgModulePage: FC<{ slug: string }> = ({ slug }) => {
  const Page = ogPages[slug];
  if (!Page) {
    return <div className="bg-newBgColorInner flex flex-1 items-center justify-center p-[40px] text-textItemBlur">Không tìm thấy module “{slug}”.</div>;
  }
  return (
    <Suspense fallback={null}>
      <Page />
    </Suspense>
  );
};
