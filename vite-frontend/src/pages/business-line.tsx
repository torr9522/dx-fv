import type { BusinessLineApiItem } from "@/api/types";

import { Fragment, useEffect, useState } from "react";
import toast from "react-hot-toast";
import { ChevronDown, ChevronUp, Trash2 } from "lucide-react";

import { AnimatedPage } from "@/components/animated-page";
import { Button } from "@/shadcn-bridge/heroui/button";
import { Input } from "@/shadcn-bridge/heroui/input";
import { Radio, RadioGroup } from "@/shadcn-bridge/heroui/radio";
import { Switch } from "@/shadcn-bridge/heroui/switch";
import {
  createBusinessLine,
  deleteBusinessLine,
  getBusinessLineList,
  updateBusinessLineProtocol,
} from "@/api";

const initialForm = {
  name: "",
  pathType: "frontsea" as "frontsea" | "qix",
  entryPort: "",
  targetHost: "",
  targetPort: "",
  protocolMode: "tcp_udp" as "tcp_udp" | "tcp",
};

const validPort = (value: string) => {
  const port = Number(value);

  return Number.isInteger(port) && port >= 1 && port <= 65535;
};

export default function BusinessLinePage() {
  const [lines, setLines] = useState<BusinessLineApiItem[]>([]);
  const [form, setForm] = useState(initialForm);
  const [loading, setLoading] = useState(false);
  const [expanded, setExpanded] = useState<number | null>(null);
  const [switchingProtocol, setSwitchingProtocol] = useState<number | null>(
    null,
  );

  const load = async () => {
    const response = await getBusinessLineList();

    if (response.code !== 0) {
      throw new Error(response.msg || "业务线路加载失败");
    }
    setLines(response.data || []);
  };

  useEffect(() => {
    void load().catch((error: unknown) => {
      toast.error(error instanceof Error ? error.message : "业务线路加载失败");
    });
  }, []);

  const update = (key: keyof typeof initialForm, value: string) =>
    setForm((old) => ({ ...old, [key]: value }));

  const submit = async () => {
    if (!form.name.trim()) {
      toast.error("请输入线路名称");

      return;
    }
    if (!validPort(form.entryPort)) {
      toast.error("GZ入口端口必须是 1-65535");

      return;
    }
    if (!form.targetHost.trim()) {
      toast.error("落地 IP / Host 不能为空");

      return;
    }
    if (!validPort(form.targetPort)) {
      toast.error("落地端口必须是 1-65535");

      return;
    }

    setLoading(true);
    try {
      const response = await createBusinessLine({
        name: form.name.trim(),
        pathType: form.pathType,
        entryPort: Number(form.entryPort),
        targetHost: form.targetHost.trim(),
        targetPort: Number(form.targetPort),
        protocolMode: form.protocolMode,
      });

      if (response.code !== 0) {
        throw new Error(response.msg || "线路创建失败");
      }
      toast.success("线路创建成功");
      setForm(initialForm);
      await load();
    } catch (error: unknown) {
      toast.error(error instanceof Error ? error.message : "线路创建失败");
    } finally {
      setLoading(false);
    }
  };

  const switchProtocol = async (line: BusinessLineApiItem) => {
    const nextMode = line.protocolMode === "tcp_udp" ? "tcp" : "tcp_udp";
    const message =
      nextMode === "tcp"
        ? "将协议从 TCP+UDP 切换为 TCP。\n\nUDP 将停止，现有 TCP 应保持运行。"
        : "将协议从 TCP 切换为 TCP+UDP。\n\nUDP 将恢复。";

    if (!window.confirm(message)) return;

    setSwitchingProtocol(line.id);
    try {
      const response = await updateBusinessLineProtocol(line.id, nextMode);

      if (response.code !== 0) {
        throw new Error(response.msg || "协议切换失败");
      }
      toast.success(nextMode === "tcp" ? "已切换为 TCP" : "已切换为 TCP+UDP");
      await load();
    } catch (error: unknown) {
      toast.error(error instanceof Error ? error.message : "协议切换失败");
    } finally {
      setSwitchingProtocol(null);
    }
  };

  const remove = async (line: BusinessLineApiItem) => {
    if (
      !window.confirm(
        `确定删除“${line.name}”吗？\n\n该操作会同时删除系统自动创建的底层转发规则，共享 QIX 隧道不会被删除。`,
      )
    ) {
      return;
    }
    const response = await deleteBusinessLine(line.id);

    if (response.code !== 0) {
      toast.error(response.msg || "线路删除失败");

      return;
    }
    toast.success("线路已删除");
    if (expanded === line.id) setExpanded(null);
    await load();
  };

  return (
    <AnimatedPage className="mx-auto w-full max-w-7xl space-y-6 p-4 md:p-6">
      <div>
        <h1 className="text-2xl font-semibold">业务线路</h1>
      </div>

      <section className="rounded-lg border border-default-200 bg-content1 p-5 shadow-sm">
        <h2 className="mb-4 text-lg font-medium">新增线路</h2>
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          <Input
            label="线路名称"
            value={form.name}
            onChange={(event) => update("name", event.target.value)}
          />
          <label className="flex flex-col gap-1 text-sm">
            <span>路径</span>
            <select
              className="h-10 rounded-medium border border-default-200 bg-content1 px-3"
              value={form.pathType}
              onChange={(event) => update("pathType", event.target.value)}
            >
              <option value="frontsea">前海IX</option>
              <option value="qix">QIX</option>
            </select>
          </label>
          <Input
            label="GZ入口端口"
            max={65535}
            min={1}
            type="number"
            value={form.entryPort}
            onChange={(event) => update("entryPort", event.target.value)}
          />
          <Input
            label="落地 IP / Host"
            value={form.targetHost}
            onChange={(event) => update("targetHost", event.target.value)}
          />
          <Input
            label="落地端口"
            max={65535}
            min={1}
            type="number"
            value={form.targetPort}
            onChange={(event) => update("targetPort", event.target.value)}
          />
          <RadioGroup
            label="协议模式"
            orientation="horizontal"
            value={form.protocolMode}
            onValueChange={(value) => update("protocolMode", value)}
          >
            <Radio value="tcp_udp">TCP+UDP</Radio>
            <Radio value="tcp">TCP</Radio>
          </RadioGroup>
        </div>
        <Button
          className="mt-5"
          color="primary"
          isLoading={loading}
          onPress={() => void submit()}
        >
          创建线路
        </Button>
      </section>

      <section className="rounded-lg border border-default-200 bg-content1 p-5 shadow-sm">
        <h2 className="mb-4 text-lg font-medium">已创建线路</h2>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[720px] text-left text-sm">
            <thead>
              <tr className="border-b border-default-200 text-default-500">
                <th className="p-2">线路名称</th>
                <th className="p-2">入口端口</th>
                <th className="p-2">路径</th>
                <th className="p-2">落地</th>
                <th className="p-2">状态</th>
                <th className="p-2" />
              </tr>
            </thead>
            <tbody>
              {lines.map((line) => (
                <Fragment key={line.id}>
                  <tr className="border-b border-default-100">
                    <td className="p-2 font-medium">
                      <span>{line.name}</span>
                      <span className="ml-2 inline-flex rounded bg-default-100 px-2 py-0.5 text-xs font-normal text-default-600">
                        {line.protocolMode === "tcp" ? "TCP" : "TCP+UDP"}
                      </span>
                    </td>
                    <td className="p-2">{line.entryPort}</td>
                    <td className="p-2">
                      {line.pathType === "frontsea" ? "前海IX" : "QIX"}
                    </td>
                    <td className="p-2">
                      {line.targetHost}:{line.targetPort}
                    </td>
                    <td className="p-2">
                      <span className="rounded bg-success-50 px-2 py-1 text-success-700">
                        {line.status === "active" ? "正常" : line.status}
                      </span>
                    </td>
                    <td className="p-2 text-right whitespace-nowrap">
                      <Button
                        isIconOnly
                        size="sm"
                        title={expanded === line.id ? "收起详情" : "查看详情"}
                        variant="light"
                        onPress={() =>
                          setExpanded(expanded === line.id ? null : line.id)
                        }
                      >
                        {expanded === line.id ? (
                          <ChevronUp className="size-4" />
                        ) : (
                          <ChevronDown className="size-4" />
                        )}
                      </Button>
                      <Button
                        className="ml-1"
                        color="danger"
                        size="sm"
                        startContent={<Trash2 className="size-4" />}
                        variant="light"
                        onPress={() => void remove(line)}
                      >
                        删除
                      </Button>
                    </td>
                  </tr>
                  {expanded === line.id && (
                    <tr className="border-b border-default-100 bg-default-50">
                      <td className="p-3 text-default-600" colSpan={6}>
                        <div className="flex flex-wrap items-center justify-between gap-3">
                          <span>
                            {line.pathType === "frontsea"
                              ? `内部端口：${line.ixPort ?? "-"}；底层转发：GZ #${line.gzForwardId}${line.ixForwardId ? ` / 前海IX #${line.ixForwardId}` : ""}`
                              : `共享 QIX 隧道 #${line.tunnelId ?? "-"}；底层转发：GZ #${line.gzForwardId}`}
                          </span>
                          <label className="flex items-center gap-3 text-sm text-foreground">
                            <span>
                              协议：
                              {line.protocolMode === "tcp" ? "TCP" : "TCP+UDP"}
                            </span>
                            <Switch
                              aria-label={`切换${line.name}的协议模式`}
                              isDisabled={switchingProtocol === line.id}
                              isSelected={line.protocolMode === "tcp_udp"}
                              onValueChange={() => void switchProtocol(line)}
                            />
                          </label>
                        </div>
                      </td>
                    </tr>
                  )}
                </Fragment>
              ))}
            </tbody>
          </table>
          {lines.length === 0 && (
            <p className="py-8 text-center text-default-500">暂无业务线路</p>
          )}
        </div>
      </section>
    </AnimatedPage>
  );
}
