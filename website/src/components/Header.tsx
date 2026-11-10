import type { Copy } from '../i18n'
import { DownloadButton } from './DownloadButton'

export const Header = ({ t }: { t: Copy }) => (
  <header className="enter [--enter-delay:50ms] sticky top-3 z-20 mx-auto mt-3 flex w-[calc(100%-24px)] max-w-[1040px] items-center gap-4 rounded-full border border-line bg-[color-mix(in_srgb,white_72%,transparent)] px-4 py-2 shadow-pill backdrop-blur-[22px] backdrop-saturate-[180%] max-[479px]:gap-2">
    <a href="#top" className="flex items-center gap-2.5 text-lg font-extrabold tracking-[-0.03em] no-underline" aria-label="Voltly">
      <img src="/logo.svg" alt="" width={32} height={32} className="size-8" />
      Voltly
    </a>
    <nav className="ms-auto flex gap-1.5 max-[759px]:hidden">
      <a href="#features" className="rounded-full px-4 py-2.5 text-[15px] text-ink-2 no-underline transition-colors hover:bg-line hover:text-ink">
        {t.nav_features}
      </a>
      <a href="#how" className="rounded-full px-4 py-2.5 text-[15px] text-ink-2 no-underline transition-colors hover:bg-line hover:text-ink">
        {t.nav_how}
      </a>
      <a href="#faq" className="rounded-full px-4 py-2.5 text-[15px] text-ink-2 no-underline transition-colors hover:bg-line hover:text-ink">
        {t.nav_faq}
      </a>
    </nav>
    <div className="ms-auto min-[760px]:ms-0">
      <DownloadButton label={t.dl} size="sm" />
    </div>
  </header>
)
