import type React from "react"
import { Inter } from "next/font/google"
import { ThemeProvider } from "@/components/theme-provider"
import { Toaster } from "@/components/ui/toaster"
import { I18nProvider } from "@/components/i18n-provider"
import { Header } from "@/components/header"
import "@/app/globals.css"

// 将脚本引入移至客户端组件
const font = Inter({ 
  subsets: ["latin"],
  display: "swap", // 优化字体加载
  variable: "--font-inter",
})

export const metadata = {
  title: "GW - Git Workflow Assistant",
  description: "现代化的 Git 工作流助手，简化您的 Git 使用体验",
  generator: 'Next.js'
}

export default function RootLayout({
  children,
  params,
}: {
  children: React.ReactNode
  params: { lang: string }
}) {
  return (
    <html 
      lang={params.lang} 
      suppressHydrationWarning 
      className={`${font.variable} antialiased`}
    >
      <head />
      <body className={font.className}>
        <ThemeProvider 
          attribute="class" 
          defaultTheme="system" 
          enableSystem
          disableTransitionOnChange // 避免主题切换时的闪烁
        >
          <I18nProvider>
            <div className="relative flex min-h-screen flex-col">
              <Header />
              <div className="flex-1 bg-background">{children}</div>
            </div>
            <Toaster />
          </I18nProvider>
        </ThemeProvider>
        {/* 移除了直接在根布局中引入的脚本，将它们移到了专用客户端组件中 */}
      </body>
    </html>
  )
}
