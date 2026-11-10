import type { Copy } from '../i18n'
import { DownloadButton } from './DownloadButton'
import { Requirements } from './Requirements'

export const Closing = ({ t }: { t: Copy }) => (
  <section className="pt-(--sec) text-center" aria-labelledby="cta-h">
    <div className="wrap rv flex flex-col items-center">
      <img src="/logo.svg" alt="" width={72} height={72} className="mb-8 size-[72px]" />
      <h2 id="cta-h" className="mx-auto mb-9 max-w-[14ch]">
        {t.cta_h}
      </h2>
      <DownloadButton label={t.dl} size="lg" />
      <Requirements t={t} />
    </div>
    <div
      aria-hidden="true"
      className="mt-16 h-[15vw] overflow-hidden text-[22vw] leading-[0.85] font-extrabold tracking-[-0.06em] text-ink/5 select-none"
    >
      Voltly
    </div>
  </section>
)
