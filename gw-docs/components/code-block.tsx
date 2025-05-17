"use client";

import { useState, useEffect, useRef } from "react";
import { Check, Copy } from "lucide-react";
import { cn } from "@/lib/utils";
import { useTranslation } from "@/hooks/use-translation";
import Prism from 'prismjs';

interface CodeBlockProps {
  code: string;
  language?: string;
  className?: string;
}

export function CodeBlock({
  code,
  language = "bash",
  className,
}: CodeBlockProps) {
  const [copied, setCopied] = useState(false);
  const [mounted, setMounted] = useState(false);
  const codeRef = useRef<HTMLElement>(null);
  const { t } = useTranslation();

  // 处理客户端挂载
  useEffect(() => {
    setMounted(true);
    
    // 确保代码高亮在组件挂载和代码更新时应用
    if (codeRef.current && typeof Prism !== 'undefined') {
      Prism.highlightElement(codeRef.current);
    }
  }, [code]);

  // 复制到剪贴板
  const copyToClipboard = async () => {
    if (!navigator.clipboard || !mounted) return;

    try {
      await navigator.clipboard.writeText(code);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error("复制代码失败: ", err);
    }
  };

  // 预计算代码块的预期高度以避免布局偏移
  const lineCount = code.split('\n').length;
  const estimatedHeight = `${Math.max(lineCount * 24, 60)}px`; // 基于行数的最小高度

  return (
    <div
      className={cn(
        "relative my-4 overflow-hidden rounded-lg border bg-muted/30 dark:bg-muted/50",
        className
      )}
      style={{ minHeight: estimatedHeight }} // 预设最小高度避免布局偏移
    >
      {/* 工具栏 - 服务端渲染占位符与客户端渲染内容相同高度 */}
      <div className="flex items-center justify-between px-4 py-1.5 border-b bg-muted/50 dark:bg-muted/70">
        {language && (
          <span className="text-xs font-medium text-muted-foreground">
            {language.toUpperCase()}
          </span>
        )}
        <button
          onClick={copyToClipboard}
          disabled={!mounted}
          className={cn(
            "flex h-8 w-8 items-center justify-center rounded-md text-muted-foreground transition-colors",
            mounted ? "hover:bg-muted-foreground/10" : "opacity-50 cursor-not-allowed",
            "focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring"
          )}
          aria-label={copied ? t("codeBlock.copied") : t("codeBlock.copy")}
        >
          {copied ? (
            <Check className="h-4 w-4 text-green-500" />
          ) : (
            <Copy className="h-4 w-4" />
          )}
        </button>
      </div>

      {/* 代码内容 */}
      <div className="overflow-x-auto p-4">
        <pre className="m-0 p-0 bg-transparent font-mono text-sm leading-relaxed">
          <code
            ref={codeRef}
            className={`language-${language} block w-full h-full !bg-transparent`}
          >
            {code.trim()}
          </code>
        </pre>
      </div>
    </div>
  );
}
