// OG fork: pages of the private OpenGate modules (modules/og/registry.frontend.tsx).
export const dynamic = 'force-dynamic';
import { OgModulePage } from '@gitroom/frontend/components/og/og.module.page';

export default async function Page({ params }: { params: Promise<{ slug: string[] }> }) {
  const { slug } = await params;
  return <OgModulePage slug={slug.join('/')} />;
}
