import { HeadContent, Outlet, Scripts, createRootRoute, useParams } from '@tanstack/react-router'
import type { ReactNode } from 'react'
import { toLang } from '../i18n'
import appCss from '../styles.css?url'

const Shell = ({ children }: { children: ReactNode }) => {
  const { lang } = useParams({ strict: false })
  const current = toLang(lang ?? 'en')
  return (
    <html lang={current} dir={current === 'ar' ? 'rtl' : 'ltr'}>
      <head>
        <HeadContent />
      </head>
      <body>
        {children}
        <Scripts />
      </body>
    </html>
  )
}

export const Route = createRootRoute({
  head: () => ({
    meta: [
      { charSet: 'utf-8' },
      { name: 'viewport', content: 'width=device-width, initial-scale=1' },
      { name: 'color-scheme', content: 'light' },
    ],
    links: [
      { rel: 'stylesheet', href: appCss },
      { rel: 'icon', type: 'image/svg+xml', href: '/logo.svg' },
    ],
  }),
  shellComponent: Shell,
  component: Outlet,
})
