import { Download, Laptop } from 'lucide-react'

export const DownloadButton = ({ label, size }: { label: string; size: 'sm' | 'lg' }) => (
  <a
    href="https://github.com/0xHamzaDev/Voltly/releases/latest"
    className={`btn inline-flex items-center gap-2.5 rounded-full bg-ink font-semibold text-white no-underline ${
      size === 'lg' ? 'px-7 py-4 text-[17px] shadow-btn' : 'px-5 py-2.5 text-[15px]'
    }`}
  >
    <span className="ico" aria-hidden="true">
      <Laptop className="i1" strokeWidth={2} />
      <Download className="i2" strokeWidth={2} />
    </span>
    <span className={size === 'sm' ? 'max-[479px]:sr-only' : ''}>{label}</span>
  </a>
)
