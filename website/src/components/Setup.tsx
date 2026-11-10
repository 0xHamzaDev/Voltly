import type { Copy } from '../i18n'

export const Setup = ({ t }: { t: Copy }) => (
  <section className="pt-(--sec)" aria-labelledby="setup-h">
    <div className="wrap grid items-center gap-10 min-[900px]:grid-cols-2 min-[900px]:gap-14">
      <div className="rv">
        <h2 id="setup-h">{t.setup_h}</h2>
        <p className="mt-[18px] max-w-[34em] text-[clamp(18px,1.7vw,21px)] leading-normal text-ink-2">{t.setup_p}</p>
      </div>
      <ul className="rv rounded-[28px] border border-line bg-surface px-6 py-4 shadow-card">
        {[
          [t.pop_limit, '80%'],
          [t.pop_sailing, t.v_on],
          [t.pop_heat, t.v_on],
          [t.st_login, t.v_on],
        ].map(([label, value], i) => (
          <li key={label} className={`flex items-center justify-between gap-4 py-[18px] font-semibold ${i ? 'border-t border-line' : ''}`}>
            <span>{label}</span>
            <span className="rounded-full bg-charge/15 px-4 py-2 font-mono text-[13px]">
              {value}
            </span>
          </li>
        ))}
      </ul>
      <p className="rv rounded-[28px] border border-line bg-surface px-6 py-5 text-ink-2 shadow-card min-[900px]:col-span-2">{t.tip_p}</p>
    </div>
  </section>
)
