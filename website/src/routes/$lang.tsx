import { createFileRoute, redirect } from '@tanstack/react-router'
import { Closing } from '../components/Closing'
import { Demo } from '../components/Demo'
import { Faq } from '../components/Faq'
import { Features } from '../components/Features'
import { Footer } from '../components/Footer'
import { Header } from '../components/Header'
import { Hero } from '../components/Hero'
import { Setup } from '../components/Setup'
import { Steps } from '../components/Steps'
import { Why } from '../components/Why'
import { dict, toLang } from '../i18n'

const Page = () => {
  const lang = toLang(Route.useParams().lang)
  const t = dict[lang]
  return (
    <>
      <Header t={t} lang={lang} />
      <main id="top">
        <Hero t={t} />
        <Demo t={t} />
        <Why t={t} />
        <Features t={t} />
        <Steps t={t} />
        <Setup t={t} />
        <Faq t={t} />
        <Closing t={t} />
      </main>
      <Footer t={t} />
    </>
  )
}

export const Route = createFileRoute('/$lang')({
  beforeLoad: ({ params }) => {
    if (params.lang !== toLang(params.lang)) {
      throw redirect({ to: '/$lang', params: { lang: 'en' } })
    }
  },
  head: ({ params }) => {
    const t = dict[toLang(params.lang)]
    return {
      meta: [
        { title: t.title },
        { name: 'description', content: t.meta_desc },
      ],
      links: [
        { rel: 'alternate', hreflang: 'en', href: '/en' },
        { rel: 'alternate', hreflang: 'ar', href: '/ar' },
      ],
    }
  },
  component: Page,
})
