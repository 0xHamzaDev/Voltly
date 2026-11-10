import type { Copy } from '../i18n'
import { DownloadButton } from './DownloadButton'
import { Requirements } from './Requirements'

export const Hero = ({ t }: { t: Copy }) => (
  <div className="pt-[72px] text-center">
    <div className="wrap">
      <h1 className="enter [--enter-delay:150ms] mx-auto max-w-[15ch]">
        <span className="block">{t.h1a}</span>
        <span>{t.h1b}</span>
        <span className="hl">{t.h1m}</span>
        <span>{t.h1c}</span>
      </h1>
      <p className="enter [--enter-delay:300ms] mx-auto mt-7 mb-9 max-w-[36em] text-[clamp(18px,1.7vw,21px)] leading-normal text-ink-2">
        {t.hero_p}
      </p>
      <div className="enter [--enter-delay:500ms] flex flex-col items-center">
        <DownloadButton label={t.dl} size="lg" />
        <Requirements t={t} />
      </div>
    </div>
  </div>
)
