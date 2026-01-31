import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  // Override default ignores of eslint-config-next.
  globalIgnores([
    // Default ignores of eslint-config-next:
    ".next/**",
    "out/**",
    "build/**",
    "next-env.d.ts",
  ]),
  // Custom rule overrides
  {
    rules: {
      // Allow explicit any for catch blocks, external API responses, and dynamic data
      // Use sparingly - prefer unknown or specific types where practical
      "@typescript-eslint/no-explicit-any": "warn",
      // Allow unused vars with underscore prefix (common pattern for intentionally unused)
      "@typescript-eslint/no-unused-vars": [
        "warn",
        {
          argsIgnorePattern: "^_",
          varsIgnorePattern: "^_",
          caughtErrorsIgnorePattern: "^_",
        },
      ],
      // Allow quotes in JSX text - they render correctly and are common in user-facing text
      "react/no-unescaped-entities": "off",
      // React purity rules - warn instead of error (these need refactoring but aren't blocking bugs)
      "react-hooks/purity": "warn",
      "react-hooks/set-state-in-effect": "warn",
      "react-hooks/static-components": "warn",
      // Allow empty object types (common in generic type constraints)
      "@typescript-eslint/no-empty-object-type": "warn",
    },
  },
]);

export default eslintConfig;
