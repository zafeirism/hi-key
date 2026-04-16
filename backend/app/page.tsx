import { notFound } from 'next/navigation';
import Playground from './playground';

export default function Page() {
  if (process.env.ENABLE_PLAYGROUND !== 'true') {
    notFound();
  }

  return <Playground />;
}
