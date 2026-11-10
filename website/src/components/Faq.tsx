import { Plus } from 'lucide-react'
import type { Copy } from '../i18n'

export const Faq = ({ t }: { t: Copy }) => (
  <section id="faq" className="pt-(--sec)" aria-labelledby="faq-h">
    <div className="wrap max-w-[860px]">
      <h2 id="faq-h" className="rv">
        {t.faq_h}
      </h2>
      <div className="rv mt-12">
        {[
          [t.q1, t.a1],
          [t.q2, t.a2],
          [t.q3, t.a3],
          [t.q4, t.a4],
          [t.q5, t.a5],
        ].map(([q, a], i) => (
          <details key={q} open={i === 0} className={`group border-b border-line ${i === 0 ? 'border-t' : ''}`}>
            <summary className="flex cursor-pointer list-none items-center justify-between gap-6 py-6 text-[clamp(18px,1.8vw,21px)] font-semibold [&::-webkit-details-marker]:hidden">
              {q}
              <Plus className="size-7 flex-none text-accent transition-transform duration-300 group-open:rotate-45" aria-hidden="true" />
            </summary>
            <p className="max-w-[38em] pb-6 text-ink-2">{a}</p>
          </details>
        ))}
      </div>
    </div>
  </section>
)
