# AI 文档排版规范（Word）

统一管理 Codex 在 Windows、Ubuntu、macOS 生成 Word（.docx）时使用的排版规范。

## 文件说明

- [word_format.md](./word_format.md)：唯一正式规范（v1.1）。一级标题不强制另起一页。
- [AGENTS.global-snippet.md](./AGENTS.global-snippet.md)：加入 Codex 全局 `AGENTS.md` 的规则示例。
- [setup_codex_word_standard.sh](./setup_codex_word_standard.sh)：Ubuntu/macOS 安装脚本。
- [setup_codex_word_standard.ps1](./setup_codex_word_standard.ps1)：Windows PowerShell 安装脚本。

## 一次性配置

下载或克隆本仓库后，在仓库目录中执行：

**Ubuntu / macOS**
```bash
bash setup_codex_word_standard.sh
```

**Windows PowerShell**
```powershell
powershell -ExecutionPolicy Bypass -File .\setup_codex_word_standard.ps1
```

脚本只修改当前电脑用户目录下的 `~/.codex/AGENTS.md` 和 `~/.codex/word_format.md`，并对已有 AGENTS 做备份；不会修改其他项目。

重新启动 Codex 会话后，可以直接说“按默认规范生成 Word”。Codex 应在生成前从 GitHub 读取最新版，网络失败时读取本地缓存并告知。

**注意：** GitHub 仓库的文件更新不代表已经自动修改所有电脑上的 AGENTS.md。每台电脑需安装一次规则；Codex 必须有网络访问权限，才能每次拉取最新版。云端 Markdown 是排版要求，并不是已生成的 Word 模板。
