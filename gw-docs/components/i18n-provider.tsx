"use client"

import type React from "react"

import { createContext, useEffect, useState } from "react"

export const I18nContext = createContext<{
  locale: string
  setLocale: (locale: string) => void
}>({
  locale: "en",
  setLocale: () => {},
})

export function I18nProvider({ children }: { children: React.ReactNode }) {
  const [locale, setLocale] = useState("en")

  useEffect(() => {
    const savedLocale = localStorage.getItem("locale")
    if (savedLocale) {
      setLocale(savedLocale)
    } else {
      // Try to detect browser language
      const browserLang = navigator.language.split("-")[0]
      if (browserLang === "zh") {
        setLocale("zh")
      }
    }
  }, [])

  const handleSetLocale = (newLocale: string) => {
    setLocale(newLocale)
    localStorage.setItem("locale", newLocale)
  }

  return <I18nContext.Provider value={{ locale, setLocale: handleSetLocale }}>{children}</I18nContext.Provider>
}
