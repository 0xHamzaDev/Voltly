import type { Copy } from '../i18n'

export const Requirements = ({ t }: { t: Copy }) => (
  <ul className="mt-4 flex flex-wrap justify-center gap-x-6 gap-y-1 text-sm text-ink-3">
    {[t.req1, t.req2].map((item) => (
      <li key={item}>{item}</li>
    ))}
  </ul>
)
