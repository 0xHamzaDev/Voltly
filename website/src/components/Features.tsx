import type { ReactNode } from 'react'
import type { Copy } from '../i18n'

const Card = ({ className, children }: { className: string; children: ReactNode }) => (
  <article className={`card rv ${className}`}>{children}</article>
)

const Bar = ({ children, className = '' }: { children: ReactNode; className?: string }) => (
  <div className={`relative h-[18px] rounded-full bg-surface-2 ${className}`}>{children}</div>
)

const Scale = ({ children }: { children: ReactNode }) => (
  <div className="mt-3.5 flex justify-between font-mono text-[13px] text-ink-3">{children}</div>
)

const Fill = ({ className }: { className: string }) => (
  <i className={`absolute inset-y-0 start-0 rounded-full ${className}`} />
)

const Marker = ({ className }: { className: string }) => (
  <b className={`absolute inset-y-[-7px] w-[3px] rounded-sm ${className}`} />
)

export const Features = ({ t }: { t: Copy }) => (
  <section id="features" className="pt-(--sec)" aria-labelledby="feat-h">
    <div className="wrap">
      <h2 id="feat-h" className="rv">
        {t.feat_h}
      </h2>
      <p className="rv mt-[18px] max-w-[34em] text-[clamp(18px,1.7vw,21px)] leading-normal text-ink-2">{t.feat_lead}</p>
      <div className="bento mt-14 grid gap-4 min-[900px]:grid-cols-12">
        <Card className="tint-ice min-[900px]:col-span-7">
          <div className="num text-[clamp(64px,9vw,120px)] leading-[0.9] font-extrabold tracking-[-0.06em] text-ink" aria-hidden="true">
            80%
          </div>
          <div>
            <Bar className="mb-7">
              <Fill className="w-[80%] bg-charge" />
              <Marker className="start-[80%] bg-ink" />
            </Bar>
            <h3>{t.f_limit_h}</h3>
            <p className="mt-2.5 text-ink-2">{t.f_limit_p}</p>
          </div>
        </Card>
        <Card className="tint-accent min-[900px]:col-span-5">
          <div aria-hidden="true">
            <Bar>
              <Fill className="w-[78%] bg-charge" />
              <Fill className="start-[75%] w-[5%] rounded-[3px] bg-charge/55 outline-2 outline-charge" />
            </Bar>
            <Scale>
              <span className="num">75%</span>
              <span className="num">80%</span>
            </Scale>
          </div>
          <div>
            <h3>{t.pop_sailing}</h3>
            <p className="mt-2.5 text-ink-2">{t.f_sail_p}</p>
          </div>
        </Card>
        <Card className="tint-warm min-[900px]:col-span-4">
          <div aria-hidden="true">
            <Bar>
              <Fill className="w-[70%] bg-warm" />
              <Marker className="start-[70%] bg-warm" />
            </Bar>
            <Scale>
              <span className="num">20°C</span>
              <span className="num font-bold text-ink">35°C</span>
              <span className="num">45°C</span>
            </Scale>
          </div>
          <div>
            <h3>{t.pop_heat}</h3>
            <p className="mt-2.5 text-ink-2">{t.f_heat_p}</p>
          </div>
        </Card>
        <Card className="tint-ice min-[900px]:col-span-4">
          <div aria-hidden="true">
            <Bar>
              <Fill className="w-[80%] bg-charge" />
              <Fill className="start-[80%] w-[20%] rounded-s-none bg-[repeating-linear-gradient(135deg,rgba(31,184,90,0.5)_0_6px,transparent_6px_12px)]" />
              <Marker className="start-[80%] bg-ink" />
            </Bar>
            <Scale>
              <span className="num">80%</span>
              <span className="num">100%</span>
            </Scale>
          </div>
          <div>
            <h3>{t.pop_topup}</h3>
            <p className="mt-2.5 text-ink-2">{t.f_top_p}</p>
          </div>
        </Card>
        <Card className="tint-accent min-[900px]:col-span-4">
          <div aria-hidden="true">
            <Bar className="outline-1 outline-line">
              <Fill className="w-[80%] bg-charge" />
              <Marker className="start-[80%] bg-ink" />
            </Bar>
            <Scale>
              <span className="num">80%</span>
              <span className="num">100%</span>
            </Scale>
          </div>
          <div>
            <h3>{t.f_dis_h}</h3>
            <p className="mt-2.5 text-ink-2">{t.f_dis_p}</p>
          </div>
        </Card>
        <Card className="tint-ice min-[900px]:col-span-8">
          <h3>{t.c6_h}</h3>
          <div className="grid gap-8 min-[700px]:grid-cols-2">
            <div>
              <div className="flex gap-2" aria-hidden="true">
                {[1, 0, 1, 0, 0, 1, 0].map((on, i) => (
                  <i key={i} className={`h-9 flex-1 rounded-[10px] ${on ? 'bg-accent' : 'bg-surface-2'}`} />
                ))}
              </div>
              <h4 className="mt-5 mb-3.5 text-xl leading-[1.3] font-bold tracking-[-0.02em]">{t.f_sch_h}</h4>
              <p className="text-ink-2">{t.f_sch_p}</p>
            </div>
            <div>
              <h4 className="mb-3.5 text-xl leading-[1.3] font-bold tracking-[-0.02em]">{t.f_sc_h}</h4>
              <p className="text-ink-2">{t.f_sc_p}</p>
              <ul className="mt-4 flex flex-wrap gap-2">
                {[t.sc1, t.sc2, t.sc3, t.sc4, t.sc5].map((item) => (
                  <li key={item} className="rounded-full border border-line bg-surface-2 px-4 py-2.5 font-mono text-[13px]">
                    {item}
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </Card>
        <Card className="tint-accent min-[900px]:col-span-4">
          <svg viewBox="0 0 240 80" fill="none" strokeLinecap="round" strokeLinejoin="round" className="h-auto max-h-[90px] w-full" aria-hidden="true">
            <path d="M4 76H236M4 4H236" className="stroke-line" strokeWidth="1" strokeDasharray="4 6" />
            <path d="M6 8 120 72 234 8" className="stroke-accent" strokeWidth="2" />
          </svg>
          <div>
            <h3>{t.f_cal_h}</h3>
            <p className="mt-2.5 text-ink-2">{t.f_cal_p}</p>
          </div>
        </Card>
        <Card className="tint-ice min-[900px]:col-span-12">
          <h3>{t.rest_h}</h3>
          <dl className="mt-2 grid gap-x-12 min-[700px]:grid-cols-2">
            {[
              [t.r_sleep_h, t.r_sleep_p],
              [t.r_ctrl_h, t.r_ctrl_p],
              [t.f_led_h, t.f_led_p],
              [t.f_lpm_h, t.f_lpm_p],
              [t.f_clam_h, t.f_clam_p],
              [t.f_icons_h, t.f_icons_p],
              [t.f_pop_h, t.f_pop_p],
            ].map(([term, desc], i) => (
              <div key={term} className="border-t border-line py-[18px]">
                <dt className="flex items-center gap-2.5 text-lg font-bold">
                  {term}
                  {i === 2 && (
                    <span className="inline-flex gap-1.5" aria-hidden="true">
                      <i className="block size-2.5 rounded-full bg-charge" />
                      <i className="block size-2.5 rounded-full bg-[#f08a1c]" />
                      <i className="block size-2.5 rounded-full border-2 border-ink-3" />
                    </span>
                  )}
                </dt>
                <dd className="mt-1 text-ink-2">{desc}</dd>
              </div>
            ))}
          </dl>
        </Card>
      </div>
    </div>
  </section>
)
