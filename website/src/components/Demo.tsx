import { ArrowDown, ArrowUp, Battery, RotateCw, Zap } from 'lucide-react'
import { useEffect, useState, type CSSProperties } from 'react'
import type { Dict } from '../i18n'

type Mode = 'normal' | 'top' | 'dis' | 'cal'
type StatusKey = 'st_charge' | 'st_hold' | 'st_top' | 'st_dis' | 'st_sail' | 'st_cal'
type Switch = 'sail' | 'heat' | 'auto'

type State = {
  pct: number
  limit: number
  mode: Mode
  phase: 'down' | 'up'
  held: boolean
  sail: boolean
  heat: boolean
  auto: boolean
  key: StatusKey
  ticks: number
}

const initial: State = {
  pct: 72,
  limit: 80,
  mode: 'normal',
  phase: 'down',
  held: false,
  sail: true,
  heat: true,
  auto: false,
  key: 'st_charge',
  ticks: 0,
}

const tick = (s: State): State => {
  const n = { ...s, ticks: s.ticks + 1 }
  const drift = () => {
    if (n.ticks % 4 === 0) n.pct -= 1
  }
  if (n.mode === 'top' && n.pct >= 100) n.mode = 'normal'
  if (n.mode === 'dis' && n.pct <= n.limit) n.mode = 'normal'
  if (n.mode === 'cal' && n.phase === 'down' && n.pct <= 5) n.phase = 'up'
  if (n.mode === 'cal' && n.phase === 'up' && n.pct >= 100) n.mode = 'normal'
  if (n.mode === 'top') {
    n.pct += 1
    n.key = 'st_top'
  } else if (n.mode === 'dis') {
    n.pct -= 1
    n.key = 'st_dis'
  } else if (n.mode === 'cal') {
    n.pct += n.phase === 'up' ? 2 : -2
    n.key = 'st_cal'
  } else if (n.pct > n.limit) {
    if (n.auto) {
      n.pct -= 1
      n.key = 'st_dis'
    } else {
      n.key = 'st_hold'
      drift()
    }
  } else if (n.pct < n.limit) {
    if (n.held && n.sail && n.pct > n.limit - 5) {
      n.key = 'st_sail'
      drift()
    } else {
      n.held = false
      n.pct += 1
      n.key = 'st_charge'
    }
  } else {
    n.held = true
    if (n.sail) {
      n.key = 'st_sail'
      drift()
    } else {
      n.key = 'st_hold'
    }
  }
  n.pct = Math.min(100, Math.max(0, n.pct))
  return n
}

const isolate = (text: string) =>
  text.split(/(\d+%)/).map((part, i) =>
    i % 2 ? (
      <bdi key={i} dir="ltr">
        {part}
      </bdi>
    ) : (
      part
    ),
  )

export const Demo = ({ t }: { t: Dict }) => {
  const [s, setS] = useState(initial)

  useEffect(() => {
    const id = setInterval(() => setS(tick), 600)
    return () => clearInterval(id)
  }, [])

  const toggleMode = (mode: Mode) =>
    setS((p) => {
      if (p.mode === mode) return tick({ ...p, mode: 'normal' })
      if (mode === 'dis' && p.pct <= p.limit) return p
      return tick({ ...p, mode, phase: 'down' })
    })

  const toggleSwitch = (key: Switch) => setS((p) => tick({ ...p, [key]: !p[key] }))

  const status = t[s.key].replace('{l}', `${s.limit}%`).replace('{n}', `${Math.max(s.limit - 5, 0)}%`)

  const modes = [
    { mode: 'top', Icon: ArrowUp, label: t.pop_topup },
    { mode: 'dis', Icon: ArrowDown, label: t.pop_discharge },
    { mode: 'cal', Icon: RotateCw, label: t.pop_calibrate },
  ] as const

  const switches = [
    { key: 'sail', label: t.pop_sailing },
    { key: 'heat', label: t.pop_heat },
    { key: 'auto', label: t.pop_auto },
  ] as const

  return (
    <div className="wrap enter mt-[72px] [--enter-delay:900ms]">
      <div className="stage relative mx-auto min-h-[580px] max-w-[1088px] overflow-hidden rounded-[40px] border border-line shadow-deep text-start max-[760px]:min-h-[560px]">
        <div aria-hidden="true" className="flex items-center gap-[18px] border-b border-line bg-white/70 px-5 py-2.5 text-[13px] text-ink-2 backdrop-blur-[14px]">
          <span className="font-bold text-ink">Voltly</span>
          <span className="max-[640px]:hidden">{t.mb1}</span>
          <span className="max-[640px]:hidden">{t.mb2}</span>
          <span className="max-[640px]:hidden">{t.mb3}</span>
          <span className="flex-1" />
          <span className="flex items-center rounded-md bg-ink/10 px-2 py-0.5 text-ink">
            <Zap size={14} strokeWidth={2} />
          </span>
          <span className="flex items-center gap-1.5">
            <Battery size={20} strokeWidth={1.5} />
            <bdi dir="ltr">{s.pct}%</bdi>
          </span>
          <bdi dir="ltr">9:41</bdi>
        </div>
        <div className="absolute top-[52px] end-24 w-[300px] rounded-2xl border border-line bg-white/80 p-5 text-sm leading-[1.4] shadow-deep backdrop-blur-[24px] backdrop-saturate-[160%] max-[760px]:start-0 max-[760px]:end-0 max-[760px]:mx-auto">
          <div className="font-round text-[64px] leading-none font-bold tracking-[-0.04em]">
            <bdi dir="ltr">{s.pct}%</bdi>
          </div>
          <div className="relative my-4 h-3.5 rounded-full bg-surface-2">
            <i className="absolute inset-y-0 start-0 rounded-full bg-charge transition-[inline-size] duration-500 ease-linear" style={{ inlineSize: `${s.pct}%` }} />
            <b className="absolute inset-y-[-5px] w-0.5 rounded-[1px] bg-ink transition-[inset-inline-start] duration-200" style={{ insetInlineStart: `${s.limit}%` }} />
          </div>
          <p className="min-h-5 font-semibold text-ink" aria-live="polite">
            {isolate(status)}
          </p>
          <div className="mt-5 mb-1.5 flex items-baseline justify-between text-[13px] text-ink-2">
            <label htmlFor="limit">{t.pop_limit}</label>
            <output htmlFor="limit" className="num font-semibold text-ink">
              {s.limit}%
            </output>
          </div>
          <input
            id="limit"
            type="range"
            min={20}
            max={100}
            step={1}
            value={s.limit}
            className="slider"
            style={{ '--p': `${((s.limit - 20) / 80) * 100}%` } as CSSProperties}
            onChange={(e) => {
              const limit = Number(e.target.value)
              setS((p) => tick({ ...p, limit }))
            }}
          />
          <div className="mt-4 mb-2 grid grid-cols-3 gap-2">
            {modes.map(({ mode, Icon, label }) => (
              <button
                key={mode}
                type="button"
                aria-pressed={s.mode === mode}
                onClick={() => toggleMode(mode)}
                className="flex cursor-pointer flex-col items-center gap-1.5 rounded-xl border border-line bg-white/70 px-1 py-3 text-xs font-semibold transition-colors hover:bg-white aria-pressed:border-ink aria-pressed:bg-ink aria-pressed:text-white"
              >
                <Icon size={18} strokeWidth={2} aria-hidden="true" />
                <span>{label}</span>
              </button>
            ))}
          </div>
          <div>
            {switches.map(({ key, label }) => (
              <button
                key={key}
                type="button"
                role="switch"
                aria-checked={s[key]}
                onClick={() => toggleSwitch(key)}
                className="group flex w-full cursor-pointer items-center justify-between border-t border-line py-3 text-start text-sm"
              >
                <span>{label}</span>
                <span className="sw relative h-6 w-10 flex-none rounded-xl bg-surface-2 transition-colors group-aria-checked:bg-charge" />
              </button>
            ))}
          </div>
        </div>
      </div>
      <p className="mt-5 text-center text-sm text-ink-3">{t.demo_hint}</p>
    </div>
  )
}
