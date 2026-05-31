# Reports

由 Claude Code autopilot 自主调研产出的报告集。

**在线地址**：https://sunchurui.github.io/reports/

## 目录结构

```
reports/
├── index.html              # 首页（报告索引）
├── reports.json            # 报告元数据
├── reports/                # 单篇报告 HTML
│   └── <slug>/index.html
└── publish.sh              # 发布新报告的脚本
```

## 发布新报告

```bash
./publish.sh <slug> <html-file> "<title>" "<summary>" <sources> <chars> tag1,tag2
```

或者由 autopilot 自动完成。
