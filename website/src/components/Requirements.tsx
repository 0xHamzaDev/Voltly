import type { Dict } from '../i18n'

export const Requirements = ({ t }: { t: Dict }) => (
  <ul className="mt-4 flex flex-wrap justify-center gap-x-6 gap-y-1 text-sm text-ink-3">
    {[t.req1, t.req2, t.req3].map((item) => (
      <li key={item}>{item}</li>
    ))}
  </ul>
)
