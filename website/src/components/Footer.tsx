import type { Copy } from '../i18n'

export const Footer = ({ t }: { t: Copy }) => (
  <footer className="border-t border-line py-6 text-sm text-ink-3">
    <div className="wrap flex flex-wrap justify-between gap-4">
      <span>
        Voltly <span className="num">2026</span>
      </span>
      <a href="https://github.com/0xHamzaDev/Voltly/releases" className="text-ink-2">
        {t.foot_link}
      </a>
    </div>
  </footer>
)
