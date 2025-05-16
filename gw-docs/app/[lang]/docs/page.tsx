import { redirect } from "next/navigation"

export default function DocsPage({ params }: { params: { lang: string } }) {
  redirect(`/${params.lang}/docs/getting-started`)
}
