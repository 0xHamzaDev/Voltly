import type { Dict } from '../i18n'

export const Why = ({ t }: { t: Dict }) => (
  <section className="rv pt-(--sec)" aria-labelledby="why-h">
    <div className="wrap">
      <h2 className="sr-only" id="why-h">
        {t.why_h}
      </h2>
      <p className="max-w-[26em] text-[clamp(22px,3vw,30px)] leading-[1.4] font-semibold tracking-[-0.02em] text-ink-2 rtl:leading-[1.75]">
        <span>{t.w_a}</span>
        <em className="text-ink not-italic">{t.w_k1}</em>
        <span>{t.w_b}</span>
        <em className="text-ink not-italic">{t.w_k2}</em>
        <span>{t.w_c}</span>
      </p>
    </div>
  </section>
)
