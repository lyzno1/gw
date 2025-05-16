import type React from "react"
import { Inter } from "next/font/google"
import { ThemeProvider } from "@/components/theme-provider"
import { Toaster } from "@/components/ui/toaster"
import { I18nProvider } from "@/components/i18n-provider"
import { Header } from "@/components/header"
import "@/app/globals.css"
import Script from "next/script"

const inter = Inter({ subsets: ["latin"] })

// export const metadata = { // Temporarily commented out, will be replaced by generateMetadata
//   title: "GW - Git Workflow Assistant",
//   description: "A modern Git workflow assistant to simplify your Git experience",
//     generator: 'v0.dev'
// }

export default function RootLayout({
  children,
  params,
}: {
  children: React.ReactNode
  params: { lang: string }
}) {
  return (
    <html lang={params.lang} suppressHydrationWarning><head> {/* Removed whitespace/newline */}
        <link
          rel="stylesheet"
          href="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/prism-tomorrow.min.css"
        />
      </head>
      <body className={inter.className}>
        <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
          <I18nProvider>
            <div className="flex min-h-screen flex-col">
              <Header />
              <main className="flex-1">{children}</main>
            </div>
            <Toaster />
          </I18nProvider>
        </ThemeProvider>
        <Script src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js" strategy="afterInteractive" />
        <Script
          src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-bash.min.js"
          strategy="afterInteractive"
        />
      </body>
    </html>
  )
}
