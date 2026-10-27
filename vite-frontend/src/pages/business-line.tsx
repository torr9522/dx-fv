import { useEffect, useMemo, useState } from "react";
import toast from "react-hot-toast";

import { AnimatedPage } from "@/components/animated-page";
import { Button } from "@/shadcn-bridge/heroui/button";
import { Input } from "@/shadcn-bridge/heroui/input";
import { getBusinessLineList, createBusinessLine, deleteBusinessLine, getNodeList, getTunnelList } from "@/api";
import type { BusinessLineApiItem, NodeApiItem, TunnelApiItem } from "@/api/types";

const initialForm = { name: "", pathType: "frontsea" as "frontsea" | "qix", gzNodeId: 0, ixNodeId: 0, entryPort: "", targetHost: "", targetPort: "", qixTunnelId: 0 };

export default function BusinessLinePage() {
  const [lines, setLines] = useState<BusinessLineApiItem[]>([]);
  const [nodes, setNodes] = useState<NodeApiItem[]>([]);
  const [tunnels, setTunnels] = useState<TunnelApiItem[]>([]);
  const [form, setForm] = useState(initialForm);
  const [loading, setLoading] = useState(false);
  const gzNodes = useMemo(() => nodes.filter((n) => n.status === 1), [nodes]);
  const ixNodes = useMemo(() => nodes.filter((n) => n.status === 1), [nodes]);

  const load = async () => {
    try {
      const [lineRes, nodeRes, tunnelRes] = await Promise.all([getBusinessLineList(), getNodeList(), getTunnelList()]);
      setLines(lineRes.data || []); setNodes(nodeRes.data || []); setTunnels(tunnelRes.data || []);
    } catch { toast.error("业务线路加载失败"); }
  };
  useEffect(() => { void load(); }, []);

  const update = (key: string, value: string | number) => setForm((old) => ({ ...old, [key]: value }));
  const submit = async () => {
    if (!form.name.trim() || !form.gzNodeId || !form.entryPort || !form.targetHost.trim() || !form.targetPort) { toast.error("请填写完整线路信息"); return; }
    if (form.pathType === "frontsea" && !form.ixNodeId) { toast.error("请选择前海IX节点"); return; }
    if (form.pathType === "qix" && !form.qixTunnelId) { toast.error("请选择既有QIX Tunnel"); return; }
    setLoading(true);
    try {
      await createBusinessLine({ name: form.name.trim(), pathType: form.pathType, gzNodeId: form.gzNodeId, ixNodeId: form.pathType === "frontsea" ? form.ixNodeId : undefined, entryPort: Number(form.entryPort), targetHost: form.targetHost.trim(), targetPort: Number(form.targetPort), qixTunnelId: form.pathType === "qix" ? form.qixTunnelId : undefined });
      toast.success("线路创建成功"); setForm(initialForm); await load();
    } catch { toast.error("线路创建失败"); } finally { setLoading(false); }
  };
  const remove = async (id: number) => { try { await deleteBusinessLine(id); toast.success("线路已删除"); await load(); } catch { toast.error("线路删除失败"); } };

  return <AnimatedPage className="mx-auto w-full max-w-7xl space-y-6 p-4 md:p-6">
    <div><h1 className="text-2xl font-semibold">业务线路</h1><p className="mt-1 text-sm text-default-500">一次创建入口、出口及其关联关系。前海IX端口由系统从安全端口池自动选择。</p></div>
    <section className="rounded-xl border border-default-200 bg-content1 p-5 shadow-sm">
      <h2 className="mb-4 text-lg font-medium">新增线路</h2>
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        <Input label="线路名称" value={form.name} onChange={(e) => update("name", e.target.value)} />
        <label className="flex flex-col gap-1 text-sm"><span>路径</span><select className="h-10 rounded-medium border border-default-200 bg-content1 px-3" value={form.pathType} onChange={(e) => update("pathType", e.target.value)}><option value="frontsea">前海IX Direct</option><option value="qix">QIX Tunnel</option></select></label>
        <label className="flex flex-col gap-1 text-sm"><span>GZ入口节点</span><select className="h-10 rounded-medium border border-default-200 bg-content1 px-3" value={form.gzNodeId} onChange={(e) => update("gzNodeId", Number(e.target.value))}><option value={0}>请选择</option>{gzNodes.map((n) => <option key={n.id} value={n.id}>{n.name}</option>)}</select></label>
        {form.pathType === "frontsea" ? <label className="flex flex-col gap-1 text-sm"><span>前海IX节点</span><select className="h-10 rounded-medium border border-default-200 bg-content1 px-3" value={form.ixNodeId} onChange={(e) => update("ixNodeId", Number(e.target.value))}><option value={0}>请选择</option>{ixNodes.map((n) => <option key={n.id} value={n.id}>{n.name}</option>)}</select></label> : <label className="flex flex-col gap-1 text-sm"><span>既有QIX Tunnel</span><select className="h-10 rounded-medium border border-default-200 bg-content1 px-3" value={form.qixTunnelId} onChange={(e) => update("qixTunnelId", Number(e.target.value))}><option value={0}>请选择</option>{tunnels.filter((t) => t.type === 2).map((t) => <option key={t.id} value={t.id}>{t.name} (#{t.id})</option>)}</select></label>}
        <Input label="GZ入口端口" type="number" value={form.entryPort} onChange={(e) => update("entryPort", e.target.value)} />
        <Input label="目标Host/IP" value={form.targetHost} onChange={(e) => update("targetHost", e.target.value)} />
        <Input label="目标端口" type="number" value={form.targetPort} onChange={(e) => update("targetPort", e.target.value)} />
      </div>
      <Button className="mt-5" color="primary" isLoading={loading} onPress={() => void submit()}>创建线路</Button>
    </section>
    <section className="rounded-xl border border-default-200 bg-content1 p-5 shadow-sm"><h2 className="mb-4 text-lg font-medium">已创建线路</h2><div className="overflow-x-auto"><table className="w-full text-left text-sm"><thead><tr className="border-b border-default-200 text-default-500"><th className="p-2">名称</th><th className="p-2">路径</th><th className="p-2">入口</th><th className="p-2">目标</th><th className="p-2">底层规则</th><th className="p-2" /></tr></thead><tbody>{lines.map((line) => <tr className="border-b border-default-100" key={line.id}><td className="p-2 font-medium">{line.name}</td><td className="p-2">{line.pathType === "frontsea" ? `前海IX:${line.ixPort || "自动"}` : "QIX Tunnel"}</td><td className="p-2">:{line.entryPort}</td><td className="p-2">{line.targetHost}:{line.targetPort}</td><td className="p-2">GZ #{line.gzForwardId}{line.ixForwardId ? ` / IX #${line.ixForwardId}` : ""}</td><td className="p-2 text-right"><Button size="sm" color="danger" variant="light" onPress={() => void remove(line.id)}>删除</Button></td></tr>)}</tbody></table>{lines.length === 0 && <p className="py-8 text-center text-default-500">暂无业务线路</p>}</div></section>
  </AnimatedPage>;
}
