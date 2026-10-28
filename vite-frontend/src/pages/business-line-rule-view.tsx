import type { BusinessLineApiItem } from "@/api/types";

import { useMemo, useState } from "react";
import { ChevronDown, ChevronUp, Layers3, Plus } from "lucide-react";

import { AnimatedPage } from "@/components/animated-page";
import { Button } from "@/shadcn-bridge/heroui/button";

const routeGroups = [
  { key: "frontsea", name: "生产-GZ→前海IX", pathLabel: "前海IX" },
  { key: "qix", name: "生产-GZ→QIX", pathLabel: "QIX" },
] as const;

interface BusinessLineRuleViewProps {
  lines: BusinessLineApiItem[];
  onShowAdvanced: () => void;
}

export function BusinessLineRuleView({
  lines,
  onShowAdvanced,
}: BusinessLineRuleViewProps) {
  const [expandedLineId, setExpandedLineId] = useState<number | null>(null);
  const groupedLines = useMemo(
    () =>
      routeGroups.map((group) => ({
        ...group,
        lines: lines
          .filter((line) => line.pathType === group.key)
          .sort(
            (left, right) =>
              left.createdTime - right.createdTime || left.id - right.id,
          ),
      })),
    [lines],
  );

  return (
    <AnimatedPage className="mx-auto w-full max-w-7xl space-y-5 p-4 md:p-6">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-semibold">业务线路</h1>
          <p className="mt-1 text-sm text-default-500">{lines.length} 条线路</p>
        </div>
        <div className="flex flex-wrap gap-2">
          <Button
            color="primary"
            size="sm"
            startContent={<Plus className="size-4" />}
            variant="flat"
            onPress={() => window.location.assign("/business-line")}
          >
            新增线路
          </Button>
          <Button
            size="sm"
            startContent={<Layers3 className="size-4" />}
            variant="flat"
            onPress={onShowAdvanced}
          >
            底层规则
          </Button>
        </div>
      </div>

      <div className="space-y-5">
        {groupedLines.map((group) => (
          <section
            key={group.key}
            className="overflow-hidden rounded-lg border border-default-200 bg-content1 shadow-sm"
          >
            <div className="flex items-center justify-between gap-3 border-b border-default-200 px-4 py-3 md:px-5">
              <h2 className="min-w-0 break-words text-base font-semibold">
                {group.name}
              </h2>
              <span className="shrink-0 text-sm text-default-500">
                {group.lines.length} 条线路
              </span>
            </div>

            {group.lines.length === 0 ? (
              <p className="px-4 py-6 text-sm text-default-500 md:px-5">
                暂无业务线路
              </p>
            ) : (
              <div className="divide-y divide-default-100">
                {group.lines.map((line) => {
                  const expanded = expandedLineId === line.id;

                  return (
                    <div key={line.id}>
                      <div className="grid grid-cols-[minmax(0,1fr)_auto] items-center gap-x-3 gap-y-2 px-4 py-4 sm:grid-cols-[minmax(0,1.4fr)_80px_92px_minmax(0,1fr)_72px_36px] sm:gap-3 md:px-5">
                        <div className="col-start-1 row-start-1 min-w-0 sm:col-auto sm:row-auto">
                          <div className="break-words font-medium text-foreground">
                            {line.name}
                          </div>
                          <div className="mt-1 text-xs text-default-500 sm:hidden">
                            入口 {line.entryPort} · {group.pathLabel}
                          </div>
                        </div>
                        <div className="hidden text-sm sm:block">
                          <div className="text-xs text-default-500">入口</div>
                          <div>{line.entryPort}</div>
                        </div>
                        <div className="hidden text-sm sm:block">
                          <div className="text-xs text-default-500">路径</div>
                          <div>{group.pathLabel}</div>
                        </div>
                        <div className="col-start-1 row-start-2 min-w-0 text-sm sm:col-auto sm:row-auto">
                          <div className="text-xs text-default-500">目标</div>
                          <div className="break-all">
                            {line.targetHost}:{line.targetPort}
                          </div>
                        </div>
                        <div className="col-start-2 row-start-2 sm:col-auto sm:row-auto">
                          <span className="inline-flex rounded bg-success-50 px-2 py-1 text-xs text-success-700">
                            {line.status === "active" ? "正常" : line.status}
                          </span>
                        </div>
                        <Button
                          isIconOnly
                          aria-expanded={expanded}
                          aria-label={
                            expanded ? "收起内部路径" : "查看内部路径"
                          }
                          className="col-start-2 row-start-1 sm:col-auto sm:row-auto"
                          size="sm"
                          title={expanded ? "收起内部路径" : "查看内部路径"}
                          variant="light"
                          onPress={() =>
                            setExpandedLineId(expanded ? null : line.id)
                          }
                        >
                          {expanded ? (
                            <ChevronUp className="size-4" />
                          ) : (
                            <ChevronDown className="size-4" />
                          )}
                        </Button>
                      </div>

                      {expanded && (
                        <div className="border-t border-default-100 bg-default-50 px-4 py-3 text-sm text-default-700 md:px-5">
                          <div className="break-words font-medium">
                            内部路径
                          </div>
                          <div className="mt-1 break-all font-mono text-xs leading-6">
                            {line.pathType === "frontsea" ? (
                              <>
                                GZ:{line.entryPort} → 前海IX:
                                {line.ixPort ?? "自动分配"} → {line.targetHost}:
                                {line.targetPort}
                              </>
                            ) : (
                              <>
                                GZ:{line.entryPort} → QIX共享Tunnel →{" "}
                                {line.targetHost}:{line.targetPort}
                              </>
                            )}
                          </div>
                          <div className="mt-1 text-xs text-default-500">
                            {line.pathType === "frontsea"
                              ? `底层转发：GZ #${line.gzForwardId} · 前海IX #${line.ixForwardId ?? "-"}`
                              : `共享 Tunnel ID：${line.tunnelId ?? "-"}`}
                          </div>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            )}
          </section>
        ))}
      </div>
    </AnimatedPage>
  );
}
