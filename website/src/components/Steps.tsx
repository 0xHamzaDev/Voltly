import type { Copy } from '../i18n'

export const Steps = ({ t }: { t: Copy }) => (
  <section id="how" className="pt-(--sec)" aria-labelledby="how-h">
    <div className="wrap">
      <h2 id="how-h" className="rv">
        {t.how_h}
      </h2>
      <div className="mt-14 grid gap-4 min-[900px]:grid-cols-3">
        {[
          [t.s1_h, t.s1_p],
          [t.s2_h, t.s2_p],
          [t.s3_h, t.s3_p],
        ].map(([title, body], i) => (
          <article key={title} className="rv rounded-[28px] border border-line bg-surface p-7 shadow-card">
            <div className="mb-7 grid size-11 place-items-center rounded-full border-2 border-accent font-mono text-xl font-bold text-accent">
              {i + 1}
            </div>
            <h3>{title}</h3>
            <p className="mt-2.5 text-ink-2">{body}</p>
          </article>
        ))}
      </div>
    </div>
  </section>
)
