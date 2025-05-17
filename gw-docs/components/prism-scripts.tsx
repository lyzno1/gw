"use client";

import { useEffect } from "react";
import Script from "next/script";
import { useTheme } from "next-themes";

export function PrismScripts() {
  const { theme } = useTheme();
  
  // 动态加载与当前主题匹配的Prism样式
  useEffect(() => {
    // 删除旧样式表（如果存在）
    const existingStylesheet = document.getElementById("prism-theme");
    if (existingStylesheet) {
      existingStylesheet.remove();
    }
    
    // 创建新样式表
    const stylesheet = document.createElement("link");
    stylesheet.id = "prism-theme";
    stylesheet.rel = "stylesheet";
    
    // 根据当前主题选择Prism主题
    const themeName = theme === "dark" ? "prism-tomorrow" : "prism-solarizedlight";
    stylesheet.href = `https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/themes/${themeName}.min.css`;
    
    // 添加到头部
    document.head.appendChild(stylesheet);
  }, [theme]);
  
  return (
    <>
      <Script 
        id="prism-core"
        src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/prism.min.js" 
        strategy="afterInteractive"
        onLoad={() => {
          // 当Prism加载完成后，重新高亮文档中的所有代码块
          if (typeof window !== 'undefined' && window.Prism) {
            window.Prism.highlightAll();
          }
        }}
      />
      <Script
        id="prism-bash"
        src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-bash.min.js"
        strategy="afterInteractive"
      />
      <Script
        id="prism-javascript"
        src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-javascript.min.js"
        strategy="afterInteractive"
      />
      <Script
        id="prism-typescript"
        src="https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/prism-typescript.min.js"
        strategy="afterInteractive"
      />
    </>
  );
} 