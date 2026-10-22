export const dynamic = 'force-dynamic';
import { Metadata } from 'next';
import { PlatformAnalytics } from '@gitroom/frontend/components/platform-analytics/platform.analytics';
import { isGeneralServerSide } from '@gitroom/helpers/utils/is.general.server.side';
import { OgAnalytics } from '@gitroom/frontend/components/og/og.analytics'; // OG fork
export const metadata: Metadata = {
  title: `${isGeneralServerSide() ? 'Postiz' : 'Gitroom'} Analytics`,
  description: '',
};
export default async function Index() {
  return (
    // OG fork: OpenGate tabs (Content Automation) next to the social channels
    <OgAnalytics>
      <PlatformAnalytics />
    </OgAnalytics>
  );
}
