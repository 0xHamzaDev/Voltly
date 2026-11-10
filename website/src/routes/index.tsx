import { createFileRoute } from '@tanstack/react-router'
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
import { copy } from '../i18n'

const Page = () => (
  <>
    <Header t={copy} />
    <main id="top">
      <Hero t={copy} />
      <Demo t={copy} />
      <Why t={copy} />
      <Features t={copy} />
      <Steps t={copy} />
      <Setup t={copy} />
      <Faq t={copy} />
      <Closing t={copy} />
    </main>
    <Footer t={copy} />
  </>
)

export const Route = createFileRoute('/')({
  head: () => ({
    meta: [
      { title: copy.title },
      { name: 'description', content: copy.meta_desc },
    ],
  }),
  component: Page,
})
