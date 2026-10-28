import { siteConfig } from "@/config/site";

interface VersionFooterProps {
  version: string;
  containerClassName?: string;
  versionClassName?: string;
  poweredClassName?: string;
  updateBadgeClassName?: string;
}

export function VersionFooter({
  version,
  containerClassName,
  versionClassName,
  poweredClassName,
}: VersionFooterProps) {
  return (
    <div className={containerClassName}>
      <p className={versionClassName}>v{version}</p>
      {siteConfig.hide_footer_brand !== true && (
        <p className={poweredClassName}>
          Powered by{" "}
          <a
            className="text-gray-500 dark:text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 transition-colors"
            href={siteConfig.github_repo}
            rel="noopener noreferrer"
            target="_blank"
          >
            FLVX
          </a>
        </p>
      )}
    </div>
  );
}
