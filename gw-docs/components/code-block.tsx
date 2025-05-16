"use client";

import { useState, useEffect } from "react";
import { Check, Copy } from "lucide-react";
import { cn } from "@/lib/utils";
import { useTranslation } from "@/hooks/use-translation";

interface CodeBlockProps {
  code: string;
  language?: string;
  className?: string;
}

export function CodeBlock({
  code,
  language,
  className,
}: CodeBlockProps) {
  const [copied, setCopied] = useState(false);
  const [isClientMounted, setIsClientMounted] = useState(false); // State to track client mount
  const { t } = useTranslation(); // For aria-label or other UI text

  useEffect(() => {
    setIsClientMounted(true); // Set to true once component is mounted on the client
  }, []);

  const copyToClipboard = async () => {
    if (!navigator.clipboard) return;

    try {
      await navigator.clipboard.writeText(code);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error("Failed to copy code: ", err);
      // Optionally, provide user feedback here
    }
  };

  // Basic styling for pre and code to ensure consistent font and prevent抖动
  const codeStyle: React.CSSProperties = {
    fontFamily: "Consolas, 'Liberation Mono', Menlo, Courier, monospace",
    fontSize: "14px", // Consistent font size
    lineHeight: "1.5", // Consistent line height
    whiteSpace: "pre", // Preserve whitespace and newlines
  };

  return (
    <div
      className={cn(
        "relative my-4 overflow-hidden rounded-lg border bg-muted/30 dark:bg-muted/50", // Adjusted background for better contrast
        className
      )}
    >
      {/* Toolbar */}
      {isClientMounted && (language || (typeof navigator !== 'undefined' && navigator.clipboard)) && ( // CORRECTED: Check isClientMounted
        <div className="flex items-center justify-between px-4 py-1 border-b"> {/* Changed py-2 to py-1 */}
          {language && (
            <span className="text-xs font-medium text-muted-foreground">
              {language.toUpperCase()}
            </span>
          )}
          {isClientMounted && typeof navigator !== 'undefined' && navigator.clipboard && ( // CORRECTED: Check isClientMounted
            <button
              onClick={copyToClipboard}
              className="flex h-8 w-8 items-center justify-center rounded-md text-muted-foreground transition-colors hover:bg-muted-foreground/10 focus:ring-2 focus:ring-ring focus:ring-offset-2"
              style={{ outline: 'none' }}
              aria-label={copied ? t("codeBlock.copied") : t("codeBlock.copy")}
            >
              {copied ? (
                <Check className="h-4 w-4 text-green-500" />
              ) : (
                <Copy className="h-4 w-4" />
              )}
            </button>
          )}
        </div>
      )}

      {/* Code Content */}
      <div className="overflow-x-auto px-4 py-2"> {/* Changed p-4 to px-4 py-2 */}
        <pre
          style={{ ...codeStyle, margin: 0, padding: 0 }} // More explicit reset
          className="bg-transparent" // Removed !m-0 !p-0 from className as style prop takes precedence
        >
          <code
            style={{ ...codeStyle, margin: 0, padding: 0, display: 'block' }} // More explicit reset, display:block might help with spacing
            className="!bg-transparent" // Reset bg from code
          >
            {code.trimStart()} {/* Trim leading whitespace from the code string itself */}
          </code>
        </pre>
      </div>
    </div>
  );
}
