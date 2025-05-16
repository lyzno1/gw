"use client"

import { useContext } from "react"
import { I18nContext } from "@/components/i18n-provider"
import { en } from "@/locales/en"
import { zh } from "@/locales/zh"

export function useTranslation() {
  const { locale, setLocale } = useContext(I18nContext)

  const translations = {
    en,
    zh,
  }

  const t = (key: string) => {
    const keys = key.split(".")
    let value = translations[locale as keyof typeof translations]

    for (const k of keys) {
      if (value && typeof value === "object" && k in value) {
        value = value[k as keyof typeof value]
      } else {
        // Fallback to English if key not found
        let fallback = translations.en
        for (const fk of keys) {
          if (fallback && typeof fallback === "object" && fk in fallback) {
            fallback = fallback[fk as keyof typeof fallback]
          } else {
            return key // Return the key if not found in fallback
          }
        }
        return fallback as string
      }
    }

    return value as string
  }

  return { t, locale, setLocale }
}
